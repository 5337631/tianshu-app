import 'dart:convert';
import 'package:intl/intl.dart';
import 'memory_service.dart';

/// 会话消息
class SessionMessage {
  final String role; // user / assistant / system
  final String content;
  final DateTime timestamp;
  final List<String>? toolCalls;

  SessionMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
    this.toolCalls,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'toolCalls': toolCalls,
  };

  factory SessionMessage.fromJson(Map<String, dynamic> json) => SessionMessage(
    role: json['role'] ?? 'user',
    content: json['content'] ?? '',
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    toolCalls: json['toolCalls'] != null ? List<String>.from(json['toolCalls']) : null,
  );
}

/// 会话日志服务
class SessionLogsService {
  static final SessionLogsService instance = SessionLogsService._internal();
  SessionLogsService._internal();

  final List<SessionMessage> _currentSession = [];
  bool _initialized = false;

  List<SessionMessage> get currentSession => List.unmodifiable(_currentSession);

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 添加消息到当前会话
  void addMessage(String role, String content, {List<String>? toolCalls}) {
    _currentSession.add(SessionMessage(
      role: role,
      content: content,
      toolCalls: toolCalls,
    ));
  }

  /// 保存当前会话
  Future<void> saveSession() async {
    if (_currentSession.isEmpty) return;

    final memory = MemoryService.instance;
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);

    final sessionData = _currentSession.map((m) => m.toJson()).toList();
    final jsonStr = json.encode(sessionData);

    // 保存到文件
    final path = 'conversations/$dateStr/${timeStr.replaceAll(':', '-')}.json';
    await memory.write(path, jsonStr);

    // 生成摘要并保存
    final summary = _generateSummary();
    await memory.saveConversation('${dateStr}_$timeStr', summary);
  }

  /// 生成会话摘要
  String _generateSummary() {
    final buffer = StringBuffer();
    buffer.writeln('## 会话摘要');
    buffer.writeln('**时间**: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('**消息数**: ${_currentSession.length}');
    buffer.writeln();

    // 提取关键内容
    final userMessages = _currentSession.where((m) => m.role == 'user').toList();
    final aiMessages = _currentSession.where((m) => m.role == 'assistant').toList();

    if (userMessages.isNotEmpty) {
      buffer.writeln('### 用户问题');
      for (final msg in userMessages.take(5)) {
        final preview = msg.content.length > 100
            ? '${msg.content.substring(0, 100)}...'
            : msg.content;
        buffer.writeln('- $preview');
      }
      buffer.writeln();
    }

    if (aiMessages.isNotEmpty) {
      buffer.writeln('### AI 回复');
      for (final msg in aiMessages.take(3)) {
        final preview = msg.content.length > 100
            ? '${msg.content.substring(0, 100)}...'
            : msg.content;
        buffer.writeln('- $preview');
      }
    }

    return buffer.toString();
  }

  /// 加载历史会话列表
  Future<List<Map<String, dynamic>>> getHistoryList() async {
    final memory = MemoryService.instance;
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];

    // 查找最近 7 天的会话
    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final content = await memory.read('conversations/$dateStr');

      if (content.isNotEmpty) {
        // 解析会话记录
        final lines = content.split('\n');
        int sessionCount = 0;

        for (final line in lines) {
          if (line.startsWith('## ')) {
            sessionCount++;
          }
        }

        if (sessionCount > 0) {
          result.add({
            'date': dateStr,
            'count': sessionCount,
          });
        }
      }
    }

    return result;
  }

  /// 搜索会话历史
  Future<List<SessionMessage>> searchHistory(String query) async {
    final memory = MemoryService.instance;
    final results = <SessionMessage>[];

    // 搜索记忆文件
    final memoryResults = await memory.search(query, limit: 10);

    // 这里简化处理，实际应该搜索会话文件
    return results;
  }

  /// 清空当前会话
  void clearCurrentSession() {
    _currentSession.clear();
  }

  /// 获取当前会话统计
  Map<String, dynamic> getStats() {
    final userCount = _currentSession.where((m) => m.role == 'user').length;
    final aiCount = _currentSession.where((m) => m.role == 'assistant').length;
    final toolCount = _currentSession.where((m) => m.toolCalls != null && m.toolCalls!.isNotEmpty).length;

    return {
      'totalMessages': _currentSession.length,
      'userMessages': userCount,
      'aiMessages': aiCount,
      'toolCalls': toolCount,
      'duration': _currentSession.isNotEmpty
          ? _currentSession.last.timestamp.difference(_currentSession.first.timestamp).inMinutes
          : 0,
    };
  }
}
