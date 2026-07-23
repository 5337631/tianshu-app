import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 记忆系统 - 长期记忆存储与检索
class MemoryService {
  static final MemoryService instance = MemoryService._internal();
  MemoryService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Directory? _memoryDir;
  bool _initialized = false;

  /// 初始化记忆系统
  Future<void> init() async {
    if (_initialized) return;

    final appDir = await getApplicationDocumentsDirectory();
    _memoryDir = Directory('${appDir.path}/memory');

    // 创建目录结构
    await _createDirectoryStructure();
    _initialized = true;
  }

  /// 创建记忆目录结构
  Future<void> _createDirectoryStructure() async {
    final dirs = [
      'user',
      'conversations',
      'knowledge',
      'sync',
      'notes',
    ];

    for (final dir in dirs) {
      final directory = Directory('${_memoryDir!.path}/$dir');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    }

    // 创建索引文件
    final indexFile = File('${_memoryDir!.path}/index.md');
    if (!await indexFile.exists()) {
      await indexFile.writeAsString('# 记忆索引\n\n');
    }
  }

  /// 搜索记忆
  Future<List<MemoryEntry>> search(String query, {int limit = 10}) async {
    if (!_initialized || _memoryDir == null) return [];

    final results = <MemoryEntry>[];
    final queryLower = query.toLowerCase();

    // 遍历所有记忆文件
    await for (final entity in _memoryDir!.list(recursive: true)) {
      if (entity is File && entity.path.endsWith('.md')) {
        try {
          final content = await entity.readAsString();
          if (content.toLowerCase().contains(queryLower)) {
            // 提取匹配的上下文
            final lines = content.split('\n');
            for (int i = 0; i < lines.length; i++) {
              if (lines[i].toLowerCase().contains(queryLower)) {
                final start = (i - 2).clamp(0, lines.length - 1);
                final end = (i + 3).clamp(0, lines.length);
                final context = lines.sublist(start, end).join('\n');

                results.add(MemoryEntry(
                  path: entity.path.replaceAll(_memoryDir!.path, ''),
                  content: context,
                  relevance: _calculateRelevance(lines[i], query),
                ));
                break;
              }
            }
          }
        } catch (_) {}
      }
    }

    // 按相关度排序
    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results.take(limit).toList();
  }

  /// 计算相关度
  double _calculateRelevance(String line, String query) {
    final lineLower = line.toLowerCase();
    final queryLower = query.toLowerCase();

    // 完全匹配
    if (lineLower == queryLower) return 1.0;

    // 包含匹配
    int matchCount = 0;
    for (final word in queryLower.split(' ')) {
      if (word.length >= 2 && lineLower.contains(word)) {
        matchCount++;
      }
    }

    return matchCount / queryLower.split(' ').length;
  }

  /// 读取记忆文件
  Future<String> read(String path) async {
    if (!_initialized || _memoryDir == null) return '';

    final file = File('${_memoryDir!.path}/$path');
    if (await file.exists()) {
      return await file.readAsString();
    }
    return '';
  }

  /// 写入记忆文件
  Future<void> write(String path, String content) async {
    if (!_initialized || _memoryDir == null) return;

    final file = File('${_memoryDir!.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(content);
  }

  /// 追加内容到记忆文件
  Future<void> append(String path, String content) async {
    if (!_initialized || _memoryDir == null) return;

    final file = File('${_memoryDir!.path}/$path');
    await file.parent.create(recursive: true);

    final existing = await file.exists() ? await file.readAsString() : '';
    await file.writeAsString('$existing\n$content');
  }

  /// 保存对话摘要
  Future<void> saveConversation(String sessionId, String summary) async {
    final date = DateTime.now().toIso8601String().split('T')[0];
    final path = 'conversations/$date/$sessionId.md';

    final content = '''# 对话摘要

**时间**: ${DateTime.now().toIso8601String()}
**会话ID**: $sessionId

## 内容

$summary
''';

    await write(path, content);
  }

  /// 保存用户偏好
  Future<void> savePreference(String key, String value) async {
    await _secureStorage.write(key: 'pref_$key', value: value);
    await write('user/preferences.md', '''# 用户偏好

${await _getAllPreferences()}
''');
  }

  /// 读取用户偏好
  Future<String> getPreference(String key, {String defaultValue = ''}) async {
    return await _secureStorage.read(key: 'pref_$key') ?? defaultValue;
  }

  /// 获取所有偏好
  Future<String> _getAllPreferences() async {
    final all = await _secureStorage.readAll();
    final prefs = <String>[];
    for (final entry in all.entries) {
      if (entry.key.startsWith('pref_')) {
        final key = entry.key.substring(5);
        prefs.add('- **$key**: ${entry.value}');
      }
    }
    return prefs.join('\n');
  }

  /// 获取记忆目录路径
  String? get memoryPath => _memoryDir?.path;
}

/// 记忆条目
class MemoryEntry {
  final String path;
  final String content;
  final double relevance;

  MemoryEntry({
    required this.path,
    required this.content,
    required this.relevance,
  });
}
