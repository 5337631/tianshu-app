import 'dart:convert';
import '../utils/method_channel_helper.dart';
import 'ai_service.dart';

/// PDF 文档问答服务
class PdfQaService {
  static final PdfQaService instance = PdfQaService._internal();
  PdfQaService._internal();

  final MethodChannelHelper _channel = MethodChannelHelper();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 读取 PDF 文本内容
  Future<String> extractText(String pdfPath) async {
    // 使用 pdftotext 命令提取文本（需要安装 poppler-utils）
    final result = await _channel.execCommand('pdftotext "$pdfPath" - 2>/dev/null');
    if (result['success'] == true && (result['stdout'] as String).isNotEmpty) {
      return result['stdout'];
    }

    // 备用方案：尝试使用 strings 命令
    final fallback = await _channel.execCommand('strings "$pdfPath" | head -500');
    return fallback['stdout'] ?? '无法提取 PDF 文本';
  }

  /// 获取 PDF 元数据
  Future<Map<String, dynamic>> getMetadata(String pdfPath) async {
    final result = await _channel.execCommand('pdfinfo "$pdfPath" 2>/dev/null');
    final info = <String, String>{};

    if (result['success'] == true) {
      final lines = (result['stdout'] as String).split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          info[parts[0].trim()] = parts.sublist(1).join(':').trim();
        }
      }
    }

    return {
      'title': info['Title'] ?? '',
      'author': info['Author'] ?? '',
      'pages': info['Pages'] ?? 'unknown',
      'fileSize': info['File size'] ?? '',
      'creationDate': info['CreationDate'] ?? '',
    };
  }

  /// 基于 PDF 内容问答
  Future<String> ask(String pdfPath, String question) async {
    // 提取 PDF 文本
    final text = await extractText(pdfPath);
    if (text.isEmpty || text.startsWith('无法')) {
      return '无法读取 PDF 内容';
    }

    // 截取前 8000 字符（避免超出上下文）
    final context = text.length > 8000 ? text.substring(0, 8000) : text;

    // 调用 AI 回答
    final prompt = '''基于以下 PDF 文档内容回答问题。

文档内容:
$context

问题: $question

请基于文档内容回答，如果文档中没有相关信息，请说明。''';

    final response = await AiService.instance.sendMessage(prompt);
    return response;
  }

  /// 生成 PDF 摘要
  Future<String> summarize(String pdfPath) async {
    final text = await extractText(pdfPath);
    if (text.isEmpty || text.startsWith('无法')) {
      return '无法读取 PDF 内容';
    }

    final context = text.length > 8000 ? text.substring(0, 8000) : text;

    final prompt = '''请为以下 PDF 文档生成简洁摘要（200字以内）。

文档内容:
$context''';

    final response = await AiService.instance.sendMessage(prompt);
    return response;
  }

  /// 提取 PDF 关键信息
  Future<Map<String, dynamic>> extractKeyInfo(String pdfPath) async {
    final text = await extractText(pdfPath);
    if (text.isEmpty || text.startsWith('无法')) {
      return {'error': '无法读取 PDF'};
    }

    final context = text.length > 5000 ? text.substring(0, 5000) : text;

    final prompt = '''从以下文档中提取关键信息，输出 JSON 格式：

文档内容:
$context

输出格式:
{
  "title": "文档标题",
  "topics": ["主题1", "主题2"],
  "keyPoints": ["要点1", "要点2", "要点3"],
  "entities": ["人名/组织/地点"],
  "dates": ["相关日期"]
}''';

    final response = await AiService.instance.sendMessage(prompt);

    try {
      // 尝试解析 JSON
      final jsonStr = response.replaceAll(RegExp(r'```json?\s*'), '').replaceAll('```', '').trim();
      return json.decode(jsonStr);
    } catch (_) {
      return {'raw': response};
    }
  }

  /// 搜索 PDF 内容
  Future<List<String>> search(String pdfPath, String query) async {
    final text = await extractText(pdfPath);
    if (text.isEmpty) return [];

    final lines = text.split('\n');
    final results = <String>[];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query.toLowerCase())) {
        // 获取上下文（前后各一行）
        final start = (i - 1).clamp(0, lines.length - 1);
        final end = (i + 2).clamp(0, lines.length);
        final context = lines.sublist(start, end).join('\n');
        results.add(context);
      }
    }

    return results.take(10).toList();
  }
}
