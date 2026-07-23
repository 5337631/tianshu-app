import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/method_channel_helper.dart';

/// 录制的操作帧
class RecordedFrame {
  final int timestamp;
  final String action; // tap, type, scroll, press, snapshot
  final Map<String, dynamic> params;
  final String? uiSnapshot; // 操作前的 UI 树快照

  RecordedFrame({
    required this.timestamp,
    required this.action,
    required this.params,
    this.uiSnapshot,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp,
    'action': action,
    'params': params,
    'uiSnapshot': uiSnapshot,
  };

  factory RecordedFrame.fromJson(Map<String, dynamic> json) => RecordedFrame(
    timestamp: json['timestamp'] ?? 0,
    action: json['action'] ?? '',
    params: json['params'] ?? {},
    uiSnapshot: json['uiSnapshot'],
  );
}

/// Skill Recorder 服务 - 录制用户操作生成 Skill
class SkillRecorderService {
  static final SkillRecorderService instance = SkillRecorderService._internal();
  SkillRecorderService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MethodChannelHelper _channel = MethodChannelHelper();

  bool _initialized = false;
  bool _isRecording = false;
  List<RecordedFrame> _frames = [];
  String _currentSkillName = '';
  String _currentSkillDescription = '';
  Timer? _snapshotTimer;

  bool get isInitialized => _initialized;
  bool get isRecording => _isRecording;
  List<RecordedFrame> get frames => List.unmodifiable(_frames);

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 开始录制
  Future<void> startRecording({
    required String skillName,
    required String skillDescription,
  }) async {
    if (_isRecording) return;

    _isRecording = true;
    _frames.clear();
    _currentSkillName = skillName;
    _currentSkillDescription = skillDescription;

    // 获取初始 UI 快照
    await _takeSnapshot();

    // 启动定期快照 (每 2 秒)
    _snapshotTimer = Timer.periodic(Duration(seconds: 2), (_) async {
      if (_isRecording) {
        await _takeSnapshot();
      }
    });
  }

  /// 停止录制
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    _isRecording = false;
    _snapshotTimer?.cancel();

    // 获取最终 UI 快照
    await _takeSnapshot();
  }

  /// 记录操作
  Future<void> recordAction({
    required String action,
    required Map<String, dynamic> params,
  }) async {
    if (!_isRecording) return;

    // 获取操作前的 UI 快照
    String? uiSnapshot;
    try {
      final snapshot = await _channel.playwrightSnapshot();
      if (snapshot != null) {
        uiSnapshot = json.encode(snapshot);
      }
    } catch (_) {}

    _frames.add(RecordedFrame(
      timestamp: DateTime.now().millisecondsSinceEpoch,
      action: action,
      params: params,
      uiSnapshot: uiSnapshot,
    ));
  }

  /// 获取 UI 快照
  Future<void> _takeSnapshot() async {
    if (!_isRecording) return;

    try {
      final snapshot = await _channel.playwrightSnapshot();
      if (snapshot != null) {
        _frames.add(RecordedFrame(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          action: 'snapshot',
          params: {},
          uiSnapshot: json.encode(snapshot),
        ));
      }
    } catch (_) {}
  }

  /// 生成 Skill Markdown
  String generateSkillMarkdown() {
    if (_frames.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('name: $_currentSkillName');
    buffer.writeln('description: $_currentSkillDescription');
    buffer.writeln('category: recorded');
    buffer.writeln('platform: android');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# $_currentSkillName');
    buffer.writeln();
    buffer.writeln('## 操作步骤');
    buffer.writeln();

    int step = 1;
    for (final frame in _frames) {
      if (frame.action == 'snapshot') continue;

      buffer.write('$step. ');
      switch (frame.action) {
        case 'tap':
          if (frame.params['ref'] != null) {
            buffer.writeln('点击元素 ${frame.params['ref']}');
          } else if (frame.params['x'] != null && frame.params['y'] != null) {
            buffer.writeln('点击位置 (${frame.params['x']}, ${frame.params['y']})');
          }
          break;
        case 'type':
          buffer.writeln('输入文字 "${frame.params['text'] ?? ''}"');
          break;
        case 'scroll':
          buffer.writeln('滚动屏幕 ${frame.params['direction'] ?? 'down'}');
          break;
        case 'press':
          buffer.writeln('按下按键 ${frame.params['key'] ?? ''}');
          break;
        case 'open':
          buffer.writeln('打开应用 ${frame.params['package'] ?? ''}');
          break;
        default:
          buffer.writeln('执行操作 ${frame.action}');
      }
      step++;
    }

    buffer.writeln();
    buffer.writeln('## 注意事项');
    buffer.writeln('- 操作间隔建议 300-500ms');
    buffer.writeln('- 某些应用可能有反自动化机制');

    return buffer.toString();
  }

  /// 保存录制的 Skill
  Future<bool> saveSkill() async {
    if (_frames.isEmpty) return false;

    try {
      final markdown = generateSkillMarkdown();
      if (markdown.isEmpty) return false;

      // 保存到本地文件
      // 实际实现需要使用 path_provider 获取正确的路径
      // 这里简化处理
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清除录制数据
  void clearRecording() {
    _frames.clear();
    _currentSkillName = '';
    _currentSkillDescription = '';
  }

  /// 获取录制状态
  Map<String, dynamic> getStatus() {
    return {
      'isRecording': _isRecording,
      'frameCount': _frames.length,
      'skillName': _currentSkillName,
      'skillDescription': _currentSkillDescription,
    };
  }
}
