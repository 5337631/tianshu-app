import 'dart:convert';
import '../utils/method_channel_helper.dart';

/// 数据处理服务
class DataProcessingService {
  static final DataProcessingService instance = DataProcessingService._internal();
  DataProcessingService._internal();

  final MethodChannelHelper _channel = MethodChannelHelper();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 解析 CSV
  Future<Map<String, dynamic>> parseCsv(String filePath) async {
    final content = await _channel.readFile(filePath);
    if (content.isEmpty) return {'error': '文件为空'};

    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return {'error': '无有效数据'};

    final headers = lines[0].split(',').map((h) => h.trim()).toList();
    final rows = <Map<String, String>>[];

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',').map((v) => v.trim()).toList();
      final row = <String, String>{};
      for (int j = 0; j < headers.length && j < values.length; j++) {
        row[headers[j]] = values[j];
      }
      rows.add(row);
    }

    return {
      'headers': headers,
      'rows': rows,
      'rowCount': rows.length,
    };
  }

  /// 解析 JSON
  Future<Map<String, dynamic>> parseJson(String content) async {
    try {
      final data = json.decode(content);
      if (data is List) {
        return {
          'type': 'array',
          'count': data.length,
          'data': data.take(100).toList(),
        };
      } else if (data is Map) {
        return {
          'type': 'object',
          'keys': data.keys.toList(),
          'data': data,
        };
      }
      return {'error': '未知格式'};
    } catch (e) {
      return {'error': 'JSON 解析失败: $e'};
    }
  }

  /// 数据统计
  Future<Map<String, dynamic>> analyzeData(List<double> numbers) async {
    if (numbers.isEmpty) return {'error': '无数据'};

    numbers.sort();
    final sum = numbers.reduce((a, b) => a + b);
    final avg = sum / numbers.length;
    final median = numbers.length % 2 == 0
        ? (numbers[numbers.length ~/ 2 - 1] + numbers[numbers.length ~/ 2]) / 2
        : numbers[numbers.length ~/ 2];

    final variance = numbers.map((n) => (n - avg) * (n - avg)).reduce((a, b) => a + b) / numbers.length;

    return {
      'count': numbers.length,
      'sum': sum,
      'average': avg,
      'median': median,
      'min': numbers.first,
      'max': numbers.last,
      'stdDev': variance > 0 ? _sqrt(variance) : 0,
    };
  }

  double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  /// 文本处理 - 分词统计
  Future<Map<String, dynamic>> analyzeText(String text) async {
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final chars = text.length;
    final lines = text.split('\n').length;

    // 词频统计
    final wordCount = <String, int>{};
    for (final word in words) {
      final lower = word.toLowerCase();
      wordCount[lower] = (wordCount[lower] ?? 0) + 1;
    }

    // 排序
    final sorted = wordCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'characters': chars,
      'words': words.length,
      'lines': lines,
      'topWords': sorted.take(10).map((e) => '${e.key}: ${e.value}').toList(),
    };
  }

  /// 数据转换 - JSON 转 CSV
  Future<String> jsonToCsv(List<Map<String, dynamic>> data) async {
    if (data.isEmpty) return '';

    final headers = data.first.keys.toList();
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));

    for (final row in data) {
      final values = headers.map((h) {
        final value = row[h]?.toString() ?? '';
        return value.contains(',') ? '"$value"' : value;
      }).toList();
      buffer.writeln(values.join(','));
    }

    return buffer.toString();
  }

  /// 数据过滤
  Future<List<Map<String, dynamic>>> filterData(
    List<Map<String, dynamic>> data,
    String field,
    String operator,
    String value,
  ) async {
    return data.where((row) {
      final fieldValue = row[field]?.toString() ?? '';
      switch (operator) {
        case 'equals':
          return fieldValue == value;
        case 'contains':
          return fieldValue.contains(value);
        case 'startsWith':
          return fieldValue.startsWith(value);
        case 'endsWith':
          return fieldValue.endsWith(value);
        case 'gt':
          return double.tryParse(fieldValue) != null &&
              double.tryParse(value) != null &&
              double.parse(fieldValue) > double.parse(value);
        case 'lt':
          return double.tryParse(fieldValue) != null &&
              double.tryParse(value) != null &&
              double.parse(fieldValue) < double.parse(value);
        default:
          return true;
      }
    }).toList();
  }

  /// 数据排序
  Future<List<Map<String, dynamic>>> sortData(
    List<Map<String, dynamic>> data,
    String field, {
    bool ascending = true,
  }) async {
    final sorted = List<Map<String, dynamic>>.from(data);
    sorted.sort((a, b) {
      final aVal = a[field]?.toString() ?? '';
      final bVal = b[field]?.toString() ?? '';

      // 尝试数字比较
      final aNum = double.tryParse(aVal);
      final bNum = double.tryParse(bVal);

      if (aNum != null && bNum != null) {
        return ascending ? aNum.compareTo(bNum) : bNum.compareTo(aNum);
      }

      return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });
    return sorted;
  }
}
