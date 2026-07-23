import 'dart:convert';
import '../utils/method_channel_helper.dart';
import 'memory_service.dart';

/// 调试工具服务
class DebuggingService {
  static final DebuggingService instance = DebuggingService._internal();
  DebuggingService._internal();

  final MethodChannelHelper _channel = MethodChannelHelper();
  final List<String> _logs = [];
  bool _initialized = false;

  List<String> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 获取设备日志
  Future<String> getDeviceLogs({String filter = '', int count = 50}) async {
    final result = await _channel.getLogs(filter: filter, count: count);
    return result;
  }

  /// 获取崩溃日志
  Future<String> getCrashLogs() async {
    final result = await _channel.execCommand('logcat -d -b crash | tail -50');
    return result['stdout'] ?? '无崩溃日志';
  }

  /// 获取 ANR 日志
  Future<String> getAnrLogs() async {
    final result = await _channel.execCommand('ls /data/anr/ 2>/dev/null || echo "无ANR日志"');
    return result['stdout'] ?? '无ANR日志';
  }

  /// 检查应用状态
  Future<Map<String, dynamic>> getAppStatus() async {
    final results = await Future.wait([
      _channel.execCommand('dumpsys activity activities | grep "mResumedActivity"'),
      _channel.execCommand('dumpsys meminfo com.tianshu.tianshu | head -20'),
      _channel.execCommand('dumpsys cpuinfo | head -5'),
    ]);

    return {
      'currentActivity': results[0]['stdout']?.trim() ?? 'unknown',
      'memoryInfo': results[1]['stdout'] ?? 'unknown',
      'cpuInfo': results[2]['stdout'] ?? 'unknown',
    };
  }

  /// 检查权限状态
  Future<Map<String, bool>> checkPermissions() async {
    final permissions = [
      'android.permission.RECORD_AUDIO',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.CAMERA',
      'android.permission.READ_EXTERNAL_STORAGE',
      'android.permission.POST_NOTIFICATIONS',
    ];

    final results = <String, bool>{};
    for (final perm in permissions) {
      final result = await _channel.execCommand(
        'dumpsys package com.tianshu.tianshu | grep "$perm"',
      );
      results[perm.split('.').last] = result['stdout']?.contains('granted=true') ?? false;
    }

    return results;
  }

  /// 清除应用数据
  Future<bool> clearAppData() async {
    final result = await _channel.execCommand('pm clear com.tianshu.tianshu');
    return result['success'] ?? false;
  }

  /// 获取存储使用情况
  Future<Map<String, String>> getStorageInfo() async {
    final results = await Future.wait([
      _channel.execCommand('df -h /data'),
      _channel.execCommand('du -sh /data/data/com.tianshu.tianshu/ 2>/dev/null'),
    ]);

    return {
      'system': results[0]['stdout'] ?? 'unknown',
      'appSize': results[1]['stdout'] ?? 'unknown',
    };
  }

  /// 获取网络状态
  Future<Map<String, dynamic>> getNetworkInfo() async {
    final results = await Future.wait([
      _channel.execCommand('ping -c 1 8.8.8.8 | tail -1'),
      _channel.execCommand('ifconfig wlan0 2>/dev/null | grep "inet addr"'),
    ]);

    return {
      'ping': results[0]['stdout'] ?? 'unknown',
      'wifi': results[1]['stdout'] ?? 'unknown',
    };
  }

  /// 运行诊断
  Future<Map<String, dynamic>> runDiagnostics() async {
    final results = <String, dynamic>{};

    results['appStatus'] = await getAppStatus();
    results['permissions'] = await checkPermissions();
    results['storage'] = await getStorageInfo();
    results['network'] = await getNetworkInfo();

    // 评估健康状态
    int score = 100;
    final issues = <String>[];

    if (results['network']['ping']?.contains('100% packet loss') ?? true) {
      score -= 20;
      issues.add('网络连接异常');
    }

    if (results['permissions'].values.any((v) => !v)) {
      score -= 10;
      issues.add('部分权限未授予');
    }

    return {
      'score': score,
      'issues': issues,
      'details': results,
    };
  }

  /// 添加调试日志（支持日志级别）
  void log(String message, {LogLevel level = LogLevel.info}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final prefix = level == LogLevel.error ? '❌' : level == LogLevel.warn ? '⚠️' : level == LogLevel.debug ? '🔍' : 'ℹ️';
    _logs.add('[$timestamp] $prefix $message');
    if (_logs.length > 500) _logs.removeAt(0);
  }

  /// 按级别过滤日志
  List<String> getLogsByLevel(LogLevel minLevel) {
    final levelOrder = [LogLevel.debug, LogLevel.info, LogLevel.warn, LogLevel.error];
    final minIndex = levelOrder.indexOf(minLevel);
    return _logs.where((log) {
      for (var i = minIndex; i < levelOrder.length; i++) {
        if (log.contains(_levelEmoji(levelOrder[i]))) return true;
      }
      return false;
    }).toList();
  }

  String _levelEmoji(LogLevel level) {
    switch (level) {
      case LogLevel.error: return '❌';
      case LogLevel.warn: return '⚠️';
      case LogLevel.debug: return '🔍';
      case LogLevel.info: return 'ℹ️';
    }
  }

  /// 持久化日志到记忆库
  Future<void> persistLogs() async {
    if (_logs.isEmpty) return;
    final today = DateTime.now().toIso8601String().split('T')[0];
    await MemoryService.instance.write('logs/$today.log', _logs.join('\n'));
  }

  /// 导出日志
  Future<String> exportLogs() async {
    return _logs.join('\n');
  }

  /// 清除日志
  void clearLogs() {
    _logs.clear();
  }
}

/// 日志级别
enum LogLevel { debug, info, warn, error }
