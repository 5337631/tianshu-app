import 'package:flutter/services.dart';
import 'dart:convert';

/// 技能定义
class SkillDefinition {
  final String name;
  final String description;
  final String category;
  final String platform;
  final String content;

  SkillDefinition({
    required this.name,
    required this.description,
    required this.category,
    required this.platform,
    required this.content,
  });

  factory SkillDefinition.fromMarkdown(String markdown) {
    final lines = markdown.split('\n');
    String name = '', description = '', category = '', platform = '';
    int contentStart = 0;

    // 解析 frontmatter
    if (lines.first.trim() == '---') {
      for (int i = 1; i < lines.length; i++) {
        if (lines[i].trim() == '---') {
          contentStart = i + 1;
          break;
        }
        final parts = lines[i].split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          switch (key) {
            case 'name': name = value; break;
            case 'description': description = value; break;
            case 'category': category = value; break;
            case 'platform': platform = value; break;
          }
        }
      }
    }

    final content = lines.sublist(contentStart).join('\n').trim();

    return SkillDefinition(
      name: name,
      description: description,
      category: category,
      platform: platform,
      content: content,
    );
  }
}

/// 技能加载器 - 从 assets/skills/ 加载 markdown 定义
class SkillLoader {
  static final SkillLoader instance = SkillLoader._internal();
  SkillLoader._internal();

  final Map<String, SkillDefinition> _skills = {};
  bool _loaded = false;

  /// 所有可用技能名
  static const List<String> availableSkills = [
    'app_management', 'auto_sync', 'background_thinking', 'browser',
    'channel_config', 'clawhub', 'code_execution', 'config',
    'context_security', 'data_processing', 'debugging', 'device_control',
    'email', 'file_management', 'install_app', 'mcp', 'memory',
    'model_config', 'model_usage', 'notification_summary', 'pdf_qa',
    'predict', 'rag', 'screenshot', 'session_logs', 'skill_creator',
    'sql_qa', 'trigger', 'tts', 'weather', 'youtube_qa',
  ];

  /// 加载所有技能
  Future<void> loadAll() async {
    if (_loaded) return;

    for (final skillName in availableSkills) {
      try {
        final content = await rootBundle.loadString('assets/skills/$skillName.md');
        _skills[skillName] = SkillDefinition.fromMarkdown(content);
      } catch (e) {
        // 技能文件不存在，跳过
      }
    }

    _loaded = true;
  }

  /// 获取指定技能
  SkillDefinition? getSkill(String name) {
    return _skills[name];
  }

  /// 获取所有技能
  Map<String, SkillDefinition> getAllSkills() {
    return Map.from(_skills);
  }

  /// 按分类获取技能
  List<SkillDefinition> getSkillsByCategory(String category) {
    return _skills.values.where((s) => s.category == category).toList();
  }

  /// 搜索技能（按名称或描述）
  List<SkillDefinition> searchSkills(String query) {
    final lowerQuery = query.toLowerCase();
    return _skills.values.where((s) =>
      s.name.toLowerCase().contains(lowerQuery) ||
      s.description.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
