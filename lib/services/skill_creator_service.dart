import 'dart:convert';
import 'ai_service.dart';
import 'memory_service.dart';

/// 技能定义
class SkillDefinition {
  final String name;
  final String description;
  final String category;
  final String trigger;
  final String action;
  final Map<String, dynamic> params;

  SkillDefinition({
    required this.name,
    required this.description,
    required this.category,
    required this.trigger,
    required this.action,
    this.params = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    'category': category,
    'trigger': trigger,
    'action': action,
    'params': params,
  };

  factory SkillDefinition.fromJson(Map<String, dynamic> json) => SkillDefinition(
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    category: json['category'] ?? '',
    trigger: json['trigger'] ?? '',
    action: json['action'] ?? '',
    params: Map<String, dynamic>.from(json['params'] ?? {}),
  );

  /// 转换为 Markdown 格式
  String toMarkdown() {
    return '''---
name: $name
description: $description
category: $category
---

# $description

## 触发条件
$trigger

## 执行动作
$action

## 参数
${params.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}
''';
  }
}

/// 技能创建器服务
class SkillCreatorService {
  static final SkillCreatorService instance = SkillCreatorService._internal();
  SkillCreatorService._internal();

  final List<SkillDefinition> _customSkills = [];
  bool _initialized = false;

  List<SkillDefinition> get customSkills => List.unmodifiable(_customSkills);

  Future<void> init() async {
    if (_initialized) return;
    await _loadSkills();
    _initialized = true;
  }

  Future<void> _loadSkills() async {
    final content = await MemoryService.instance.read('skills/custom_skills.json');
    if (content.isNotEmpty) {
      try {
        final list = json.decode(content) as List;
        _customSkills.addAll(list.map((e) => SkillDefinition.fromJson(e)));
      } catch (_) {}
    }
  }

  Future<void> _saveSkills() async {
    final json = jsonEncode(_customSkills.map((e) => e.toJson()).toList());
    await MemoryService.instance.write('skills/custom_skills.json', json);
  }

  /// 使用 AI 创建技能
  Future<SkillDefinition?> createSkill({
    required String name,
    required String description,
    String? exampleTrigger,
  }) async {
    final prompt = '''你是一个技能创建器。请根据以下需求创建一个技能定义。

技能名称: $name
描述: $description
${exampleTrigger != null ? '示例触发: $exampleTrigger' : ''}

请输出 JSON 格式的技能定义:
{
  "name": "技能名称（英文）",
  "description": "技能描述",
  "category": "类别（utility/automation/ai/device）",
  "trigger": "触发条件描述",
  "action": "执行动作描述",
  "params": {"参数名": "参数说明"}
}''';

    final response = await AiService.instance.sendMessage(prompt);

    try {
      final jsonStr = response.replaceAll(RegExp(r'```json?\s*'), '').replaceAll('```', '').trim();
      final data = json.decode(jsonStr);
      final skill = SkillDefinition.fromJson(data);

      _customSkills.add(skill);
      await _saveSkills();

      return skill;
    } catch (_) {
      return null;
    }
  }

  /// 手动创建技能
  Future<void> addSkill(SkillDefinition skill) async {
    _customSkills.add(skill);
    await _saveSkills();
  }

  /// 删除技能
  Future<void> removeSkill(String name) async {
    _customSkills.removeWhere((s) => s.name == name);
    await _saveSkills();
  }

  /// 更新技能
  Future<void> updateSkill(String name, SkillDefinition updated) async {
    final index = _customSkills.indexWhere((s) => s.name == name);
    if (index >= 0) {
      _customSkills[index] = updated;
      await _saveSkills();
    }
  }

  /// 搜索技能
  List<SkillDefinition> searchSkills(String query) {
    final lowerQuery = query.toLowerCase();
    return _customSkills.where((s) =>
      s.name.toLowerCase().contains(lowerQuery) ||
      s.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  /// 按类别获取技能
  List<SkillDefinition> getSkillsByCategory(String category) {
    return _customSkills.where((s) => s.category == category).toList();
  }

  /// 导出技能为 Markdown
  Future<String> exportSkill(String name) async {
    final skill = _customSkills.firstWhere((s) => s.name == name);
    return skill.toMarkdown();
  }

  /// 从 Markdown 导入技能
  Future<SkillDefinition?> importFromMarkdown(String markdown) async {
    final prompt = '''解析以下 Markdown 格式的技能定义，输出 JSON:

$markdown

输出格式:
{"name": "...", "description": "...", "category": "...", "trigger": "...", "action": "...", "params": {...}}''';

    final response = await AiService.instance.sendMessage(prompt);

    try {
      final jsonStr = response.replaceAll(RegExp(r'```json?\s*'), '').replaceAll('```', '').trim();
      final data = json.decode(jsonStr);
      return SkillDefinition.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// 获取所有技能列表（内置 + 自定义）
  List<Map<String, dynamic>> getAllSkills() {
    final builtIn = [
      {'name': 'web_search', 'category': 'search', 'builtin': true},
      {'name': 'weather', 'category': 'utility', 'builtin': true},
      {'name': 'screenshot', 'category': 'device', 'builtin': true},
      {'name': 'notification', 'category': 'utility', 'builtin': true},
      {'name': 'file_operation', 'category': 'utility', 'builtin': true},
      {'name': 'exec_command', 'category': 'utility', 'builtin': true},
      {'name': 'memory_search', 'category': 'ai', 'builtin': true},
      {'name': 'tts', 'category': 'utility', 'builtin': true},
    ];

    final custom = _customSkills.map((s) => {
      'name': s.name,
      'category': s.category,
      'builtin': false,
      'description': s.description,
    }).toList();

    return [...builtIn, ...custom];
  }
}
