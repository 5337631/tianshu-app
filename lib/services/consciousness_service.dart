import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';
import 'memory_service.dart';

/// 意识条目 - 携带置信度
class ConsciousnessEntry {
  final String key;
  final String value;
  final double confidence; // 0.0-1.0
  final String source; // user_explicit / inferred / implied
  final DateTime timestamp;
  final bool isConflict; // 与已有信息冲突

  ConsciousnessEntry({
    required this.key,
    required this.value,
    this.confidence = 0.8,
    this.source = 'user_explicit',
    DateTime? timestamp,
    this.isConflict = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'key': key,
    'value': value,
    'confidence': confidence,
    'source': source,
    'timestamp': timestamp.toIso8601String(),
    'isConflict': isConflict,
  };

  factory ConsciousnessEntry.fromJson(Map<String, dynamic> json) =>
    ConsciousnessEntry(
      key: json['key'] ?? '',
      value: json['value'] ?? '',
      confidence: (json['confidence'] ?? 0.8).toDouble(),
      source: json['source'] ?? 'user_explicit',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isConflict: json['isConflict'] ?? false,
    );
}

/// 意识维度
enum ConsciousnessDimension {
  identity('身份', 0.08),
  personality('性格', 0.18),
  language('语言', 0.20),
  knowledge('知识', 0.14),
  memory('记忆', 0.18),
  workflow('工作流', 0.15),
  aspiration('抱负', 0.07);

  final String label;
  final double weight;
  const ConsciousnessDimension(this.label, this.weight);
}

/// 意识档案 - 完整结构
class ConsciousnessProfile {
  final Map<String, List<ConsciousnessEntry>> dimensions;
  final double maturity;
  final int totalEntries;
  final int conflictCount;
  final DateTime lastDistilled;
  final DateTime lastUpdated;

  ConsciousnessProfile({
    required this.dimensions,
    this.maturity = 0.0,
    this.totalEntries = 0,
    this.conflictCount = 0,
    DateTime? lastDistilled,
    DateTime? lastUpdated,
  }) : lastDistilled = lastDistilled ?? DateTime.now(),
       lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'dimensions': dimensions.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
    'maturity': maturity,
    'totalEntries': totalEntries,
    'conflictCount': conflictCount,
    'lastDistilled': lastDistilled.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory ConsciousnessProfile.fromJson(Map<String, dynamic> json) {
    final dims = <String, List<ConsciousnessEntry>>{};
    if (json['dimensions'] != null) {
      (json['dimensions'] as Map).forEach((k, v) {
        dims[k] = (v as List).map((e) => ConsciousnessEntry.fromJson(e)).toList();
      });
    }
    return ConsciousnessProfile(
      dimensions: dims,
      maturity: (json['maturity'] ?? 0).toDouble(),
      totalEntries: json['totalEntries'] ?? 0,
      conflictCount: json['conflictCount'] ?? 0,
      lastDistilled: DateTime.parse(json['lastDistilled'] ?? DateTime.now().toIso8601String()),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// 生成 system prompt 片段 (≤800 token)
  String toSystemPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('## 用户意识档案');
    buffer.writeln('基于日常对话蒸馏出的数字意识，用于个性化对话。\n');

    for (final dim in ConsciousnessDimension.values) {
      final entries = dimensions[dim.label];
      if (entries == null || entries.isEmpty) continue;

      // 按置信度排序，取前5条
      final top = entries.where((e) => !e.isConflict)
          .toList()
        ..sort((a, b) => b.confidence.compareTo(a.confidence));

      if (top.isEmpty) continue;

      buffer.writeln('**${dim.label}** (${(dim.weight * 100).toInt()}%):');
      for (final entry in top.take(5)) {
        final src = entry.source == 'user_explicit' ? '' : ' [推断]';
        buffer.writeln('- ${entry.value}$src');
      }
      buffer.writeln();
    }

    // 冲突提醒
    if (conflictCount > 0) {
      buffer.writeln('> 注意: 有 $conflictCount 条信息存在冲突，已标记待确认。\n');
    }

    return buffer.toString();
  }

  /// 生成灵魂对话 prompt
  String toRolePlayPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('你现在是用户的数字意识克隆体。');
    buffer.writeln('请根据以下人格档案，以用户的身份和风格回应。\n');
    buffer.writeln(toSystemPrompt());
    buffer.writeln('\n**关键规则**：');
    buffer.writeln('- 用用户的语言风格说话');
    buffer.writeln('- 反映用户的价值观和决策模式');
    buffer.writeln('- 如果被问"你是AI吗"，如实承认');
    return buffer.toString();
  }

