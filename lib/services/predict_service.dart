import 'dart:async';
import 'package:intl/intl.dart';
import '../utils/method_channel_helper.dart';
import 'memory_service.dart';

/// 预判结果
class PredictResult {
  final String id;
  final String title;
  final String description;
  final String action;
  final PredictType type;
  final double confidence;

  PredictResult({
    required this.id,
    required this.title,
    required this.description,
    required this.action,
    required this.type,
    this.confidence = 0.8,
  });
}

/// 预判类型
enum PredictType {
  time,      // 时间预判
  scene,     // 场景预判
  interest,  // 兴趣预判
  task,      // 任务预判
}

/// 预判系统 - 智能推荐
class PredictService {
  static final PredictService instance = PredictService._internal();
  PredictService._internal();

  Timer? _refreshTimer;
  final List<PredictResult> _currentPredictions = [];
  bool _initialized = false;

  /// 获取当前预判结果
  List<PredictResult> get predictions => List.unmodifiable(_currentPredictions);

  /// 初始化预判系统
  Future<void> init() async {
    if (_initialized) return;

    // 每 5 分钟刷新预判结果
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => refresh());
    await refresh();

    _initialized = true;
  }

  /// 刷新预判结果
  Future<void> refresh() async {
    _currentPredictions.clear();

    await _timePredict();
    await _scenePredict();
    await _taskPredict();

    _currentPredictions.sort((a, b) => b.confidence.compareTo(a.confidence));
  }

  /// 时间预判
  Future<void> _timePredict() async {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;

    final memory = MemoryService.instance;
    final activeTime = await memory.getPreference('active_time');

    // 早上 6-9 点
    if (hour >= 6 && hour < 9) {
      _currentPredictions.add(PredictResult(
        id: 'morning_overview',
        title: '今日概览',
        description: '查看今天的日程安排和待办事项',
        action: 'show_daily_overview',
        type: PredictType.time,
        confidence: 0.9,
      ));

      _currentPredictions.add(PredictResult(
        id: 'morning_weather',
        title: '查看天气',
        description: '了解今天的天气情况',
        action: 'check_weather',
        type: PredictType.time,
        confidence: 0.85,
      ));
    }

    // 周五 17-19 点
    if (weekday == 5 && hour >= 17 && hour < 19) {
      _currentPredictions.add(PredictResult(
        id: 'weekly_report',
        title: '生成周报',
        description: '本周工作总结和下周计划',
        action: 'generate_weekly_report',
        type: PredictType.time,
        confidence: 0.8,
      ));
    }

    // 晚上 22-23 点
    if (hour >= 22 && hour < 23) {
      _currentPredictions.add(PredictResult(
        id: 'daily_summary',
        title: '今日总结',
        description: '回顾今天的对话和完成的任务',
        action: 'daily_summary',
        type: PredictType.time,
        confidence: 0.75,
      ));
    }
  }

  /// 场景预判
  Future<void> _scenePredict() async {
    final channel = MethodChannelHelper();

    // 获取设备状态
    final deviceState = await channel.getDeviceState();
    if (deviceState != null) {
      final batteryLevel = deviceState['batteryLevel'] as int? ?? 100;
      final isCharging = deviceState['isCharging'] as bool? ?? false;

      // 低电量提醒
      if (batteryLevel < 20 && !isCharging) {
        _currentPredictions.add(PredictResult(
          id: 'low_battery',
          title: '低电量提醒',
          description: '电量仅剩 $batteryLevel%，建议充电',
          action: 'show_battery_warning',
          type: PredictType.scene,
          confidence: 0.95,
        ));
      }
    }

    // 获取位置（如果有权限）
    try {
      final location = await channel.getLocation();
      if (location != null) {
        // 可以根据位置做更多预判
        // 例如：到公司提醒、离开公司提醒等
      }
    } catch (_) {}

    // 获取当前活动
    try {
      final activity = await channel.getCurrentActivityName();
      if (activity != null) {
        // 根据当前应用做预判
      }
    } catch (_) {}
  }

  /// 任务预判
  Future<void> _taskPredict() async {
    final memory = MemoryService.instance;

    // 检查是否有未完成任务
    final tasksContent = await memory.read('user/tasks.md');
    if (tasksContent.isNotEmpty && tasksContent.contains('- [ ]')) {
      _currentPredictions.add(PredictResult(
        id: 'continue_task',
        title: '继续任务',
        description: '你有未完成的任务',
        action: 'show_pending_tasks',
        type: PredictType.task,
        confidence: 0.7,
      ));
    }

    // 检查截止日期
    final deadlines = await memory.getPreference('deadlines');
    if (deadlines.isNotEmpty) {
      final deadlineList = deadlines.split(',');
      for (final deadline in deadlineList) {
        final parts = deadline.split(':');
        if (parts.length == 2) {
          final taskName = parts[0];
          final dueDate = DateTime.tryParse(parts[1]);
          if (dueDate != null) {
            final daysLeft = dueDate.difference(DateTime.now()).inDays;
            if (daysLeft <= 3 && daysLeft >= 0) {
              _currentPredictions.add(PredictResult(
                id: 'deadline_$taskName',
                title: '截止提醒',
                description: '$taskName 将在 $daysLeft 天后截止',
                action: 'show_deadline_detail',
                type: PredictType.task,
                confidence: 0.85,
              ));
            }
          }
        }
      }
    }
  }

  /// 执行预判动作
  Future<void> executeAction(PredictResult prediction) async {
    final channel = MethodChannelHelper();

    switch (prediction.action) {
      case 'check_weather':
        // 调用天气 API
        break;
      case 'show_daily_overview':
        // 显示今日概览
        break;
      case 'generate_weekly_report':
        // 生成周报
        break;
      case 'daily_summary':
        // 今日总结
        break;
      case 'show_battery_warning':
        await channel.speak('电量不足，请及时充电');
        break;
      case 'show_pending_tasks':
        // 显示待办任务
        break;
      case 'show_deadline_detail':
        // 显示截止详情
        break;
    }
  }

  /// 销毁
  void dispose() {
    _refreshTimer?.cancel();
  }
}
