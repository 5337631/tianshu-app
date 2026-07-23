import 'package:flutter/services.dart';

/// MethodChannel 封装 - 与 Android 原生层通信
class MethodChannelHelper {
  static final MethodChannelHelper _instance = MethodChannelHelper._internal();
  factory MethodChannelHelper() => _instance;
  MethodChannelHelper._internal();

  // 通道定义
  static const _screenshotChannel = MethodChannel('com.tianshu.screenshot');
  static const _contextChannel = MethodChannel('com.tianshu.context');
  static const _systemChannel = MethodChannel('com.tianshu.system');
  static const _permissionsChannel = MethodChannel('com.tianshu.permissions');
  static const _accessibilityChannel = MethodChannel('com.tianshu.accessibility');
  static const _executorChannel = MethodChannel('com.tianshu.executor');
  static const _audioChannel = MethodChannel('com.tianshu.audio');
  static const _ttsChannel = MethodChannel('com.tianshu.tts');
  static const _mcpChannel = MethodChannel('com.tianshu.mcp');
  static const _termuxChannel = MethodChannel('tianshu/termux');
  static const _logChannel = MethodChannel('com.tianshu.log');
  static const _clipboardChannel = MethodChannel('com.tianshu.clipboard');

  // 新增通道
  static const _playwrightChannel = MethodChannel('com.tianshu.playwright');
  static const _cameraChannel = MethodChannel('com.tianshu.camera');
  static const _appInstallChannel = MethodChannel('com.tianshu.appinstall');
  static const _javascriptChannel = MethodChannel('com.tianshu.javascript');
  static const _configChannel = MethodChannel('com.tianshu.config');

