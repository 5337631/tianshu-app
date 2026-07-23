/// Context 管理服务 - 4层防护
/// 1. limitHistoryTurns - 限制历史轮数
/// 2. 工具结果裁剪 - 截断过长的工具返回
/// 3. budget guard - Token 预算控制
/// 4. auto-summarization - 自动摘要
class ContextManager {
  static final ContextManager instance = ContextManager._internal();
  ContextManager._internal();

  bool _initialized = false;

  // 配置参数
  int _maxHistoryTurns = 20;
  int _maxToolResultLength = 2000;
  int _maxTokenBudget = 8000;
  bool _autoSummarize = true;

  bool get isInitialized => _initialized;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  /// 配置参数
  void configure({
    int? maxHistoryTurns,
    int? maxToolResultLength,
    int? maxTokenBudget,
    bool? autoSummarize,
  }) {
    if (maxHistoryTurns != null) _maxHistoryTurns = maxHistoryTurns;
    if (maxToolResultLength != null) _maxToolResultLength = maxToolResultLength;
    if (maxTokenBudget != null) _maxTokenBudget = maxTokenBudget;
    if (autoSummarize != null) _autoSummarize = autoSummarize;
  }

  /// 裁剪历史消息
  List<Map<String, dynamic>> trimHistory(List<Map<String, dynamic>> history) {
    if (history.length <= _maxHistoryTurns) return history;

    // 保留最近的消息
    return history.sublist(history.length - _maxHistoryTurns);
  }

  /// 裁剪工具结果
  String trimToolResult(String result) {
    if (result.length <= _maxToolResultLength) return result;

    return '${result.substring(0, _maxToolResultLength)}\n\n[结果已截断，共 ${result.length} 字符]';
  }

  /// 估算 Token 数量 (简化版)
  int estimateTokens(String text) {
    // 粗略估算：1个中文字 ≈ 2 tokens，1个英文单词 ≈ 1.3 tokens
    int tokens = 0;
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code > 0x4e00 && code < 0x9fff) {
        tokens += 2; // 中文字符
      } else if (code == 32 || code == 10) {
        tokens += 1; // 空格/换行
      } else {
        tokens += 1; // 其他字符
      }
    }
    return tokens;
  }

  /// 检查是否超出 Token 预算
  bool isOverBudget(List<Map<String, dynamic>> messages) {
    int totalTokens = 0;
    for (final msg in messages) {
      totalTokens += estimateTokens(msg['content'] ?? '');
    }
    return totalTokens > _maxTokenBudget;
  }

  /// 智能裁剪消息以适应预算
  List<Map<String, dynamic>> fitToBudget(List<Map<String, dynamic>> messages) {
    if (!isOverBudget(messages)) return messages;

    // 优先保留系统消息和最近的消息
    final result = <Map<String, dynamic>>[];
    int remaining = _maxTokenBudget;

    // 先添加系统消息
    for (final msg in messages) {
      if (msg['role'] == 'system') {
        final tokens = estimateTokens(msg['content'] ?? '');
        if (remaining >= tokens) {
          result.add(msg);
          remaining -= tokens;
        }
      }
    }

    // 然后从后往前添加消息
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (msg['role'] == 'system') continue;
      if (result.contains(msg)) continue;

      final tokens = estimateTokens(msg['content'] ?? '');
      if (remaining >= tokens) {
        result.insert(1, msg); // 插入到系统消息之后
        remaining -= tokens;
      }
    }

    return result;
  }

  /// 生成摘要 (需要 AI 服务)
  Future<String> summarize(String text) async {
    // 简化版：直接截断
    if (text.length < 500) return text;
    return '${text.substring(0, 500)}...\n[已摘要]';
  }

  /// 获取配置状态
  Map<String, dynamic> getConfig() {
    return {
      'maxHistoryTurns': _maxHistoryTurns,
      'maxToolResultLength': _maxToolResultLength,
      'maxTokenBudget': _maxTokenBudget,
      'autoSummarize': _autoSummarize,
    };
  }
}
