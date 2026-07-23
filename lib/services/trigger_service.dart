import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/method_channel_helper.dart';

/// 触发规则
class TriggerRule {
  final String id;
  final String name;
  final String type; // time, location
  final String? time; // HH:mm 格式
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int? radius; // 米
  final String action;
  final String actionType; // dnd, alarm, notification, launch_app, send_message, tts, brightness
  final Map<String, dynamic> actionParams;
  final bool enabled;
  final bool oneTimePerDay; // 同一天只触发一次

  TriggerRule({
    required this.id,
    required this.name,
    required this.type,
    this.time,
    this.locationName,
    this.latitude,
    this.longitude,
    this.radius,
    required this.action,
    required this.actionType,
    this.actionParams = const {},
    this.enabled = true,
    this.oneTimePerDay = true,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'time': time,
    'locationName': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'radius': radius,
    'action': action,
    'actionType': actionType,
    'actionParams': actionParams,
    'enabled': enabled,
    'oneTimePerDay': oneTimePerDay,
  };

  factory TriggerRule.fromJson(Map<String, dynamic> json) => TriggerRule(
    id: json['id'],
    name: json['name'],
    type: json['type'],
    time: json['time'],
    locationName: json['locationName'],
    latitude: json['latitude'],
    longitude: json['longitude'],
    radius: json['radius'],
    action: json['action'],
    actionType: json['actionType'],
    actionParams: Map<String, dynamic>.from(json['actionParams'] ?? {}),
    enabled: json['enabled'] ?? true,
    oneTimePerDay: json['oneTimePerDay'] ?? true,
  );
}

/// 场景触发与自动化
class TriggerService {
  static final TriggerService instance = TriggerService._internal();
  TriggerService._internal();

  Timer? _checkTimer;
  final List<TriggerRule> _rules = [];
  final Set<String> _triggeredToday = {};
  bool _initialized = false;

  /// 获取所有规则
  List<TriggerRule> get rules => List.unmodifiable(_rules);

  /// 初始化触发服务
  Future<void> init() async {
    if (_initialized) return;

    await _loadRules();
    await _loadTriggeredToday();

    // 每分钟检查一次
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (_) => _checkTriggers());

    // 添加预设规则（如果为空）
    if (_rules.isEmpty) {
      await _addPresetRules();
    }

    _initialized = true;
  }

  /// 加载规则
  Future<void> _loadRules() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = prefs.getString('trigger_rules') ?? '[]';
    final List<dynamic> rulesList = json.decode(rulesJson);
    _rules.clear();
    _rules.addAll(rulesList.map((r) => TriggerRule.fromJson(r)));
  }

  /// 保存规则
  Future<void> _saveRules() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesJson = json.encode(_rules.map((r) => r.toJson()).toList());
    await prefs.setString('trigger_rules', rulesJson);
  }

  /// 加载今日已触发的规则
  Future<void> _loadTriggeredToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final savedDate = prefs.getString('trigger_date') ?? '';

    if (savedDate == today) {
      final triggered = prefs.getStringList('triggered_rules') ?? [];
      _triggeredToday.addAll(triggered);
    } else {
      _triggeredToday.clear();
      await prefs.setString('trigger_date', today);
      await prefs.setStringList('triggered_rules', []);
    }
  }

  /// 保存今日已触发的规则
  Future<void> _saveTriggeredToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('triggered_rules', _triggeredToday.toList());
  }

  /// 检查触发条件
  Future<void> _checkTriggers() async {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    for (final rule in _rules) {
      if (!rule.enabled) continue;
      if (rule.oneTimePerDay && _triggeredToday.contains(rule.id)) continue;

      bool shouldTrigger = false;

      switch (rule.type) {
        case 'time':
          if (rule.time == currentTime) {
            shouldTrigger = true;
          }
          break;
        case 'location':
          // 位置触发需要持续监听，这里简化处理
          break;
      }

      if (shouldTrigger) {
        await _executeRule(rule);
        _triggeredToday.add(rule.id);
        await _saveTriggeredToday();
      }
    }
  }

  /// 执行规则
  Future<void> _executeRule(TriggerRule rule) async {
    final channel = MethodChannelHelper();

    switch (rule.actionType) {
      case 'tts':
        final text = rule.actionParams['text'] as String? ?? rule.action;
        await channel.speak(text);
        break;
      case 'notification':
        // 发送通知
        break;
      case 'dnd':
        // 勿扰模式（需要特殊权限）
        break;
      case 'alarm':
        // 设置闹钟
        break;
      case 'launch_app':
        // 启动应用
        break;
      case 'send_message':
        // 发送消息
        break;
      case 'brightness':
        // 调节亮度
        break;
    }
  }

  /// 添加预设规则
  Future<void> _addPresetRules() async {
    final presets = [
      TriggerRule(
        id: 'morning_greeting',
        name: '晨间问候',
        type: 'time',
        time: '07:00',
        action: '早安！新的一天开始了。',
        actionType: 'tts',
        actionParams: {'text': '早上好！新的一天开始了。'},
      ),
      TriggerRule(
        id: 'work_reminder',
        name: '上班提醒',
        type: 'time',
        time: '08:30',
        action: '该出发去上班了',
        actionType: 'notification',
      ),
      TriggerRule(
        id: 'lunch_recommend',
        name: '午餐推荐',
        type: 'time',
        time: '11:45',
        action: '午饭时间到了',
        actionType: 'notification',
      ),
      TriggerRule(
        id: 'bedtime_dnd',
        name: '睡前勿扰',
        type: 'time',
        time: '22:00',
        action: '开启勿扰模式',
        actionType: 'dnd',
      ),
    ];

    for (final rule in presets) {
      _rules.add(rule);
    }
    await _saveRules();
  }

  /// 添加规则
  Future<void> addRule(TriggerRule rule) async {
    _rules.add(rule);
    await _saveRules();
  }

  /// 删除规则
  Future<void> removeRule(String id) async {
    _rules.removeWhere((r) => r.id == id);
    await _saveRules();
  }

  /// 更新规则
  Future<void> updateRule(TriggerRule rule) async {
    final index = _rules.indexWhere((r) => r.id == rule.id);
    if (index >= 0) {
      _rules[index] = rule;
      await _saveRules();
    }
  }

  /// 启用/禁用规则
  Future<void> toggleRule(String id, bool enabled) async {
    final index = _rules.indexWhere((r) => r.id == id);
    if (index >= 0) {
      _rules[index] = TriggerRule(
        id: _rules[index].id,
        name: _rules[index].name,
        type: _rules[index].type,
        time: _rules[index].time,
        locationName: _rules[index].locationName,
        latitude: _rules[index].latitude,
        longitude: _rules[index].longitude,
        radius: _rules[index].radius,
        action: _rules[index].action,
        actionType: _rules[index].actionType,
        actionParams: _rules[index].actionParams,
        enabled: enabled,
        oneTimePerDay: _rules[index].oneTimePerDay,
      );
      await _saveRules();
    }
  }

  /// 销毁
  void dispose() {
    _checkTimer?.cancel();
  }
}
