import 'dart:convert';
import '../utils/method_channel_helper.dart';
import 'ai_service.dart';

/// YouTube 视频问答服务
class YoutubeQaService {
  static final YoutubeQaService instance = YoutubeQaService._internal();
  YoutubeQaService._internal();

  final MethodChannelHelper _channel = MethodChannelHelper();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 获取视频信息
  Future<Map<String, dynamic>> getVideoInfo(String url) async {
    // 提取视频 ID
    final videoId = _extractVideoId(url);
    if (videoId == null) return {'error': '无效的 YouTube URL'};

    // 使用 yt-dlp 获取视频信息
    final result = await _channel.execCommand(
      'yt-dlp --dump-json --no-download "https://www.youtube.com/watch?v=$videoId" 2>/dev/null'
    );

    if (result['success'] == true && (result['stdout'] as String).isNotEmpty) {
      try {
        final info = json.decode(result['stdout'] as String);
        return {
          'title': info['title'] ?? '',
          'description': info['description'] ?? '',
          'duration': info['duration'] ?? 0,
          'uploader': info['uploader'] ?? '',
          'uploadDate': info['upload_date'] ?? '',
          'viewCount': info['view_count'] ?? 0,
          'likeCount': info['like_count'] ?? 0,
        };
      } catch (_) {}
    }

    return {'error': '获取视频信息失败'};
  }

  /// 获取视频字幕/转录
  Future<String> getTranscript(String url) async {
    final videoId = _extractVideoId(url);
    if (videoId == null) return '无效的 YouTube URL';

    // 尝试获取字幕
    final result = await _channel.execCommand(
      'yt-dlp --write-auto-sub --sub-lang zh,en --skip-download --sub-format vtt -o "/tmp/yt_%(id)s" "https://www.youtube.com/watch?v=$videoId" 2>/dev/null'
    );

    // 读取字幕文件
    final subResult = await _channel.execCommand(
      'cat /tmp/yt_${videoId}.vtt 2>/dev/null || cat /tmp/yt_${videoId}.en.vtt 2>/dev/null || echo ""'
    );

    if ((subResult['stdout'] as String).isNotEmpty) {
      // 清理 VTT 格式
      final cleaned = (subResult['stdout'] as String)
          .replaceAll(RegExp(r'WEBVTT\n\n\d+\n'), '')
          .replaceAll(RegExp(r'\d{2}:\d{2}:\d{2}\.\d{3} --> \d{2}:\d{2}:\d{2}\.\d{3}\n'), '')
          .replaceAll(RegExp(r'<[^>]+>'), '')
          .replaceAll(RegExp(r'\n+'), '\n')
          .trim();
      return cleaned;
    }

    return '无法获取字幕';
  }

  /// 基于视频内容问答
  Future<String> ask(String url, String question) async {
    // 获取视频信息
    final info = await getVideoInfo(url);
    final transcript = await getTranscript(url);

    final context = StringBuffer();
    if (info['title'] != null) {
      context.writeln('标题: ${info['title']}');
    }
    if (info['description'] != null) {
      context.writeln('描述: ${(info['description'] as String).substring(0, 500)}');
    }
    if (transcript.isNotEmpty && !transcript.startsWith('无法')) {
      context.writeln('\n字幕内容:\n${transcript.substring(0, 5000)}');
    }

    final prompt = '''基于以下 YouTube 视频内容回答问题。

视频信息:
$context

问题: $question''';

    final response = await AiService.instance.sendMessage(prompt);
    return response;
  }

  /// 生成视频摘要
  Future<String> summarize(String url) async {
    final info = await getVideoInfo(url);
    final transcript = await getTranscript(url);

    final context = StringBuffer();
    if (info['title'] != null) context.writeln('标题: ${info['title']}');
    if (info['uploader'] != null) context.writeln('频道: ${info['uploader']}');
    if (transcript.isNotEmpty && !transcript.startsWith('无法')) {
      context.writeln('\n内容:\n${transcript.substring(0, 5000)}');
    }

    final prompt = '''为以下 YouTube 视频生成简洁摘要（200字以内）。

视频信息:
$context''';

    final response = await AiService.instance.sendMessage(prompt);
    return response;
  }

  /// 提取视频关键点
  Future<List<String>> extractKeyPoints(String url) async {
    final transcript = await getTranscript(url);
    if (transcript.isEmpty || transcript.startsWith('无法')) {
      return ['无法获取视频内容'];
    }

    final prompt = '''从以下视频字幕中提取 5-10 个关键点，每点一行:

${transcript.substring(0, 5000)}''';

    final response = await AiService.instance.sendMessage(prompt);
    return response.split('\n').where((l) => l.trim().isNotEmpty).toList();
  }

  /// 搜索视频相关问题
  Future<List<String>> searchRelated(String url, String query) async {
    final transcript = await getTranscript(url);
    if (transcript.isEmpty || transcript.startsWith('无法')) return [];

    // 在字幕中搜索相关内容
    final lines = transcript.split('\n');
    final results = <String>[];

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].toLowerCase().contains(query.toLowerCase())) {
        final start = (i - 1).clamp(0, lines.length - 1);
        final end = (i + 2).clamp(0, lines.length);
        results.add(lines.sublist(start, end).join(' '));
      }
    }

    return results.take(5).toList();
  }

  String? _extractVideoId(String url) {
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }

    return null;
  }
}
