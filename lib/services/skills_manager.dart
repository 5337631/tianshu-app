import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

/// 技能定义
class Skill {
  final String name;
  final String description;
  final String category;
  final String content;
  final List<String> relatedTools;

  const Skill({
    required this.name,
    required this.description,
    required this.category,
    required this.content,
    this.relatedTools = const [],
  });
}

/// 技能管理器 - 加载和管理 assets/skills/ 下的技能文件
class SkillsManager {
  static final SkillsManager instance = SkillsManager._internal();
  SkillsManager._internal();

  final List<Skill> _skills = [];
  final Map<String, Skill> _skillMap = {};

  bool _loaded = false;
  bool get loaded => _loaded;
  List<Skill> get skills => List.unmodifiable(_skills);

  /// 加载所有技能文件
  Future<void> loadSkills() async {
    if (_loaded) return;
    _skills.clear();
    _skillMap.clear();

    try {
      // 从 assets/skills/ 加载
      final manifestStr = await rootBundle.loadString('assets/skills/skill_creator.md');
      // 如果能加载到 skill_creator.md，说明目录存在，用遍历方式
      _skills.addAll(await _parseSkillFiles());
      _loaded = true;
    } catch (e) {
      print('SkillsManager: 无法从assets加载技能: $e');
    }
  }

  /// 解析所有技能文件
  Future<List<Skill>> _parseSkillFiles() async {
    final skills = <Skill>[];
    // 技能文件列表
    final skillFiles = [
      'browser', 'memory', 'device_control', 'weather', 'code_execution',
      'file_management', 'notification_summary', 'screenshot', 'tts',
      'app_management', 'auto_sync', 'background_thinking', 'channel_config',
      'clawhub', 'config', 'context_security', 'data_processing', 'debugging',
      'email', 'install_app', 'mcp', 'model_config', 'model_usage', 'pdf_qa',
      'predict', 'rag', 'session_logs', 'skill_creator', 'sql_qa', 'trigger',
      'youtube_qa',
    ];

    for (final name in skillFiles) {
      try {
        final content = await rootBundle.loadString('assets/skills/$name.md');
        final skill = _parseSkillFile(name, content);
        if (skill != null) skills.add(skill);
      } catch (_) {}
    }
    return skills;
  }

  /// 解析单个技能文件
  Skill? _parseSkillFile(String name, String content) {
    try {
      String description = '';
      String category = 'uncategorized';
      final tools = <String>[];

      // 解析 YAML frontmatter
      if (content.startsWith('---')) {
        final endIdx = content.indexOf('---', 3);
        if (endIdx != -1) {
          final yaml = content.substring(3, endIdx).trim();
          for (final line in yaml.split('\n')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final val = parts.sublist(1).join(':').trim();
              if (key == 'name') name = val;
              if (key == 'description') description = val;
              if (key == 'category') category = val;
            }
          }
          // 提取相关工具名
          final toolMatches = RegExp(r'`(\w+)`').allMatches(content);
          for (final m in toolMatches) {
            final toolName = m.group(1)!;
            if (!tools.contains(toolName)) tools.add(toolName);
          }
          // 去掉 frontmatter
          final bodyContent = content.substring(endIdx + 3).trim();
          _skillMap[name] = Skill(
            name: name,
            description: description,
            category: category,
            content: bodyContent,
            relatedTools: tools,
          );
          return _skillMap[name];
        }
      }
    } catch (_) {}
    return null;
  }

  /// 根据分类获取技能
  List<Skill> getSkillsByCategory(String category) {
    return _skills.where((s) => s.category == category).toList();
  }

  /// 根据关键词匹配技能
  List<Skill> findSkills(String query) {
    final q = query.toLowerCase();
    return _skills.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.description.toLowerCase().contains(q) ||
      s.content.toLowerCase().contains(q)
    ).toList();
  }

  /// 获取Agent可用的技能上下文
  String getSkillsContextForAgent(String agentName) {
    final agentSkills = <String>[];
    // 根据Agent名称匹配相关技能
    switch (agentName) {
      case '天玑':
        agentSkills.addAll(['browser', 'weather']);
        break;
      case '天权':
        agentSkills.addAll(['code_execution', 'file_management', 'debugging', 'sql_qa']);
        break;
      case '玉衡':
        agentSkills.addAll(['device_control', 'screenshot', 'app_management', 'notification_summary', 'tts']);
        break;
      case '开阳':
        agentSkills.addAll(['data_processing', 'predict', 'rag', 'pdf_qa']);
        break;
      case '摇光':
        agentSkills.addAll(['memory', 'session_logs', 'auto_sync']);
        break;
      default:
        agentSkills.addAll(['browser', 'memory', 'weather']);
    }

    final contexts = <String>[];
    for (final name in agentSkills) {
      final skill = _skillMap[name];
      if (skill != null) {
        contexts.add('## ${skill.name}: ${skill.description}\n${skill.content.substring(0, skill.content.length.clamp(0, 300))}');
      }
    }
    return contexts.isEmpty ? '' : '\n\n【可用技能】\n${contexts.join('\n\n')}';
  }
}
