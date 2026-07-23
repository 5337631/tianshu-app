package com.tianshu.tianshu

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import android.provider.Settings
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import java.io.OutputStream
import java.net.ServerSocket
import java.net.Socket
import java.util.Locale
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

class MainActivity: FlutterActivity() {
    private val ACCESSIBILITY_CHANNEL = "com.tianshu.accessibility"
    private val EXECUTOR_CHANNEL = "com.tianshu.executor"
    private val AUDIO_CHANNEL = "com.tianshu.audio"
    private val TTS_CHANNEL = "com.tianshu.tts"
    private val MCP_CHANNEL = "com.tianshu.mcp"

    private var audioRecord: AudioRecord? = null
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var recordingThread: Thread? = null
    private var recordingResult: MethodChannel.Result? = null
    private var recordingFile: File? = null

    private var tts: TextToSpeech? = null
    private var ttsReady = false
    private var ttsResult: MethodChannel.Result? = null
    private var mcpServerThread: Thread? = null
    private var mcpRunning = false
    private var termuxResultReceiver: TermuxResultReceiver? = null
    val pendingTermuxResults = ConcurrentHashMap<String, MethodChannel.Result>()

    private val RECORD_AUDIO_REQUEST = 1001
    private val pendingPermissionResults = mutableMapOf<Int, MethodChannel.Result>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 请求录音权限
        requestAudioPermission()

