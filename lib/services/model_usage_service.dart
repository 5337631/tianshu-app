import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 模型使用记录
class UsageRecord {
  final String model;
  final String provider;
  final int inputTokens;
  final int outputTokens;
  final DateTime timestamp;
  final String? taskType;

  UsageRecord({
    required this.model,
    required this.provider,
    required this.inputTokens,
    required this.outputTokens,
    DateTime? timestamp,
    this.taskType,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'model': model,
    'provider': provider,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'timestamp': timestamp.toIso8601String(),
    'taskType': taskType,
  };

  factory UsageRecord.fromJson(Map<String, dynamic> json) => UsageRecord(
    model: json['model'] ?? '',
    provider: json['provider'] ?? '',
    inputTokens: json['inputTokens'] ?? 0,
    outputTokens: json['outputTokens'] ?? 0,
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    taskType: json['taskType'],
  );

  int get totalTokens => inputTokens + outputTokens;
}

/// 模型用量统计服务
class ModelUsageService {
  static final ModelUsageService instance = ModelUsageService._internal();
  ModelUsageService._internal();

  SharedPreferences? _prefs;
  List<UsageRecord> _records = [];
  bool _initialized = false;

  List<UsageRecord> get records => List.unmodifiable(_records);

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadRecords();
    _initialized = true;
  }

  Future<void> _loadRecords() async {
    final json = _prefs?.getString('usage_records');
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        _records = list.map((e) => UsageRecord.fromJson(e)).toList();
      } catch (_) {
        _records = [];
      }
    }
  }

  Future<void> _saveRecords() async {
    final json = jsonEncode(_records.map((e) => e.toJson()).toList());
    await _prefs?.setString('usage_records', json);
  }

  /// 记录使用
  Future<void> record({
    required String model,
    required String provider,
    required int inputTokens,
    required int outputTokens,
    String? taskType,
  }) async {
    _records.add(UsageRecord(
      model: model,
      provider: provider,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      taskType: taskType,
    ));

    // 只保留最近 1000 条
    if (_records.length > 1000) {
      _records = _records.sublist(_records.length - 1000);
    }

    await _saveRecords();
  }

  /// 获取今日统计
  Map<String, dynamic> getTodayStats() {
    final now = DateTime.now();
    final todayRecords = _records.where((r) =>
      r.timestamp.year == now.year &&
      r.timestamp.month == now.month &&
      r.timestamp.day == now.day
    ).toList();

    int totalInput = 0;
    int totalOutput = 0;
    int requestCount = todayRecords.length;

    for (final r in todayRecords) {
      totalInput += r.inputTokens;
      totalOutput += r.outputTokens;
    }

    return {
      'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'requests': requestCount,
      'inputTokens': totalInput,
      'outputTokens': totalOutput,
      'totalTokens': totalInput + totalOutput,
    };
  }

  /// 获取本周统计
  Map<String, dynamic> getWeekStats() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekRecords = _records.where((r) =>
      r.timestamp.isAfter(weekStart)
    ).toList();

    int totalInput = 0;
    int totalOutput = 0;
    Map<String, int> modelCounts = {};

    for (final r in weekRecords) {
      totalInput += r.inputTokens;
      totalOutput += r.outputTokens;
      modelCounts[r.model] = (modelCounts[r.model] ?? 0) + 1;
    }

    return {
      'period': '${weekStart.month}/${weekStart.day} - ${now.month}/${now.day}',
      'requests': weekRecords.length,
      'inputTokens': totalInput,
      'outputTokens': totalOutput,
      'totalTokens': totalInput + totalOutput,
      'modelBreakdown': modelCounts,
    };
  }

  /// 获取月度统计
  Map<String, dynamic> getMonthStats() {
    final now = DateTime.now();
    final monthRecords = _records.where((r) =>
      r.timestamp.year == now.year && r.timestamp.month == now.month
    ).toList();

    int totalInput = 0;
    int totalOutput = 0;

    for (final r in monthRecords) {
      totalInput += r.inputTokens;
      totalOutput += r.outputTokens;
    }

    return {
      'month': '${now.year}-${now.month.toString().padLeft(2, '0')}',
      'requests': monthRecords.length,
      'inputTokens': totalInput,
      'outputTokens': totalOutput,
      'totalTokens': totalInput + totalOutput,
    };
  }

  /// 获取按模型分组统计
  Map<String, Map<String, int>> getByModel() {
    final Map<String, Map<String, int>> result = {};

    for (final r in _records) {
      if (!result.containsKey(r.model)) {
        result[r.model] = {'requests': 0, 'inputTokens': 0, 'outputTokens': 0};
      }
      result[r.model]!['requests'] = result[r.model]!['requests']! + 1;
      result[r.model]!['inputTokens'] = result[r.model]!['inputTokens']! + r.inputTokens;
      result[r.model]!['outputTokens'] = result[r.model]!['outputTokens']! + r.outputTokens;
    }

    return result;
  }

  /// 清除旧记录（保留最近 30 天）
  Future<void> cleanupOldRecords() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    _records = _records.where((r) => r.timestamp.isAfter(cutoff)).toList();
    await _saveRecords();
  }

  /// 清除所有记录
  Future<void> clearAll() async {
    _records.clear();
    await _saveRecords();
  }
}