  // ══════════════════════════════════════
  //  截屏
  // ══════════════════════════════════════
  Future<Map<String, dynamic>?> takeScreenshot() async {
    try {
      final result = await _screenshotChannel.invokeMethod('takeScreenshot');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  // ══════════════════════════════════════
  //  位置 & 设备状态
  // ══════════════════════════════════════
  Future<Map<String, dynamic>?> getLocation() async {
    try {
      final result = await _contextChannel.invokeMethod('getLocation');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getDeviceState() async {
    try {
      final result = await _contextChannel.invokeMethod('getDeviceState');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getCalendarEvents() async {
    try {
      final result = await _contextChannel.invokeMethod('getCalendarEvents');
      return List.from(result);
    } catch (e) {
      return [];
    }
  }

  // ══════════════════════════════════════
  //  通知
  // ══════════════════════════════════════
  Future<String> getNotifications() async {
    try {
      final result = await _accessibilityChannel.invokeMethod('getNotifications');
      return result?.toString() ?? '[]';
    } catch (e) {
      return '[]';
    }
  }

  // ══════════════════════════════════════
  //  无障碍服务 (基础)
  // ══════════════════════════════════════
  Future<bool> isAccessibilityEnabled() async {
    try {
      final result = await _permissionsChannel.invokeMethod('checkAccessibilityEnabled');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> openAccessibilitySettings() async {
    try {
      await _permissionsChannel.invokeMethod('openAccessibilitySettings');
    } catch (_) {}
  }

  Future<String> getUiHierarchy() async {
    try {
      final result = await _accessibilityChannel.invokeMethod('getUiHierarchy');
      return result?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  Future<bool> performClick(int x, int y) async {
    try {
      final result = await _accessibilityChannel.invokeMethod('performClick', {'x': x, 'y': y});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> performSwipe(int startX, int startY, int endX, int endY, {int duration = 300}) async {
    try {
      final result = await _accessibilityChannel.invokeMethod('performSwipe', {
        'startX': startX, 'startY': startY,
        'endX': endX, 'endY': endY,
        'duration': duration,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setTextOnNode(String nodeId, String text) async {
    try {
      final result = await _accessibilityChannel.invokeMethod('setTextOnNode', {
        'nodeId': nodeId, 'text': text,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getCurrentActivityName() async {
    try {
      final result = await _accessibilityChannel.invokeMethod('getCurrentActivityName');
      return result?.toString();
    } catch (e) {
      return null;
    }
  }

  // ══════════════════════════════════════
  //  Playwright 模式 (新增)
  // ══════════════════════════════════════

  /// 获取带 ref 编号的 UI 树 (Playwright snapshot)
  Future<Map<String, dynamic>?> playwrightSnapshot() async {
    try {
      final result = await _playwrightChannel.invokeMethod('snapshot');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  /// 点击指定 ref 元素
  Future<bool> playwrightTapByRef(String ref) async {
    try {
      final result = await _playwrightChannel.invokeMethod('tapByRef', {'ref': ref});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// 在指定 ref 元素输入文字
  Future<bool> playwrightTypeByRef(String ref, String text) async {
    try {
      final result = await _playwrightChannel.invokeMethod('typeByRef', {
        'ref': ref,
        'text': text,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// 滚动屏幕
  Future<bool> playwrightScroll(String direction) async {
    try {
      final result = await _playwrightChannel.invokeMethod('scroll', {'direction': direction});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  /// 按系统按键
  Future<bool> playwrightPress(String key) async {
    try {
      final result = await _playwrightChannel.invokeMethod('press', {'key': key});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // ══════════════════════════════════════
  //  代码执行
  // ══════════════════════════════════════
  Future<Map<String, dynamic>> execCommand(String command) async {
    try {
      final result = await _executorChannel.invokeMethod('exec', {'command': command});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'exitCode': -1, 'stdout': '', 'stderr': e.toString()};
    }
  }

  Future<String> readFile(String path) async {
    try {
      final result = await _executorChannel.invokeMethod('readFile', {'path': path});
      return result?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  // ══════════════════════════════════════
  //  摄像头 (新增)
  // ══════════════════════════════════════
  Future<Map<String, dynamic>?> takePhoto() async {
    try {
      final result = await _cameraChannel.invokeMethod('takePhoto');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return null;
    }
  }

  // ══════════════════════════════════════
  //  应用安装 (新增)
  // ══════════════════════════════════════
  Future<Map<String, dynamic>> installApk(String apkPath) async {
    try {
      final result = await _appInstallChannel.invokeMethod('installApk', {'path': apkPath});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ══════════════════════════════════════
  //  Activity 启动 (新增)
  // ══════════════════════════════════════
  Future<bool> startActivity(String component) async {
    try {
      final result = await _systemChannel.invokeMethod('startActivity', {'component': component});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // ══════════════════════════════════════
  //  JavaScript 执行 (新增)
  // ══════════════════════════════════════
  Future<Map<String, dynamic>> executeJavaScript(String code) async {
    try {
      final result = await _javascriptChannel.invokeMethod('execute', {'code': code});
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ══════════════════════════════════════
  //  配置管理 (新增)
  // ══════════════════════════════════════
  Future<String?> configGet(String key) async {
    try {
      final result = await _configChannel.invokeMethod('get', {'key': key});
      return result?.toString();
    } catch (e) {
      return null;
    }
  }

  Future<bool> configSet(String key, String value) async {
    try {
      final result = await _configChannel.invokeMethod('set', {
        'key': key,
        'value': value,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // ══════════════════════════════════════
  //  录音
  // ══════════════════════════════════════
  Future<bool> startRecording() async {
    try {
      final result = await _audioChannel.invokeMethod('startRecording');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final result = await _audioChannel.invokeMethod('stopRecording');
      return result?.toString();
    } catch (e) {
      return null;
    }
  }

  // ══════════════════════════════════════
  //  TTS
  // ══════════════════════════════════════
  Future<bool> speak(String text) async {
    try {
      final result = await _ttsChannel.invokeMethod('speak', {'text': text});
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopTts() async {
    try {
      await _ttsChannel.invokeMethod('stop');
    } catch (_) {}
  }

  Future<bool> isTtsReady() async {
    try {
      final result = await _ttsChannel.invokeMethod('isReady');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  // ══════════════════════════════════════
  //  MCP
  // ══════════════════════════════════════
  Future<void> startMcpServer({int port = 8399}) async {
    try {
      await _mcpChannel.invokeMethod('startMCPServer', {'port': port});
    } catch (_) {}
  }

  Future<void> stopMcpServer() async {
    try {
      await _mcpChannel.invokeMethod('stopMCPServer');
    } catch (_) {}
  }

  // ══════════════════════════════════════
  //  剪贴板
  // ══════════════════════════════════════
  Future<void> copyToClipboard(String text) async {
    try {
      await _clipboardChannel.invokeMethod('copy', {'text': text});
    } catch (_) {}
  }

  /// 打开文件
  Future<void> openFile(String path) async {
    try {
      await _systemChannel.invokeMethod('openFile', {'path': path});
    } catch (_) {}
  }

  Future<String> pasteFromClipboard() async {
    try {
      final result = await _clipboardChannel.invokeMethod('paste');
      return result?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  // ══════════════════════════════════════
  //  日志
  // ══════════════════════════════════════
  Future<String> getLogs({String filter = '', int count = 50}) async {
    try {
      final result = await _logChannel.invokeMethod('getLogs', {
        'filter': filter,
        'count': count,
      });
      return result?.toString() ?? '';
    } catch (e) {
      return '';
    }
  }

  // ══════════════════════════════════════
  //  Termux
  // ══════════════════════════════════════
  Future<bool> isTermuxInstalled() async {
    try {
      final result = await _termuxChannel.invokeMethod('isTermuxInstalled');
      return result == true;
    } catch (e) {
      return false;
    }
  }

  Future<String> termuxExec(String command) async {
    try {
      final result = await _termuxChannel.invokeMethod('termuxExec', {'command': command});
      return result?.toString() ?? '';
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<String> deployBridge() async {
    try {
      final result = await _termuxChannel.invokeMethod('deployBridge');
      return result?.toString() ?? '';
    } catch (e) {
      return 'Error: $e';
    }
  }
}