        // ════════════════════════════════════════
        //  截屏通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tianshu.screenshot")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "takeScreenshot" -> {
                        try {
                            val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                            if (service != null) {
                                val screenshotFile = File(cacheDir, "screenshot_${System.currentTimeMillis()}.png")
                                val success = service.takeScreenshot(screenshotFile.absolutePath, "png")
                                if (success) {
                                    val options = android.graphics.BitmapFactory.Options().apply { inJustDecodeBounds = true }
                                    android.graphics.BitmapFactory.decodeFile(screenshotFile.absolutePath, options)
                                    result.success(mapOf(
                                        "path" to screenshotFile.absolutePath,
                                        "width" to options.outWidth,
                                        "height" to options.outHeight,
                                        "size" to screenshotFile.length()
                                    ))
                                } else {
                                    result.error("SCREENSHOT_FAILED", "截屏失败", null)
                                }
                            } else {
                                result.error("NO_ACCESSIBILITY", "无障碍服务未启用", null)
                            }
                        } catch (e: Exception) {
                            result.error("SCREENSHOT_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  位置通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tianshu.context")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLocation" -> {
                        try {
                            val locationManager = getSystemService(LOCATION_SERVICE) as? android.location.LocationManager
                            if (locationManager == null) {
                                result.error("NO_LOCATION_MANAGER", "无法获取位置服务", null)
                                return@setMethodCallHandler
                            }

                            // 检查权限
                            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                                result.error("NO_PERMISSION", "缺少定位权限", null)
                                return@setMethodCallHandler
                            }

                            // 先尝试缓存位置
                            var loc: android.location.Location? = locationManager.getLastKnownLocation(android.location.LocationManager.GPS_PROVIDER)
                                ?: locationManager.getLastKnownLocation(android.location.LocationManager.NETWORK_PROVIDER)

                            // 如果缓存为空，主动请求一次（API 30+）
                            if (loc == null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                val provider = when {
                                    locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) -> android.location.LocationManager.GPS_PROVIDER
                                    locationManager.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER) -> android.location.LocationManager.NETWORK_PROVIDER
                                    else -> null
                                }
                                if (provider != null) {
                                    val latch = java.util.concurrent.CountDownLatch(1)
                                    val executor = java.util.concurrent.Executors.newSingleThreadExecutor()
                                    try {
                                        locationManager.getCurrentLocation(provider, null, executor) { location: android.location.Location? ->
                                            loc = location
                                            latch.countDown()
                                        }
                                        latch.await(10, java.util.concurrent.TimeUnit.SECONDS)
                                    } catch (_: Exception) {}
                                }
                            }

                            if (loc != null) {
                                result.success(mapOf(
                                    "latitude" to loc!!.latitude,
                                    "longitude" to loc!!.longitude,
                                    "accuracy" to loc!!.accuracy,
                                    "name" to "当前位置"
                                ))
                            } else {
                                result.error("NO_LOCATION", "无法获取当前位置，请确保定位服务已开启", null)
                            }
                        } catch (e: SecurityException) {
                            result.error("NO_PERMISSION", "缺少定位权限", null)
                        } catch (e: Exception) {
                            result.error("LOCATION_ERROR", e.message, null)
                        }
                    }
                    "getDeviceState" -> {
                        try {
                            val batteryManager = getSystemService(BATTERY_SERVICE) as? android.os.BatteryManager
                            val batteryLevel = batteryManager?.getIntProperty(android.os.BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
                            val isCharging = batteryManager?.isCharging ?: false
                            result.success(mapOf(
                                "batteryLevel" to batteryLevel,
                                "isCharging" to isCharging,
                                "isScreenOn" to true
                            ))
                        } catch (e: Exception) {
                            result.error("STATE_ERROR", e.message, null)
                        }
                    }
                    "getCalendarEvents" -> {
                        result.success(emptyList<Map<String, Any>>())
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  系统操作通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tianshu.system")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "showNotification" -> {
                        val title = call.argument<String>("title") ?: ""
                        val body = call.argument<String>("body") ?: ""
                        // 简单 Toast
                        android.widget.Toast.makeText(this, "$title: $body", android.widget.Toast.LENGTH_LONG).show()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  权限管理通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tianshu.permissions")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "checkPermission" -> {
                        val permission = call.argument<String>("permission") ?: ""
                        val granted = ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
                        result.success(granted)
                    }
                    "requestPermission" -> {
                        val permission = call.argument<String>("permission") ?: ""
                        val requestCode = call.argument<Int>("requestCode") ?: 2000
                        if (ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED) {
                            result.success(true)
                        } else {
                            pendingPermissionResults[requestCode] = result
                            ActivityCompat.requestPermissions(this, arrayOf(permission), requestCode)
                        }
                    }
                    "checkNotificationListener" -> {
                        result.success(isNotificationListenerEnabled())
                    }
                    "openNotificationSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FAILED", e.message, null)
                        }
                    }
                    "openLocationSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FAILED", e.message, null)
                        }
                    }
                    "checkLocationEnabled" -> {
                        val locationManager = getSystemService(LOCATION_SERVICE) as? android.location.LocationManager
                        val enabled = locationManager?.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) == true ||
                                locationManager?.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER) == true
                        result.success(enabled)
                    }
                    "checkAccessibilityEnabled" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FAILED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  日志查看通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tianshu.log")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getLogs" -> {
                        val filter = call.argument<String>("filter") ?: ""
                        val count = call.argument<Int>("count") ?: 50
                        val level = call.argument<String>("level") ?: "i"
                        Thread {
                            try {
                                val process = Runtime.getRuntime().exec(
                                    arrayOf("logcat", "-d", "-t", count.toString(),
                                        if (filter.isNotEmpty()) "$filter:*:S" else "*:S")
                                )
                                val reader = BufferedReader(InputStreamReader(process.inputStream))
                                val output = reader.readText()
                                process.waitFor()
                                result.success(output)
                            } catch (e: Exception) {
                                result.success("")
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  剪贴板通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tianshu.clipboard")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "copy" -> {
                        val text = call.argument<String>("text") ?: ""
                        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                        val clip = android.content.ClipData.newPlainText("Tianshu", text)
                        clipboard.setPrimaryClip(clip)
                        result.success(true)
                    }
                    "paste" -> {
                        val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as android.content.ClipboardManager
                        val text = clipboard.primaryClip?.getItemAt(0)?.text?.toString() ?: ""
                        result.success(text)
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  无障碍服务通道（补充 getNotifications 等）
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ACCESSIBILITY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isProviderInstalled", "connect" -> {
                        result.success(isAccessibilityServiceEnabled())
                    }
                    "openAccessibilitySettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FAILED", e.message, null)
                        }
                    }
                    "getUiHierarchy" -> {
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.getUiHierarchy() ?: "")
                    }
                    "getNotifications" -> {
                        val listener = TianshuNotificationListener.instance
                        if (listener != null) {
                            val notifications = listener.getNotifications()
                            result.success(notifications)
                        } else {
                            // 通知监听服务未启用，返回空
                            result.success("[]")
                        }
                    }
                    "performClick" -> {
                        val x = call.argument<Int>("x") ?: 0
                        val y = call.argument<Int>("y") ?: 0
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.performClick(x, y) ?: false)
                    }
                    "performLongPress" -> {
                        val x = call.argument<Int>("x") ?: 0
                        val y = call.argument<Int>("y") ?: 0
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.performLongPress(x, y) ?: false)
                    }
                    "performSwipe" -> {
                        val startX = call.argument<Int>("startX") ?: 0
                        val startY = call.argument<Int>("startY") ?: 0
                        val endX = call.argument<Int>("endX") ?: 0
                        val endY = call.argument<Int>("endY") ?: 0
                        val duration = call.argument<Int>("duration")?.toLong() ?: 300
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.performSwipe(startX, startY, endX, endY, duration) ?: false)
                    }
                    "performGlobalAction" -> {
                        val actionId = call.argument<Int>("actionId") ?: 0
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.performGlobal(actionId) ?: false)
                    }
                    "findFocusedNodeId" -> {
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.findFocusedNodeId())
                    }
                    "setTextOnNode" -> {
                        val nodeId = call.argument<String>("nodeId") ?: ""
                        val text = call.argument<String>("text") ?: ""
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.setTextOnNode(nodeId, text) ?: false)
                    }
                    "takeScreenshot" -> {
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.takeScreenshot("", "") ?: false)
                    }
                    "getCurrentActivityName" -> {
                        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
                        result.success(service?.getCurrentActivityName())
                    }
                    "openApp" -> {
                        val packageName = call.argument<String>("packageName") ?: ""
                        try {
                            val intent = packageManager.getLaunchIntentForPackage(packageName)
                            if (intent != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "installProvider" -> result.success(true)
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  代码执行 / 终端通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, EXECUTOR_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "exec" -> {
                        val command = call.argument<String>("command") ?: ""
                        Thread {
                            try {
                                val process = Runtime.getRuntime().exec(command)
                                val stdout = BufferedReader(InputStreamReader(process.inputStream))
                                val stderr = BufferedReader(InputStreamReader(process.errorStream))
                                val output = stdout.readText()
                                val error = stderr.readText()
                                val exitCode = process.waitFor()
                                result.success(mapOf(
                                    "exitCode" to exitCode,
                                    "stdout" to output,
                                    "stderr" to error
                                ))
                            } catch (e: Exception) {
                                result.success(mapOf(
                                    "exitCode" to -1,
                                    "stdout" to "",
                                    "stderr" to (e.message ?: "执行失败").toString()
                                ))
                            }
                        }.start()
                    }

                    "execWithInput" -> {
                        val command = call.argument<String>("command") ?: ""
                        val input = call.argument<String>("input") ?: ""
                        Thread {
                            try {
                                val process = Runtime.getRuntime().exec(command)
                                if (input.isNotEmpty()) {
                                    process.outputStream.write(input.toByteArray())
                                    process.outputStream.flush()
                                    process.outputStream.close()
                                }
                                val stdout = BufferedReader(InputStreamReader(process.inputStream))
                                val stderr = BufferedReader(InputStreamReader(process.errorStream))
                                val output = stdout.readText()
                                val error = stderr.readText()
                                val exitCode = process.waitFor()
                                result.success(mapOf(
                                    "exitCode" to exitCode,
                                    "stdout" to output,
                                    "stderr" to error
                                ))
                            } catch (e: Exception) {
                                result.success(mapOf(
                                    "exitCode" to -1,
                                    "stdout" to "",
                                    "stderr" to (e.message ?: "执行失败").toString()
                                ))
                            }
                        }.start()
                    }

                    "readFile" -> {
                        val path = call.argument<String>("path") ?: ""
                        try {
                            val file = java.io.File(path)
                            if (file.exists() && file.canRead()) {
                                result.success(file.readText())
                            } else {
                                result.success("")
                            }
                        } catch (e: Exception) {
                            result.success("")
                        }
                    }

                    "which" -> {
                        val cmd = call.argument<String>("command") ?: ""
                        Thread {
                            try {
                                val process = Runtime.getRuntime().exec("which $cmd")
                                val reader = BufferedReader(InputStreamReader(process.inputStream))
                                val line = reader.readLine()
                                result.success(line ?: "")
                            } catch (e: Exception) {
                                result.success("")
                            }
                        }.start()
                    }

                    "streamExec" -> {
                        val command = call.argument<String>("command") ?: ""
                        // 流式执行——每条输出行通过 MethodChannel 回调
                        // 简化版：一次性返回所有输出
                        Thread {
                            try {
                                val process = Runtime.getRuntime().exec(command)
                                val stdout = BufferedReader(InputStreamReader(process.inputStream))
                                val stderr = BufferedReader(InputStreamReader(process.errorStream))
                                val output = stdout.readText()
                                val error = stderr.readText()
                                val exitCode = process.waitFor()
                                result.success(mapOf(
                                    "exitCode" to exitCode,
                                    "stdout" to output,
                                    "stderr" to error
                                ))
                            } catch (e: Exception) {
                                result.success(mapOf(
                                    "exitCode" to -1,
                                    "stdout" to "",
                                    "stderr" to (e.message ?: "执行失败").toString()
                                ))
                            }
                        }.start()
                    }

                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  录音通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startRecording" -> {
                        // 检查权限
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                                recordingResult = result
                                requestAudioPermission()
                                return@setMethodCallHandler
                            }
                        }

                        try {
                            recordingFile = File(cacheDir, "recording_${System.currentTimeMillis()}.m4a")
                            
                            mediaRecorder = MediaRecorder().apply {
                                setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION)
                                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                                setAudioSamplingRate(48000)
                                setAudioEncodingBitRate(192000)
                                setOutputFile(recordingFile?.absolutePath)
                            }

                            mediaRecorder?.prepare()
                            mediaRecorder?.start()
                            isRecording = true
                            result.success(true)
                        } catch (e: SecurityException) {
                            result.error("PERMISSION_ERROR", "录音权限被系统拦截: ${e.message}", null)
                        } catch (e: Exception) {
                            result.error("START_FAILED", "录音启动失败: ${e.message}", null)
                        }
                    }

                    "stopRecording" -> {
                        try {
                            isRecording = false
                            mediaRecorder?.apply {
                                stop()
                                release()
                            }
                            mediaRecorder = null
                            
                            val file = recordingFile
                            recordingFile = null
                            
                            if (file != null && file.exists() && file.length() > 0) {
                                result.success(file.absolutePath)
                            } else {
                                result.error("NO_AUDIO", "未录制到音频数据", null)
                            }
                        } catch (e: Exception) {
                            result.error("STOP_FAILED", "停止录音失败: ${e.message}", null)
                        }
                    }

                    "isRecording" -> {
                        result.success(isRecording)
                    }

                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  文件选择通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.tianshu.file_picker")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickAudioFile" -> {
                        try {
                            val intent = Intent(Intent.ACTION_GET_CONTENT)
                            intent.type = "audio/*"
                            intent.addCategory(Intent.CATEGORY_OPENABLE)
                            startActivityForResult(intent, 2001)
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("PICK_FAILED", "文件选择失败: ${e.message}", null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  系统 TTS 通道
        // ════════════════════════════════════════
        tts = TextToSpeech(this) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale.CHINESE
                ttsReady = true
                android.util.Log.d("TianShuTTS", "TTS init OK")
            } else {
                android.util.Log.e("TianShuTTS", "TTS init failed: $status")
            }
        }

        // ════════════════════════════════════════
        //  Termux 服务通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "tianshu/termux")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTermuxInstalled" -> {
                        result.success(isTermuxInstalled())
                    }
                    "installTermux" -> {
                        try {
                            val intent = packageManager.getLaunchIntentForPackage("com.termux")
                            if (intent != null) {
                                result.success(true)
                            } else {
                                // 打开 F-Droid 下载页
                                val fDroidIntent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse("https://f-droid.org/packages/com.termux/"))
                                fDroidIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(fDroidIntent)
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "authorizeTermux" -> {
                        // 打开 Termux:API 权限设置
                        try {
                            val intent = Intent("com.termux.RUN_COMMAND")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("FAILED", "无法打开 Termux 授权: ${e.message}", null)
                        }
                    }
                    "launchTermux" -> {
                        try {
                            val intent = packageManager.getLaunchIntentForPackage("com.termux")
                            if (intent != null) {
                                startActivity(intent)
                                result.success(true)
                            } else {
                                result.success(false)
                            }
                        } catch (e: Exception) {
                            result.success(false)
                        }
                    }
                    "connectTermux" -> {
                        if (termuxResultReceiver == null) {
                            termuxResultReceiver = TermuxResultReceiver()
                            registerReceiver(termuxResultReceiver, IntentFilter("com.tianshu.TERMUX_RESULT"))
                        }
                        result.success(isTermuxInstalled())
                    }
                    "termuxExec" -> {
                        val command = call.argument<String>("command") ?: ""
                        Thread {
                            try {
                                val terminal = BuiltinTerminal.getInstance(this@MainActivity)
                                val sessionId = terminal.createSession("exec")
                                val r = terminal.executeCommand(sessionId, command, 60000)
                                result.success(r.output.ifEmpty { if (r.success) "OK" else (r.error ?: "Failed") })
                            } catch (e: Exception) {
                                result.error("EXEC_FAILED", "执行失败: ${e.message}", null)
                            }
                        }.start()
                    }
                    "deployBridge" -> {
                        Thread {
                            try {
                                val terminal = BuiltinTerminal.getInstance(this@MainActivity)
                                val sid = terminal.createSession("bridge-deploy")
                                val logs = mutableListOf<String>()

                                logs.add("📦 创建目录...")
                                terminal.executeCommand(sid, "mkdir -p ${context.filesDir}/bridge")

                                logs.add("📦 复制 index.js...")
                                terminal.copyAssetToSession(sid, "bridge/index.js", "bridge/index.js")

                                logs.add("📦 复制 spawn-helper.js...")
                                terminal.copyAssetToSession(sid, "bridge/spawn-helper.js", "bridge/spawn-helper.js")

                                logs.add("✅ 桥接器文件已部署到: ${context.filesDir}/bridge/")
                                logs.add("🚀 启动桥接器...")

                                val startResult = terminal.executeCommand(sid,
                                    "cd ${context.filesDir}/bridge && nohup node index.js 8752 > bridge.log 2>&1 &", 5000)

                                if (startResult.success) {
                                    logs.add("✅ 桥接器已启动 (端口 8752)")
                                } else {
                                    logs.add("⚠️ 启动结果: ${startResult.output} ${startResult.error ?: ""}")
                                }

                                result.success(logs.joinToString("\n"))
                            } catch (e: Exception) {
                                result.error("DEPLOY_FAILED", "部署失败: ${e.message}", null)
                            }
                        }.start()
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  系统 TTS 通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TTS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "speak" -> {
                        val text = call.argument<String>("text") ?: ""
                        val uttId = call.argument<String>("utteranceId") ?: "tts_0"
                        if (!ttsReady) {
                            result.error("TTS_NOT_READY", "TTS 引擎未就绪", null)
                            return@setMethodCallHandler
                        }
                        ttsResult = result
                        tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                            override fun onStart(utteranceId: String?) {}
                            override fun onDone(utteranceId: String?) {
                                runOnUiThread { ttsResult?.success(true); ttsResult = null }
                            }
                            @Deprecated("Deprecated in Java")
                            override fun onError(utteranceId: String?) {
                                runOnUiThread { ttsResult?.error("TTS_ERROR", "播放出错", null); ttsResult = null }
                            }
                            override fun onError(utteranceId: String?, errorCode: Int) {
                                runOnUiThread { ttsResult?.error("TTS_ERROR", "播放出错 code=$errorCode", null); ttsResult = null }
                            }
                        })
                        val params = android.os.Bundle()
                        params.putString(TextToSpeech.Engine.KEY_PARAM_UTTERANCE_ID, uttId)
                        tts?.speak(text, TextToSpeech.QUEUE_FLUSH, params, uttId)
                    }
                    "stop" -> {
                        tts?.stop()
                        result.success(true)
                    }
                    "isReady" -> {
                        result.success(ttsReady)
                    }
                    "getLanguages" -> {
                        val locales = tts?.availableLanguages
                        val list = locales?.map { "${it.language}_${it.country}" } ?: emptyList()
                        result.success(list)
                    }
                    "setLanguage" -> {
                        val lang = call.argument<String>("language") ?: "zh_CN"
                        val parts = lang.split("_")
                        val locale = if (parts.size >= 2) Locale(parts[0], parts[1]) else Locale(parts[0])
                        tts?.language = locale
                        result.success(true)
                    }
                    "setSpeechRate" -> {
                        val rate = call.argument<Double>("rate") ?: 1.0
                        tts?.setSpeechRate(rate.toFloat())
                        result.success(true)
                    }
                    "setPitch" -> {
                        val pitch = call.argument<Double>("pitch") ?: 1.0
                        tts?.setPitch(pitch.toFloat())
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        // ════════════════════════════════════════
        //  内置 MCP Server 通道
        // ════════════════════════════════════════
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MCP_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startMCPServer" -> {
                        val port = call.argument<Int>("port") ?: 8399
                        startMCPServer(port)
                        result.success(true)
                    }
                    "stopMCPServer" -> {
                        stopMCPServer()
                        result.success(true)
                    }
                    "getMCPStatus" -> {
                        result.success(mapOf(
                            "running" to mcpRunning
                        ))
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun startMCPServer(port: Int) {
        if (mcpRunning) return
        mcpRunning = true
        mcpServerThread = Thread {
            try {
                val serverSocket = ServerSocket(port, 5, java.net.InetAddress.getByName("127.0.0.1"))
                android.util.Log.i("MCP", "Server started on port $port")
                while (mcpRunning) {
                    try {
                        val client = serverSocket.accept()
                        Thread { handleMCPRequest(client) }.start()
                    } catch (e: Exception) {
                        if (mcpRunning) android.util.Log.e("MCP", "Accept error: ${e.message}")
                    }
                }
                serverSocket.close()
            } catch (e: Exception) {
                android.util.Log.e("MCP", "Server error: ${e.message}")
                mcpRunning = false
            }
        }.apply {
            name = "MCP-Server"
            isDaemon = true
            start()
        }
    }

    private fun stopMCPServer() {
        mcpRunning = false
        mcpServerThread?.interrupt()
        mcpServerThread = null
    }

    private fun handleMCPRequest(socket: Socket) {
        try {
            val input = socket.getInputStream().bufferedReader()
            val output = socket.getOutputStream()

            // 读取 HTTP 请求
            val requestLine = input.readLine() ?: return
            val parts = requestLine.split(" ")
            if (parts.size < 2) return

            val headers = mutableMapOf<String, String>()
            var line = input.readLine()
            var contentLength = 0
            while (line != null && line.isNotEmpty()) {
                val colonIdx = line.indexOf(":")
                if (colonIdx > 0) {
                    val key = line.substring(0, colonIdx).trim().lowercase()
                    val value = line.substring(colonIdx + 1).trim()
                    headers[key] = value
                    if (key == "content-length") contentLength = value.toIntOrNull() ?: 0
                }
                line = input.readLine()
            }

            // 读取 body
            val body = if (contentLength > 0) {
                val chars = CharArray(contentLength)
                var read = 0
                while (read < contentLength) {
                    val n = input.read(chars, read, contentLength - read)
                    if (n < 0) break
                    read += n
                }
                String(chars, 0, read)
            } else ""

            // 构建 MCP JSON-RPC 响应
            val response = buildMCPResponse(body)

            // 发送 HTTP 响应
            val responseBytes = """
                HTTP/1.1 200 OK
                Content-Type: application/json
                Content-Length: ${response.length}
                Access-Control-Allow-Origin: *
                Connection: close

                $response
            """.trimIndent().replace("\n", "\r\n").toByteArray()

            output.write(responseBytes)
            output.flush()
        } catch (e: Exception) {
            android.util.Log.e("MCP", "Request error: ${e.message}")
        } finally {
            try { socket.close() } catch (_: Exception) {}
        }
    }

    private fun buildMCPResponse(body: String): String {
        if (body.isEmpty()) {
            return """{"jsonrpc":"2.0","error":{"code":-32700,"message":"Parse error"},"id":null}"""
        }
        try {
            val json = org.json.JSONObject(body)
            val method = json.optString("method", "")
            val id = if (json.has("id")) json.get("id") else null

            return when (method) {
                "tools/list" -> buildToolsListResponse(id)
                "ping" -> """{"jsonrpc":"2.0","id":$id,"result":{"pong":true}}"""
                else -> """{"jsonrpc":"2.0","id":$id,"error":{"code":-32601,"message":"Method not found: $method"}}"""
            }
        } catch (e: Exception) {
            return """{"jsonrpc":"2.0","error":{"code":-32700,"message":"Parse error: ${e.message?.replace("\"", "\\\"")}"},"id":null}"""
        }
    }

    private fun buildToolsListResponse(id: Any?): String {
        val tools = """
        [
            {"name":"tianshu_snapshot","description":"获取手机屏幕 UI 无障碍树快照","inputSchema":{"type":"object","properties":{}}},
            {"name":"tianshu_act","description":"操作手机屏幕元素（tap/type/scroll）","inputSchema":{"type":"object","properties":{"ref":{"type":"string"},"action":{"type":"string"},"text":{"type":"string"}},"required":["ref","action"]}},
            {"name":"tianshu_memory_search","description":"搜索记忆库","inputSchema":{"type":"object","properties":{"query":{"type":"string"},"limit":{"type":"integer"}},"required":["query"]}},
            {"name":"tianshu_chat","description":"通用 AI 对话","inputSchema":{"type":"object","properties":{"message":{"type":"string"},"system":{"type":"string"}},"required":["message"]}}
        ]
        """.trimIndent().replace("\n", "")
        val idStr = if (id is String) "\"$id\"" else id?.toString() ?: "null"
        return """{"jsonrpc":"2.0","id":$idStr,"result":{"tools":$tools}}"""
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 2001 && resultCode == RESULT_OK) {
            data?.data?.let { uri ->
                // 复制文件到应用目录
                try {
                    val inputStream = contentResolver.openInputStream(uri)
                    val fileName = "voice_sample_${System.currentTimeMillis()}.mp3"
                    val outputFile = File(cacheDir, fileName)
                    inputStream?.use { input ->
                        outputFile.outputStream().use { output ->
                            input.copyTo(output)
                        }
                    }
                    
                    // 通过 MethodChannel 返回文件路径
                    val channel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger ?: return, "com.tianshu.file_picker")
                    channel.invokeMethod("onFilePicked", outputFile.absolutePath)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    private fun pcmToWav(pcmFile: File, wavFile: File, sampleRate: Int, channels: Int, bitsPerSample: Int) {
        val pcmData = pcmFile.readBytes()
        val totalDataLen = pcmData.size + 36
        val byteRate = sampleRate * channels * bitsPerSample / 8

        val output = FileOutputStream(wavFile)
        output.write("RIFF".toByteArray())
        output.write(intToByteArray(totalDataLen))
        output.write("WAVE".toByteArray())
        output.write("fmt ".toByteArray())
        output.write(intToByteArray(16))
        output.write(shortToByteArray(1))
        output.write(shortToByteArray(channels.toShort()))
        output.write(intToByteArray(sampleRate))
        output.write(intToByteArray(byteRate))
        output.write(shortToByteArray((channels * bitsPerSample / 8).toShort()))
        output.write(shortToByteArray(bitsPerSample.toShort()))
        output.write("data".toByteArray())
        output.write(intToByteArray(pcmData.size))
        output.write(pcmData)
        output.close()
    }

    private fun intToByteArray(value: Int): ByteArray {
        return byteArrayOf(
            (value and 0xFF).toByte(),
            (value shr 8 and 0xFF).toByte(),
            (value shr 16 and 0xFF).toByte(),
            (value shr 24 and 0xFF).toByte()
        )
    }

    private fun shortToByteArray(value: Short): ByteArray {
        return byteArrayOf(
            (value.toInt() and 0xFF).toByte(),
            (value.toInt() shr 8 and 0xFF).toByte()
        )
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val service = com.tianshu.accessibility.TianshuAccessibilityService.instance
        return service != null
    }

    private fun requestAudioPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_REQUEST)
            }
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        return flat != null && flat.contains(packageName)
    }

    private fun isTermuxInstalled(): Boolean {
        return try {
            packageManager.getPackageInfo("com.termux", 0)
            true
        } catch (e: Exception) {
            false
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        val pendingResult = pendingPermissionResults.remove(requestCode)
        if (pendingResult != null) {
            pendingResult.success(grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED)
        }
        if (requestCode == RECORD_AUDIO_REQUEST) {
            if (grantResults.isEmpty() || grantResults[0] != PackageManager.PERMISSION_GRANTED) {
                recordingResult?.error("PERMISSION_DENIED", "录音权限被拒绝", null)
                recordingResult = null
            }
        }
    }

    /// 广播接收 Termux 命令执行结果
    inner class TermuxResultReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val requestId = intent.getStringExtra("requestId") ?: return
            val pendingResult = pendingTermuxResults.remove(requestId) ?: return
            try {
                val stdout = intent.getStringExtra("com.termux.RUN_COMMAND_STDOUT")?.trim() ?: ""
                val stderr = intent.getStringExtra("com.termux.RUN_COMMAND_STDERR")?.trim() ?: ""
                val exitCode = intent.getIntExtra("com.termux.RUN_COMMAND_EXIT_CODE", -1)
                val output = when {
                    stdout.isNotEmpty() -> stdout
                    stderr.isNotEmpty() -> stderr
                    else -> ""
                }
                android.util.Log.d("Termux", "result: $output (exit=$exitCode)")
                pendingResult.success(if (output.isNotEmpty()) output else "(exit=$exitCode)")
            } catch (e: Exception) {
                pendingResult.error("RESULT_ERROR", "解析结果失败: ${e.message}", null)
            }
        }
    }
}