  /// 生成简短摘要 (≤200 token)
  String toSummary() {
    final parts = <String>[];

    // 身份
    final identity = dimensions['身份'];
    if (identity != null && identity.isNotEmpty) {
      parts.add(identity.first.value);
    }

    // 性格
    final personality = dimensions['性格'];
    if (personality != null && personality.isNotEmpty) {
      parts.add(personality.first.value);
    }

    // 抱负
    final aspiration = dimensions['抱负'];
    if (aspiration != null && aspiration.isNotEmpty) {
      parts.add('目标: ${aspiration.first.value}');
    }

    return parts.isEmpty ? '用户档案收集中...' : parts.join(' | ');
  }
}

/// 意识服务 - 完整实现 (借鉴 Soul Archive)
class ConsciousnessService {
  static final ConsciousnessService instance = ConsciousnessService._internal();
  ConsciousnessService._internal();

  ConsciousnessProfile? _profile;
  final Map<String, String> _rawInputs = {};
  bool _initialized = false;

  ConsciousnessProfile? get profile => _profile;
  bool get isReady => _initialized;
  List<String> get uploadedCategories => _rawInputs.keys.toList();

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    await _loadProfile();
    await _loadRawInputs();
    _initialized = true;
  }

  /// 加载档案
  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('consciousness_profile');
    if (json != null) {
      try {
        _profile = ConsciousnessProfile.fromJson(jsonDecode(json));
      } catch (_) {}
    }
  }

  /// 保存档案
  Future<void> _saveProfile() async {
    if (_profile == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('consciousness_profile', jsonEncode(_profile!.toJson()));
  }

  /// 加载原始输入
  Future<void> _loadRawInputs() async {
    for (final dim in ConsciousnessDimension.values) {
      final content = await MemoryService.instance.read('consciousness/${dim.label}.md');
      if (content.isNotEmpty) _rawInputs[dim.label] = content;
    }
    // 额外分类
    for (final cat in ['人际关系', '生活经历', '专业技能', '情感偏好']) {
      final content = await MemoryService.instance.read('consciousness/$cat.md');
      if (content.isNotEmpty) _rawInputs[cat] = content;
    }
  }

  /// 保存输入
  Future<void> saveInput(String category, String content) async {
    _rawInputs[category] = content;
    await MemoryService.instance.write('consciousness/$category.md', content);
  }

  /// 获取原始输入
  String? getRawInput(String category) => _rawInputs[category];

  /// 计算成熟度
  double calculateMaturity() {
    if (_rawInputs.isEmpty) return 0.0;

    double score = 0.0;

    // 分类覆盖度 (40%)
    score += (_rawInputs.length / 11).clamp(0, 1) * 40;

    // 内容完整度 (30%)
    int totalChars = _rawInputs.values.fold(0, (s, c) => s + c.length);
    score += (totalChars / 1500).clamp(0, 1) * 30;

    // 蒸馏结果 (20%)
    if (_profile != null) {
      final dimCount = _profile!.dimensions.values.where((e) => e.isNotEmpty).length;
      score += (dimCount / 7).clamp(0, 1) * 20;
    }

    // 一致性 (10%)
    if (_rawInputs.length >= 5) score += 10;

    return score.clamp(0, 100);
  }

  /// ═══════════════════════════════════════
  ///  灵魂沉淀 - 从对话提取人格信息
  /// ═══════════════════════════════════════
  Future<List<ConsciousnessEntry>> extractFromConversation(String conversation) async {
    final prompt = _buildExtractPrompt(conversation);
    final result = await AiService.instance.distillConsciousness(prompt);
    if (result == null) return [];

    return _parseExtractResult(result);
  }

  String _buildExtractPrompt(String conversation) {
    return '''你是一个人格信息提取引擎。从以下对话中提取用户的人格信息。

## 对话内容
$conversation

## 提取维度 (JSON 数组格式)
每个条目包含:
- dimension: 维度名 (身份/性格/语言/知识/记忆/工作流/抱负)
- key: 信息键名
- value: 信息内容
- confidence: 置信度 (0.0-1.0)
- source: 来源 (user_explicit=用户明示/inferred=推断/implied=暗示)

## 规则
1. 只提取高置信度信息 (confidence > 0.5)
2. 用户明确说的 > 推断的 > 暗示的
3. 输出 JSON 数组，例如:
[{"dimension":"性格","key":"决策风格","value":"数据驱动型","confidence":0.9,"source":"user_explicit"}]''';
  }

  List<ConsciousnessEntry> _parseExtractResult(String result) {
    try {
      // 提取 JSON 部分
      final jsonStr = result.replaceAll(RegExp(r'```json?\s*'), '').replaceAll('```', '').trim();
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((e) => ConsciousnessEntry(
        key: e['key'] ?? '',
        value: e['value'] ?? '',
        confidence: (e['confidence'] ?? 0.8).toDouble(),
        source: e['source'] ?? 'inferred',
      )).toList();
    } catch (_) {
      return [];
    }
  }

  /// 添加条目到档案 (带冲突检测和去重)
  Future<void> addEntry(String dimension, ConsciousnessEntry entry) async {
    _profile ??= ConsciousnessProfile(dimensions: {});

    final entries = _profile!.dimensions[dimension] ?? [];

    // 相似度去重 (≥0.85 合并)
    final similarIndex = entries.indexWhere((e) =>
      _calculateSimilarity(e.value, entry.value) >= 0.85);

    if (similarIndex >= 0) {
      // 合并: 保留更高置信度
      if (entry.confidence > entries[similarIndex].confidence) {
        entries[similarIndex] = entry;
      }
    } else {
      // 冲突检测
      final conflicting = entries.where((e) =>
        _isConflicting(e.value, entry.value)).toList();

      if (conflicting.isNotEmpty) {
        // 标记冲突，不自动覆盖
        entry = ConsciousnessEntry(
          key: entry.key,
          value: entry.value,
          confidence: entry.confidence,
          source: entry.source,
          isConflict: true,
        );
      }

      entries.add(entry);
    }

    _profile!.dimensions[dimension] = entries;
    _profile = ConsciousnessProfile(
      dimensions: _profile!.dimensions,
      maturity: calculateMaturity(),
      totalEntries: _profile!.dimensions.values.fold(0, (s, e) => s + e.length),
      conflictCount: _countConflicts(),
      lastUpdated: DateTime.now(),
      lastDistilled: _profile!.lastDistilled,
    );

    await _saveProfile();
  }

  /// 计算文本相似度（适合中文的关键词重叠 + 包含关系综合评分）
  double _calculateSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    // 1. 关键词重叠评分（按标点/空格切分，适合中文）
    final keywordsA = a.split(RegExp(r'[，。！？、\s,.;!?]+')).where((s) => s.length >= 2).toSet();
    final keywordsB = b.split(RegExp(r'[，。！？、\s,.;!?]+')).where((s) => s.length >= 2).toSet();

    if (keywordsA.isNotEmpty && keywordsB.isNotEmpty) {
      final intersection = keywordsA.intersection(keywordsB).length;
      final union = keywordsA.union(keywordsB).length;
      final keywordScore = union > 0 ? intersection / union : 0.0;
      if (keywordScore >= 0.5) return keywordScore;
    }

    // 2. 包含关系检查（如 "内向" 和 "性格内向"）
    if (a.contains(b) || b.contains(a)) return 0.8;

    // 3. 字符级重叠（仅作为兜底，权重降低）
    final setA = a.split('').toSet();
    final setB = b.split('').toSet();
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;

    return union > 0 ? intersection / union * 0.6 : 0.0;
  }

  /// 检测是否冲突
  bool _isConflicting(String existing, String newEntry) {
    // 简单冲突检测: 包含反义词
    final conflictPairs = [
      ['内向', '外向'],
      ['理性', '感性'],
      ['乐观', '悲观'],
      ['主动', '被动'],
      ['严谨', '随意'],
      ['独立', '依赖'],
    ];

    for (final pair in conflictPairs) {
      if ((existing.contains(pair[0]) && newEntry.contains(pair[1])) ||
          (existing.contains(pair[1]) && newEntry.contains(pair[0]))) {
        return true;
      }
    }
    return false;
  }

  int _countConflicts() {
    int count = 0;
    final dimensions = _profile?.dimensions;
    for (final entries in dimensions.values) {
      count += entries.where((e) => e.isConflict).length;
    }
    return count;
  }

  /// ═══════════════════════════════════════
  ///  蒸馏 - 从原始输入生成结构化档案
  /// ═══════════════════════════════════════
  Future<bool> distill() async {
    if (_rawInputs.isEmpty) return false;

    try {
      final prompt = _buildDistillPrompt();
      final result = await AiService.instance.distillConsciousness(prompt);
      if (result == null || result.isEmpty) return false;

      _profile = _parseDistillResult(result);
      _profile = ConsciousnessProfile(
        dimensions: _profile!.dimensions,
        maturity: calculateMaturity(),
        totalEntries: _profile!.dimensions.values.fold(0, (s, e) => s + e.length),
        conflictCount: _countConflicts(),
        lastDistilled: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _saveProfile();
      await MemoryService.instance.write('consciousness/distilled.md', result);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _buildDistillPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('你是一个专业的意识蒸馏引擎。分析以下个人信息，输出结构化的意识档案。');
    buffer.writeln();
    buffer.writeln('## 用户原始信息');
    for (final entry in _rawInputs.entries) {
      buffer.writeln('\n### ${entry.key}\n${entry.value}');
    }
    buffer.writeln();
    buffer.writeln('## 输出格式 (JSON)');
    buffer.writeln('{"dimensions":{"身份":[{"key":"...","value":"...","confidence":0.9,"source":"user_explicit"}],...}}');
    buffer.writeln();
    buffer.writeln('## 维度说明');
    buffer.writeln('- 身份: 姓名/年龄/职业/所在地/生活习惯');
    buffer.writeln('- 性格: MBTI/特质/价值观/决策风格');
    buffer.writeln('- 语言: 口头禅/句式/幽默风格/用词习惯');
    buffer.writeln('- 知识: 关注话题/立场/方法论');
    buffer.writeln('- 记忆: 重要事件/情感触发');
    buffer.writeln('- 工作流: 工具/技术栈/硬规则/输出偏好');
    buffer.writeln('- 抱负: 目标/在做项目/想学技能');
    return buffer.toString();
  }

  ConsciousnessProfile _parseDistillResult(String result) {
    try {
      final jsonStr = result.replaceAll(RegExp(r'```json?\s*'), '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = json.decode(jsonStr);

      final dimensions = <String, List<ConsciousnessEntry>>{};
      if (data['dimensions'] != null) {
        (data['dimensions'] as Map).forEach((k, v) {
          dimensions[k] = (v as List).map((e) => ConsciousnessEntry(
            key: e['key'] ?? '',
            value: e['value'] ?? '',
            confidence: (e['confidence'] ?? 0.8).toDouble(),
            source: e['source'] ?? 'user_explicit',
          )).toList();
        });
      }

      return ConsciousnessProfile(dimensions: dimensions);
    } catch (_) {
      return ConsciousnessProfile(dimensions: {});
    }
  }

  /// ═══════════════════════════════════════
  ///  灵魂对话 - 角色扮演 prompt
  /// ═══════════════════════════════════════
  Future<String> getRolePlayPrompt() async {
    if (_profile == null) return '';
    return _profile!.toRolePlayPrompt();
  }

  /// ═══════════════════════════════════════
  ///  上下文注入 - ≤800 token 人格摘要
  /// ═══════════════════════════════════════
  Future<String> getContextInjection() async {
    if (_profile == null) return '';
    return _profile!.toSystemPrompt();
  }

  /// ═══════════════════════════════════════
  ///  灵魂报告 - 人格画像数据
  /// ═══════════════════════════════════════
  Map<String, dynamic> getReportData() {
    if (_profile == null) return {};

    final dimensionScores = <String, double>{};
    for (final dim in ConsciousnessDimension.values) {
      final entries = _profile!.dimensions[dim.label] ?? [];
      if (entries.isEmpty) {
        dimensionScores[dim.label] = 0;
      } else {
        final avgConfidence = entries.map((e) => e.confidence).reduce((a, b) => a + b) / entries.length;
        dimensionScores[dim.label] = avgConfidence * dim.weight * 100;
      }
    }

    return {
      'maturity': _profile!.maturity,
      'totalEntries': _profile!.totalEntries,
      'conflictCount': _profile!.conflictCount,
      'dimensionScores': dimensionScores,
      'dimensions': _profile!.dimensions.map((k, v) => MapEntry(k, v.length)),
      'lastDistilled': _profile!.lastDistilled.toIso8601String(),
    };
  }

  /// ═══════════════════════════════════════
  ///  灵魂报告 - 生成 HTML 人格画像
  /// ═══════════════════════════════════════
  Future<String> generateReport() async {
    if (_profile == null) return '';

    final reportData = getReportData();
    final dimensions = reportData['dimensionScores'] as Map<String, double>;

    // 获取各维度的详细条目
    final dimensionDetails = <String, List<String>>{};
    for (final dim in ConsciousnessDimension.values) {
      final entries = _profile!.dimensions[dim.label] ?? [];
      dimensionDetails[dim.label] = entries
          .where((e) => !e.isConflict)
          .map((e) => '${e.value} (${(e.confidence * 100).toInt()}%)')
          .toList();
    }

    final html = '''<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>灵魂报告 - 天枢</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #1a1a2e; color: #fff; min-height: 100vh; padding: 20px; }
.container { max-width: 800px; margin: 0 auto; }
.header { text-align: center; padding: 40px 0; }
.header h1 { font-size: 32px; background: linear-gradient(135deg, #ffd700, #ff8c00); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.header p { color: #59ffffff; margin-top: 8px; }
.card { background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 24px; margin: 16px 0; backdrop-filter: blur(20px); }
.card h2 { font-size: 18px; margin-bottom: 16px; color: #ffd700; }
.stat-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.stat { text-align: center; }
.stat-value { font-size: 32px; font-weight: bold; color: #ffd700; }
.stat-label { font-size: 12px; color: #59ffffff; margin-top: 4px; }
.dimension { margin: 12px 0; }
.dimension-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.dimension-name { font-size: 14px; font-weight: 500; }
.dimension-weight { font-size: 12px; color: #ffd700; }
.dimension-bar { height: 8px; background: rgba(255,255,255,0.1); border-radius: 4px; overflow: hidden; }
.dimension-fill { height: 100%; background: linear-gradient(90deg, #ffd700, #ff8c00); border-radius: 4px; transition: width 0.5s; }
.dimension-items { margin-top: 8px; padding-left: 12px; }
.dimension-item { font-size: 13px; color: #59ffffff; padding: 4px 0; }
.conflict-badge { display: inline-block; background: rgba(255,0,0,0.2); color: #ff6b6b; padding: 2px 8px; border-radius: 10px; font-size: 11px; }
.footer { text-align: center; padding: 20px; color: #59ffffff; font-size: 12px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>灵魂报告</h1>
    <p>天枢数字意识系统 · ${_formatDateTime(_profile!.lastDistilled)}</p>
  </div>

  <div class="card">
    <h2>总体概况</h2>
    <div class="stat-grid">
      <div class="stat">
        <div class="stat-value">${_profile!.maturity.toInt()}%</div>
        <div class="stat-label">成熟度</div>
      </div>
      <div class="stat">
        <div class="stat-value">${_profile!.totalEntries}</div>
        <div class="stat-label">信息条目</div>
      </div>
      <div class="stat">
        <div class="stat-value">${_profile!.conflictCount}</div>
        <div class="stat-label">待确认冲突</div>
      </div>
    </div>
  </div>

  <div class="card">
    <h2>7 维人格画像</h2>
    ${ConsciousnessDimension.values.map((dim) {
      final score = dimensions[dim.label] ?? 0;
      final items = dimensionDetails[dim.label] ?? [];
      return '''
    <div class="dimension">
      <div class="dimension-header">
        <span class="dimension-name">${dim.label}</span>
        <span class="dimension-weight">${(dim.weight * 100).toInt()}% 权重 · ${score.toInt()} 分</span>
      </div>
      <div class="dimension-bar">
        <div class="dimension-fill" style="width: ${score.clamp(0, 100)}%"></div>
      </div>
      <div class="dimension-items">
        ${items.map((item) => '<div class="dimension-item">· $item</div>').join('')}
        ${items.isEmpty ? '<div class="dimension-item" style="color:#59ffffff">暂无数据</div>' : ''}
      </div>
    </div>''';
    }).join('')}
  </div>

  <div class="footer">
    由天枢数字意识系统生成 · 数据本地存储，未上传云端
  </div>
</div>
</body>
</html>''';

    return html;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// ═══════════════════════════════════════
  ///  AI 自我改进 - 反思、批评、蒸馏
  /// ═══════════════════════════════════════

  /// 反思 - 任务后回顾
  Future<String> reflect(String taskDescription, String outcome) async {
    final prompt = '''你是一个自我反思引擎。请分析以下任务的执行情况：

任务: $taskDescription
结果: $outcome

请输出:
【做得好的】列出 2-3 个做得好的方面
【做得不好的】列出 1-2 个需要改进的方面
【学到的】从中学到了什么经验''';

    final result = await AiService.instance.distillConsciousness(prompt);

    // 保存反思记录
    await _saveReflection(taskDescription, outcome, result ?? '');

    return result ?? '反思失败';
  }

  Future<void> _saveReflection(String task, String outcome, String content) async {
    // TODO: 保存反思记录到记忆库
  }

  double _calculateSimilarity(String a, String b) {
    // 1. 精确匹配
    if (a == b) return 1.0;

    // 2. 包含关系检查（如 "内向" 和 "性格内向"）
    if (a.contains(b) || b.contains(a)) return 0.8;

    // 3. 字符级重叠（仅作为兜底，权重降低）
    final setA = a.split('').toSet();
    final setB = b.split('').toSet();
    final intersection = setA.intersection(setB).length;
    final union = setA.union(setB).length;

    return union > 0 ? intersection / union * 0.6 : 0.0;
  }

  /// 检测是否冲突
  bool _isConflicting(String existing, String newEntry) {
    // 简单冲突检测: 包含反义词
    final conflictPairs = [
      ['内向', '外向'],
      ['理性', '感性'],
      ['乐观', '悲观'],
      ['主动', '被动'],
      ['严谨', '随意'],
      ['独立', '依赖'],
    ];

    for (final pair in conflictPairs) {
      if ((existing.contains(pair[0]) && newEntry.contains(pair[1])) ||
          (existing.contains(pair[1]) && newEntry.contains(pair[0]))) {
        return true;
      }
    }
    return false;
  }

  int _countConflicts() {
    int count = 0;
    final dimensions = _profile?.dimensions;
    if (dimensions == null) return 0;
    for (final entries in dimensions.values) {
      count += entries.where((e) => e.isConflict).length;
    }
    return count;
  }

  /// ═══════════════════════════════════════
  ///  蒸馏 - 从原始输入生成结构化档案
  /// ═══════════════════════════════════════
  Future<bool> distill() async {
    if (_rawInputs.isEmpty) return false;

    try {
      final prompt = _buildDistillPrompt();
      final result = await AiService.instance.distillConsciousness(prompt);
      if (result == null || result.isEmpty) return false;

      _profile = _parseDistillResult(result);
      _profile = ConsciousnessProfile(
        dimensions: _profile!.dimensions,
        maturity: calculateMaturity(),
        totalEntries: _profile!.dimensions.values.fold(0, (s, e) => s + e.length),
        conflictCount: _countConflicts(),
        lastDistilled: DateTime.now(),
        lastUpdated: DateTime.now(),
      );

      await _saveProfile();
      await MemoryService.instance.write('consciousness/distilled.md', result);
      return true;
    } catch (e) {
      return false;
    }
  }

  String _buildDistillPrompt() {
    final buffer = StringBuffer();
    buffer.writeln('你是一个专业的意识蒸馏引擎。分析以下个人信息，输出结构化的意识档案。');
    buffer.writeln();
    buffer.writeln('## 用户原始信息');
    for (final entry in _rawInputs.entries) {
      buffer.writeln('\n### ${entry.key}\n${entry.value}');
    }
    buffer.writeln();
    buffer.writeln('## 输出格式 (JSON)');
    buffer.writeln('{"dimensions":{"身份":[{"key":"...","value":"...","confidence":0.9,"source":"user_explicit"}],...}}');
    buffer.writeln();
    buffer.writeln('## 维度说明');
    buffer.writeln('- 身份: 姓名/年龄/职业/所在地/生活习惯');
    buffer.writeln('- 性格: MBTI/特质/价值观/决策风格');
    buffer.writeln('- 语言: 口头禅/句式/幽默风格/用词习惯');
    buffer.writeln('- 知识: 关注话题/立场/方法论');
    buffer.writeln('- 记忆: 重要事件/情感触发');
    buffer.writeln('- 工作流: 工具/技术栈/硬规则/输出偏好');
    buffer.writeln('- 抱负: 目标/在做项目/想学技能');
    return buffer.toString();
  }

  ConsciousnessProfile _parseDistillResult(String result) {
    try {
      final jsonStr = result.replaceAll(RegExp(r'```json?\s*'), '').replaceAll('```', '').trim();
      final Map<String, dynamic> data = json.decode(jsonStr);

      final dimensions = <String, List<ConsciousnessEntry>>{};
      if (data['dimensions'] != null) {
        (data['dimensions'] as Map).forEach((k, v) {
          dimensions[k] = (v as List).map((e) => ConsciousnessEntry(
            key: e['key'] ?? '',
            value: e['value'] ?? '',
            confidence: (e['confidence'] ?? 0.8).toDouble(),
            source: e['source'] ?? 'user_explicit',
          )).toList();
        });
      }

      return ConsciousnessProfile(dimensions: dimensions);
    } catch (_) {
      return ConsciousnessProfile(dimensions: {});
    }
  }

  /// ═══════════════════════════════════════
  ///  灵魂对话 - 角色扮演 prompt
  /// ═══════════════════════════════════════
  Future<String> getRolePlayPrompt() async {
    if (_profile == null) return '';
    return _profile!.toRolePlayPrompt();
  }

  /// ═══════════════════════════════════════
  ///  上下文注入 - ≤800 token 人格摘要
  /// ═══════════════════════════════════════
  Future<String> getContextInjection() async {
    if (_profile == null) return '';
    return _profile!.toSystemPrompt();
  }

  /// ═══════════════════════════════════════
  ///  灵魂报告 - 人格画像数据
  /// ═══════════════════════════════════════
  Map<String, dynamic> getReportData() {
    if (_profile == null) return {};

    final dimensionScores = <String, double>{};
    for (final dim in ConsciousnessDimension.values) {
      final entries = _profile!.dimensions[dim.label] ?? [];
      if (entries.isEmpty) {
        dimensionScores[dim.label] = 0;
      } else {
        final avgConfidence = entries.map((e) => e.confidence).reduce((a, b) => a + b) / entries.length;
        dimensionScores[dim.label] = avgConfidence * dim.weight * 100;
      }
    }

    return {
      'maturity': _profile!.maturity,
      'totalEntries': _profile!.totalEntries,
      'conflictCount': _profile!.conflictCount,
      'dimensionScores': dimensionScores,
      'dimensions': _profile!.dimensions.map((k, v) => MapEntry(k, v.length)),
      'lastDistilled': _profile!.lastDistilled.toIso8601String(),
    };
  }

  /// ═══════════════════════════════════════
  ///  灵魂报告 - 生成 HTML 人格画像
  /// ═══════════════════════════════════════
  Future<String> generateReport() async {
    if (_profile == null) return '';

    final reportData = getReportData();
    final dimensions = reportData['dimensionScores'] as Map<String, double>;

    // 获取各维度的详细条目
    final dimensionDetails = <String, List<String>>{};
    for (final dim in ConsciousnessDimension.values) {
      final entries = _profile!.dimensions[dim.label] ?? [];
      dimensionDetails[dim.label] = entries
          .where((e) => !e.isConflict)
          .map((e) => '${e.value} (${(e.confidence * 100).toInt()}%)')
          .toList();
    }

    final html = '''<!DOCTYPE html>
<html lang="zh">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>灵魂报告 - 天枢</title>
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; background: #1a1a2e; color: #fff; min-height: 100vh; padding: 20px; }
.container { max-width: 800px; margin: 0 auto; }
.header { text-align: center; padding: 40px 0; }
.header h1 { font-size: 32px; background: linear-gradient(135deg, #ffd700, #ff8c00); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
.header p { color: #59ffffff; margin-top: 8px; }
.card { background: rgba(255,255,255,0.04); border: 1px solid rgba(255,255,255,0.08); border-radius: 16px; padding: 24px; margin: 16px 0; backdrop-filter: blur(20px); }
.card h2 { font-size: 18px; margin-bottom: 16px; color: #ffd700; }
.stat-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
.stat { text-align: center; }
.stat-value { font-size: 32px; font-weight: bold; color: #ffd700; }
.stat-label { font-size: 12px; color: #59ffffff; margin-top: 4px; }
.dimension { margin: 12px 0; }
.dimension-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
.dimension-name { font-size: 14px; font-weight: 500; }
.dimension-weight { font-size: 12px; color: #ffd700; }
.dimension-bar { height: 8px; background: rgba(255,255,255,0.1); border-radius: 4px; overflow: hidden; }
.dimension-fill { height: 100%; background: linear-gradient(90deg, #ffd700, #ff8c00); border-radius: 4px; transition: width 0.5s; }
.dimension-items { margin-top: 8px; padding-left: 12px; }
.dimension-item { font-size: 13px; color: #59ffffff; padding: 4px 0; }
.conflict-badge { display: inline-block; background: rgba(255,0,0,0.2); color: #ff6b6b; padding: 2px 8px; border-radius: 10px; font-size: 11px; }
.footer { text-align: center; padding: 20px; color: #59ffffff; font-size: 12px; }
</style>
</head>
<body>
<div class="container">
  <div class="header">
    <h1>灵魂报告</h1>
    <p>天枢数字意识系统 · ${_formatDateTime(_profile!.lastDistilled)}</p>
  </div>

  <div class="card">
    <h2>总体概况</h2>
    <div class="stat-grid">
      <div class="stat">
        <div class="stat-value">${_profile!.maturity.toInt()}%</div>
        <div class="stat-label">成熟度</div>
      </div>
      <div class="stat">
        <div class="stat-value">${_profile!.totalEntries}</div>
        <div class="stat-label">信息条目</div>
      </div>
      <div class="stat">
        <div class="stat-value">${_profile!.conflictCount}</div>
        <div class="stat-label">待确认冲突</div>
      </div>
    </div>
  </div>

  <div class="card">
    <h2>7 维人格画像</h2>
    ${ConsciousnessDimension.values.map((dim) {
      final score = dimensions[dim.label] ?? 0;
      final items = dimensionDetails[dim.label] ?? [];
      return '''
    <div class="dimension">
      <div class="dimension-header">
        <span class="dimension-name">${dim.label}</span>
        <span class="dimension-weight">${(dim.weight * 100).toInt()}% 权重 · ${score.toInt()} 分</span>
      </div>
      <div class="dimension-bar">
        <div class="dimension-fill" style="width: ${score.clamp(0, 100)}%"></div>
      </div>
      <div class="dimension-items">
        ${items.map((item) => '<div class="dimension-item">· $item</div>').join('')}
        ${items.isEmpty ? '<div class="dimension-item" style="color:#59ffffff">暂无数据</div>' : ''}
      </div>
    </div>''';
    }).join('')}
  </div>

  <div class="footer">
    由天枢数字意识系统生成 · 数据本地存储，未上传云端
  </div>
</div>
</body>
</html>''';

    return html;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// ═══════════════════════════════════════
  ///  AI 自我改进 - 反思、批评、蒸馏
  /// ═══════════════════════════════════════

  /// 反思 - 任务后回顾
  Future<String> reflect(String taskDescription, String outcome) async {
    final prompt = '''你是一个自我反思引擎。请分析以下任务的执行情况：

任务: $taskDescription
结果: $outcome

请输出:
【做得好的】列出 2-3 个做得好的方面
【做得不好的】列出 1-2 个需要改进的方面
【学到的】从中学到了什么经验''';

    final result = await AiService.instance.distillConsciousness(prompt);

    // 保存反思记录
    await _saveReflection(taskDescription, outcome, result ?? '');

    return result ?? '反思失败';
  }

  Future<void> _saveReflection(String task, String outcome, String reflection) async {
    final entry = {
      'task': task,
      'outcome': outcome,
      'reflection': reflection,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final path = 'consciousness/reflections.jsonl';
    final existing = await MemoryService.instance.read(path);
    final lines = existing.isNotEmpty ? existing.split('\n').where((l) => l.isNotEmpty).toList() : [];
    lines.add(jsonEncode(entry));
    await MemoryService.instance.write(path, lines.join('\n'));
  }

  /// 自我批评 - 用户纠正时记录
  Future<void> recordCorrection(String userFeedback, String myResponse) async {
    final prompt = '''分析这个纠正：

用户反馈: $userFeedback
我的回复: $myResponse

提取:
1. 我犯了什么错误
2. 正确的做法是什么
3. 这个错误的类别（事实错误/理解偏差/风格不当/其他）''';

    final result = await AiService.instance.distillConsciousness(prompt);

    final entry = {
      'feedback': userFeedback,
      'myResponse': myResponse,
      'analysis': result,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final path = 'consciousness/corrections.jsonl';
    final existing = await MemoryService.instance.read(path);
    final lines = existing.isNotEmpty ? existing.split('\n').where((l) => l.isNotEmpty).toList() : [];
    lines.add(jsonEncode(entry));
    await MemoryService.instance.write(path, lines.join('\n'));
  }

  /// 模式蒸馏 - 从反思/批评中提炼行为模式
  Future<String> distillPatterns() async {
    // 读取所有反思和批评
    final reflections = await MemoryService.instance.read('consciousness/reflections.jsonl');
    final corrections = await MemoryService.instance.read('consciousness/corrections.jsonl');

    if (reflections.isEmpty && corrections.isEmpty) return '暂无数据可蒸馏';

    final prompt = '''你是行为模式蒸馏引擎。从以下反思和批评记录中提炼行为模式：

## 反思记录
$reflections

## 批评记录
$corrections

请输出:
【行为模式】列出 3-5 条核心行为模式
【改进方向】基于批评记录，列出需要改进的方向
【优势领域】基于反思记录，列出做得好的领域''';

    final result = await AiService.instance.distillConsciousness(prompt);

    // 保存蒸馏结果
    await MemoryService.instance.write('consciousness/patterns.md', result ?? '');

    return result ?? '蒸馏失败';
  }

  /// 获取状态摘要
  Future<Map<String, dynamic>> getSelfImprovementStatus() async {
    final reflections = await MemoryService.instance.read('consciousness/reflections.jsonl');
    final corrections = await MemoryService.instance.read('consciousness/corrections.jsonl');
    final patterns = await MemoryService.instance.read('consciousness/patterns.md');

    return {
      'reflectionCount': reflections.isNotEmpty ? reflections.split('\n').where((l) => l.isNotEmpty).length : 0,
      'correctionCount': corrections.isNotEmpty ? corrections.split('\n').where((l) => l.isNotEmpty).length : 0,
      'hasPatterns': patterns.isNotEmpty,
    };
  }

  /// 重置
  Future<void> reset() async {
    _profile = null;
    _rawInputs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('consciousness_profile');
    await prefs.remove('consciousness_evolution_count');
  }
}
g reflection) async {
    final entry = {
      'task': task,
      'outcome': outcome,
      'reflection': reflection,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final path = 'consciousness/reflections.jsonl';
    final existing = await MemoryService.instance.read(path);
    final lines = existing.isNotEmpty ? existing.split('\n').where((l) => l.isNotEmpty).toList() : [];
    lines.add(jsonEncode(entry));
    await MemoryService.instance.write(path, lines.join('\n'));
  }

  /// 自我批评 - 用户纠正时记录
  Future<void> recordCorrection(String userFeedback, String myResponse) async {
    final prompt = '''分析这个纠正：

用户反馈: $userFeedback
我的回复: $myResponse

提取:
1. 我犯了什么错误
2. 正确的做法是什么
3. 这个错误的类别（事实错误/理解偏差/风格不当/其他）''';

    final result = await AiService.instance.distillConsciousness(prompt);

    final entry = {
      'feedback': userFeedback,
      'myResponse': myResponse,
      'analysis': result,
      'timestamp': DateTime.now().toIso8601String(),
    };

    final path = 'consciousness/corrections.jsonl';
    final existing = await MemoryService.instance.read(path);
    final lines = existing.isNotEmpty ? existing.split('\n').where((l) => l.isNotEmpty).toList() : [];
    lines.add(jsonEncode(entry));
    await MemoryService.instance.write(path, lines.join('\n'));
  }

  /// 模式蒸馏 - 从反思/批评中提炼行为模式
  Future<String> distillPatterns() async {
    // 读取所有反思和批评
    final reflections = await MemoryService.instance.read('consciousness/reflections.jsonl');
    final corrections = await MemoryService.instance.read('consciousness/corrections.jsonl');

    if (reflections.isEmpty && corrections.isEmpty) return '暂无数据可蒸馏';

    final prompt = '''你是行为模式蒸馏引擎。从以下反思和批评记录中提炼行为模式：

## 反思记录
$reflections

## 批评记录
$corrections

请输出:
【行为模式】列出 3-5 条核心行为模式
【改进方向】基于批评记录，列出需要改进的方向
【优势领域】基于反思记录，列出做得好的领域''';

    final result = await AiService.instance.distillConsciousness(prompt);

    // 保存蒸馏结果
    await MemoryService.instance.write('consciousness/patterns.md', result ?? '');

    return result ?? '蒸馏失败';
  }

  /// 获取状态摘要
  Future<Map<String, dynamic>> getSelfImprovementStatus() async {
    final reflections = await MemoryService.instance.read('consciousness/reflections.jsonl');
    final corrections = await MemoryService.instance.read('consciousness/corrections.jsonl');
    final patterns = await MemoryService.instance.read('consciousness/patterns.md');

    return {
      'reflectionCount': reflections.isNotEmpty ? reflections.split('\n').where((l) => l.isNotEmpty).length : 0,
      'correctionCount': corrections.isNotEmpty ? corrections.split('\n').where((l) => l.isNotEmpty).length : 0,
      'hasPatterns': patterns.isNotEmpty,
    };
  }

  /// 重置
  Future<void> reset() async {
    _profile = null;
    _rawInputs.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('consciousness_profile');
    await prefs.remove('consciousness_evolution_count');
  }
}
