import 'dart:convert';
import '../utils/method_channel_helper.dart';
import 'ai_service.dart';

/// SQL 数据库问答服务
class SqlQaService {
  static final SqlQaService instance = SqlQaService._internal();
  SqlQaService._internal();

  final MethodChannelHelper _channel = MethodChannelHelper();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 执行 SQL 查询
  Future<Map<String, dynamic>> executeQuery(String dbPath, String sql) async {
    final result = await _channel.execCommand("sqlite3 '$dbPath' '.mode csv' '.headers on' '$sql' 2>/dev/null");

    if (result['success'] == true && (result['stdout'] as String).isNotEmpty) {
      final lines = (result['stdout'] as String).split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) return {'rows': [], 'columns': []};

      final columns = lines[0].split(',').map((c) => c.trim().replaceAll('"', '')).toList();
      final rows = <Map<String, String>>[];

      for (int i = 1; i < lines.length; i++) {
        final values = lines[i].split(',').map((v) => v.trim().replaceAll('"', '')).toList();
        final row = <String, String>{};
        for (int j = 0; j < columns.length && j < values.length; j++) {
          row[columns[j]] = values[j];
        }
        rows.add(row);
      }

      return {
        'columns': columns,
        'rows': rows,
        'count': rows.length,
      };
    }

    return {'error': result['stderr'] ?? '查询失败'};
  }

  /// 获取数据库表结构
  Future<Map<String, dynamic>> getSchema(String dbPath) async {
    final result = await _channel.execCommand(
      "sqlite3 '$dbPath' \".schema\" 2>/dev/null"
    );

    if (result['success'] == true) {
      return {'schema': result['stdout']};
    }

    return {'error': '获取 schema 失败'};
  }

  /// 列出所有表
  Future<List<String>> listTables(String dbPath) async {
    final result = await _channel.execCommand(
      "sqlite3 '$dbPath' \".tables\" 2>/dev/null"
    );

    if (result['success'] == true) {
      return (result['stdout'] as String)
          .split(RegExp(r'\s+'))
          .where((t) => t.trim().isNotEmpty)
          .toList();
    }

    return [];
  }

  /// 获取表的行数
  Future<int> getRowCount(String dbPath, String table) async {
    final result = await _channel.execCommand(
      "sqlite3 '$dbPath' \"SELECT COUNT(*) FROM $table\" 2>/dev/null"
    );

    if (result['success'] == true) {
      return int.tryParse((result['stdout'] as String).trim()) ?? 0;
    }

    return 0;
  }

  /// 基于自然语言查询数据
  Future<Map<String, dynamic>> naturalLanguageQuery(String dbPath, String question) async {
    // 获取数据库结构
    final schema = await getSchema(dbPath);
    final tables = await listTables(dbPath);

    // 获取每个表的示例数据
    final samples = <String, dynamic>{};
    for (final table in tables.take(5)) {
      final sample = await executeQuery(dbPath, "SELECT * FROM $table LIMIT 3");
      samples[table] = sample;
    }

    // 调用 AI 生成 SQL
    final prompt = '''你是一个 SQL 专家。根据数据库结构和用户问题，生成 SQL 查询。

数据库结构:
${schema['schema'] ?? '未知'}

表信息:
${tables.join(', ')}

示例数据:
${json.encode(samples)}

用户问题: $question

请输出:
1. 生成的 SQL 查询
2. 对查询结果的解释

格式:
SQL: SELECT ...
解释: ...''';

    final response = await AiService.instance.sendMessage(prompt);

    // 提取 SQL
    final sqlMatch = RegExp(r'SQL:\s*(.+?)(?:\n|$)', caseSensitive: false).firstMatch(response);
    if (sqlMatch != null) {
      final sql = sqlMatch.group(1)!.trim();
      final queryResult = await executeQuery(dbPath, sql);

      return {
        'sql': sql,
        'explanation': response,
        'result': queryResult,
      };
    }

    return {'explanation': response};
  }

  /// 数据库统计
  Future<Map<String, dynamic>> getStats(String dbPath) async {
    final tables = await listTables(dbPath);
    final stats = <String, int>{};

    for (final table in tables) {
      stats[table] = await getRowCount(dbPath, table);
    }

    // 获取数据库文件大小
    final sizeResult = await _channel.execCommand("ls -lh '$dbPath' 2>/dev/null");
    final size = (sizeResult['stdout'] as String?)?.split(' ')[4] ?? 'unknown';

    return {
      'tables': tables.length,
      'tableStats': stats,
      'fileSize': size,
    };
  }

  /// 备份数据库
  Future<bool> backup(String dbPath, String backupPath) async {
    final result = await _channel.execCommand("cp '$dbPath' '$backupPath'");
    return result['success'] ?? false;
  }
}
