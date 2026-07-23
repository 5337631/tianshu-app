package com.tianshu.tianshu

import android.content.Context
import android.util.Log
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader
import java.io.OutputStream
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit

/**
 * 内置终端 — 不依赖 Termux，直接在 Android 上执行 shell 命令
 * 对标 HermesApp OperitTerminal
 */
class BuiltinTerminal private constructor(private val context: Context) {
    companion object {
        private const val TAG = "BuiltinTerminal"
        private var instance: BuiltinTerminal? = null

        fun getInstance(context: Context): BuiltinTerminal {
            return instance ?: synchronized(this) {
                instance ?: BuiltinTerminal(context.applicationContext).also { instance = it }
            }
        }
    }

    private val sessions = ConcurrentHashMap<String, TerminalSession>()
    private val homeDir = File(context.filesDir, "terminal_home")

    init {
        if (!homeDir.exists()) homeDir.mkdirs()
    }

    /**
     * 创建新的终端会话
     */
    fun createSession(title: String = "session"): String {
        val sessionId = UUID.randomUUID().toString()
        sessions[sessionId] = TerminalSession(sessionId, title, homeDir)
        Log.d(TAG, "Created session: $sessionId ($title)")
        return sessionId
    }

    /**
     * 执行命令
     */
    fun executeCommand(sessionId: String, command: String, timeoutMs: Long = 30000): CommandResult {
        val session = sessions[sessionId]
            ?: return CommandResult(false, "", "Session not found: $sessionId")

        return try {
            val processBuilder = ProcessBuilder(listOf("sh", "-c", command))
            processBuilder.directory(session.workDir)
            
            val env = processBuilder.environment()
            env["HOME"] = homeDir.absolutePath
            env["PATH"] = "/system/bin:/system/xbin:${homeDir.absolutePath}/bin"
            env["TMPDIR"] = File(homeDir, "tmp").apply { mkdirs() }.absolutePath
            env["LANG"] = "en_US.UTF-8"
            env["TERM"] = "dumb"
            
            processBuilder.redirectErrorStream(true)
            val process = processBuilder.start()

            val output = StringBuilder()
            val reader = BufferedReader(InputStreamReader(process.inputStream))
            var line: String?
            while (reader.readLine().also { line = it } != null) {
                output.appendLine(line)
            }

            val completed = process.waitFor(timeoutMs, TimeUnit.MILLISECONDS)
            if (!completed) {
                process.destroyForcibly()
                return CommandResult(false, output.toString(), "Command timed out after ${timeoutMs}ms")
            }

            val exitCode = process.exitValue()
            CommandResult(exitCode == 0, output.toString(), null, exitCode)
        } catch (e: Exception) {
            Log.e(TAG, "Execute command error: $e")
            CommandResult(false, "", e.message)
        }
    }

    /**
     * 写入文件
     */
    fun writeFile(sessionId: String, relativePath: String, content: String): Boolean {
        val session = sessions[sessionId] ?: return false
        return try {
            val file = File(session.workDir, relativePath)
            file.parentFile?.mkdirs()
            file.writeText(content)
            true
        } catch (e: Exception) {
            Log.e(TAG, "Write file error: $e")
            false
        }
    }

    /**
     * 读取文件
     */
    fun readFile(sessionId: String, relativePath: String): String? {
        val session = sessions[sessionId] ?: return null
        return try {
            val file = File(session.workDir, relativePath)
            if (file.exists()) file.readText() else null
        } catch (e: Exception) {
            Log.e(TAG, "Read file error: $e")
            null
        }
    }

    /**
     * 从 assets 复制文件到会话目录
     */
    fun copyAssetToSession(sessionId: String, assetPath: String, targetPath: String): Boolean {
        val session = sessions[sessionId] ?: return false
        return try {
            // Flutter assets 存储在 flutter_assets/ 目录下
            val flutterAssetPath = "flutter_assets/assets/$assetPath"
            val inputStream = context.assets.open(flutterAssetPath)
            val targetFile = File(session.workDir, targetPath)
            targetFile.parentFile?.mkdirs()
            targetFile.outputStream().use { output ->
                inputStream.copyTo(output)
            }
            inputStream.close()
            Log.d(TAG, "Copied asset: $flutterAssetPath -> ${targetFile.absolutePath}")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Copy asset error: $e")
            false
        }
    }

    /**
     * 获取会话工作目录
     */
    fun getWorkDir(sessionId: String): String? {
        return sessions[sessionId]?.workDir?.absolutePath
    }

    /**
     * 关闭会话
     */
    fun closeSession(sessionId: String) {
        sessions.remove(sessionId)
        Log.d(TAG, "Closed session: $sessionId")
    }

    /**
     * 检查是否已连接（内置终端始终可用）
     */
    fun isConnected(): Boolean = true
}

/**
 * 终端会话
 */
data class TerminalSession(
    val id: String,
    val title: String,
    val workDir: File
) {
    init {
        if (!workDir.exists()) workDir.mkdirs()
    }
}

/**
 * 命令执行结果
 */
data class CommandResult(
    val success: Boolean,
    val output: String,
    val error: String? = null,
    val exitCode: Int = if (success) 0 else -1
)
