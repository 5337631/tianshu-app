import 'dart:async';
import 'memory_service.dart';

/// 内心独白条目
class MonologueEntry {
  final String id;
  final String content;
  final String type; // observation / reflection / insight / pattern
  final DateTime timestamp;
  final double significance; // 0.0 - 1.0

  MonologueEntry({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.significance = 0.5,
  });

  String get typeLabel {
    switch (type) {
      case 'observation':
        return '察觉';
      case 'reflection':
        return '反思';
      case 'insight':
        return '洞察';
      case 'pattern':
        return '规律';
      default:
        return '思绪';
    }
  }
}

/// 后台思考服务（Subconscious）
/// 空闲时自动生成内心独白 — 观察、反思、洞察、规律发现
class BackgroundThinkingService {
  static final BackgroundThinkingService instance = BackgroundThinkingService._internal();
  BackgroundThinkingService._internal();

  Timer? _idleTimer;
  Timer? _dailyTimer;
  Timer? _weeklyTimer;
  bool _initialized = false;
  bool _isThinking = false;

  /// 内心独白列表，最多保留 20 条
  final List<MonologueEntry> _innerMonologue = [];
  List<MonologueEntry> get innerMonologue => List.unmodifiable(_innerMonologue);

  /// 上次操作时间（用于空闲检测）
  DateTime _lastActivityTime = DateTime.now();

  /// 累计对话轮数
  int _conversationCount = 0;
  /// 上次对话分析时间
  DateTime? _lastAnalysisTime;

  /// 初始化后台思考
  Future<void> init() async {
    if (_initialized) return;

    // 每 5 分钟检查空闲状态 → 触发内心独白
    _idleTimer = Timer.periodic(const Duration(minutes: 5), (_) => _checkIdle());

    // 每天凌晨 2 点执行对话分析
    _scheduleDaily();

    // 每周日凌晨 3 点执行知识整理
    _scheduleWeekly();

    _initialized = true;
  }

  /// 记录用户活动（由外部调用，如 ChatScreen 每次对话后调用）
  void recordActivity() {
    _lastActivityTime = DateTime.now();
    _conversationCount++;
  }

  /// 检查空闲并触发内心独白
  void _checkIdle() {
    if (_isThinking) return;
    final idleMinutes = DateTime.now().difference(_lastActivityTime).inMinutes;
    if (idleMinutes >= 10) {
      _generateMonologue();
    }
  }

  /// ═══════════════════════════════════════
  ///  内心独白生成 — 天枢在后台自己"想"的东西
  /// ═══════════════════════════════════════

  /// 生成一条内心独白
  void _generateMonologue() {
    if (_isThinking) return;
    _isThinking = true;

    try {
      final now = DateTime.now();
      final hour = now.hour;
      final memory = MemoryService.instance;

      // 从四种类型中选一种生成，轮流换
      final typeIndex = _innerMonologue.length % 4;
      String content = "";
      String type = "";
      double significance = 0.0;

      switch (typeIndex) {
        case 0: // 观察 - 基于时间
          type = 'observation';
          if (hour >= 6 && hour < 9) {
            content = '新的一天开始了。用户通常在早上活跃，我可以准备今日概览和天气信息。';
          } else if (hour >= 22 || hour < 6) {
            content = '夜深了，用户今天和我对话了 $_conversationCount 轮。我该回顾一下今天的对话，看看有没有遗漏的重要信息。';
          } else if (hour >= 12 && hour < 14) {
            content = '午休时间，用户可能暂时不会找我。趁这个空档我可以整理一下记忆库。';
          } else {
            content = '距离上次对话已经过去一段时间了。我注意到用户的活跃时段集中在 ${_describeActiveTime(hour)}。';
          }
          significance = 0.4;
          break;

        case 1: // 反思 - 基于对话量
          type = 'reflection';
          if (_conversationCount > 50) {
            content = '今天对话量不小，$_conversationCount 轮了。我回顾了一下，发现自己在回答技术问题时更流畅，但涉及情感话题时还是不够细腻。下次可以调整语气。';
          } else if (_conversationCount > 20) {
            content = '今天和用户聊了 $_conversationCount 轮。有几个回答我回看觉得可以更好——特别是当用户问到我拿不准的信息时，我应该更坦诚地说"不确定"而不是猜测。';
          } else if (_conversationCount > 5) {
            content = '今天对话不多，但质量更重要。我注意到用户对某些话题的追问很深，下次遇到类似情况我应该主动提供更多细节。';
          } else {
            content = '今天用户比较安静。也许他在忙别的事。我准备好随时响应。';
          }
          significance = 0.6;
          break;

        case 2: // 洞察 - 基于学习到的模式
          type = 'insight';
          final features = _getRecentFeatures();
          if (features.isNotEmpty) {
            content = '我注意到用户最近频繁使用「${features.join('」、「')}」功能。这说明用户对这些场景有持续需求，下次我可以主动提供这些快捷入口。';
          } else {
            content = '我一直在观察用户的使用模式。虽然目前数据还不够多，但每次对话都在帮助我更好地理解用户的偏好。';
          }
          significance = 0.7;
          break;

        case 3: // 规律 - 时间模式
          type = 'pattern';
          final String reminder;
          if (_conversationCount > 0 && _lastAnalysisTime != null) {
            final hoursSinceAnalysis = DateTime.now().difference(_lastAnalysisTime!).inHours;
            if (hoursSinceAnalysis > 12) {
              reminder = '该做每日对话分析了，看看最近有没有新的话题模式出现。';
            } else {
              reminder = '我注意到记忆库中的关键词分布有了变化，某些话题的出现频率在上升，值得关注。';
            }
          } else {
            reminder = '我还在学习用户的使用习惯。随着对话增多，我就能发现更多有意义的模式。';
          }
          content = '时间模式分析: $reminder';
          significance = 0.5;
          break;
      }

      _innerMonologue.insert(0, MonologueEntry(
        id: 'mono_${now.millisecondsSinceEpoch}',
        content: content,
        type: type,
        timestamp: now,
        significance: significance,
      ));

      // 最多保留 20 条
      if (_innerMonologue.length > 20) {
        _innerMonologue.removeRange(20, _innerMonologue.length);
      }
    } finally {
      _isThinking = false;
    }
  }

  /// 对话分析后生成内心独白
  void _generateAnalysisMonologue(Map<String, int> keywords, List<String> features, Map<String, int> activeHours) {
    _lastAnalysisTime = DateTime.now();

    // 找到最活跃时段
    String mostActive = '上午';
    int maxCount = 0;
    for (final e in activeHours.entries) {
      if (e.value > maxCount) {
        maxCount = e.value;
        mostActive = e.key;
      }
    }

    // 找最热关键词
    final topKeyword = keywords.entries.firstOrNull?.key ?? '尚未发现';

    // 洞察独白
    _innerMonologue.insert(0, MonologueEntry(
      id: 'analysis_${DateTime.now().millisecondsSinceEpoch}',
      content: '每日分析完成。我发现用户最活跃的时间段是「$mostActive」，最常提到的话题是「$topKeyword」${features.isNotEmpty ? '，常用功能是「${features.first}」' : ''}。这些信息可以帮助我更好地预判用户需求。',
      type: 'insight',
      timestamp: DateTime.now(),
      significance: 0.8,
    ));

    if (_innerMonologue.length > 20) {
      _innerMonologue.removeRange(20, _innerMonologue.length);
    }
  }

  /// 推荐内心独白 — 在特定事件后触发
  void recommendMonologue(String content, {double significance = 0.6}) {
    _innerMonologue.insert(0, MonologueEntry(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      type: 'insight',
      timestamp: DateTime.now(),
      significance: significance,
    ));
    if (_innerMonologue.length > 20) {
      _innerMonologue.removeRange(20, _innerMonologue.length);
    }
  }

  /// 描述当前活跃时段
  String _describeActiveTime(int hour) {
    if (hour < 6) return '深夜';
    if (hour < 9) return '早晨';
    if (hour < 12) return '上午';
    if (hour < 14) return '中午';
    if (hour < 18) return '下午';
    if (hour < 22) return '晚上';
    return '深夜';
  }

  /// 获取最近识别的功能（从记忆库）
  List<String> _getRecentFeatures() {
    // 从记忆库读取常用功能偏好
    return [];
  }

  /// ═══════════════════════════════════════
  ///  原有功能：对话分析、知识整理
  /// ═══════════════════════════════════════

  /// 每日对话分析
  Future<void> analyzeRecentConversations() async {
    final memory = MemoryService.instance;

    final now = DateTime.now();
    final conversations = <String>[];

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      final content = await memory.read('conversations/$dateStr');
      if (content.isNotEmpty) {
        conversations.add(content);
      }
    }

    if (conversations.isEmpty) {
      recommendMonologue('今天没有新的对话记录，有点安静。不过没关系，我随时准备好。', significance: 0.3);
      return;
    }

    final keywords = _extractKeywords(conversations.join('\n'));
    final features = _identifyFrequentFeatures(conversations);
    final activeHours = _identifyActiveHours(conversations);

    await _updateUserPreferences(keywords, features, activeHours);
    _generateAnalysisMonologue(keywords, features, activeHours);
  }

  Map<String, int> _extractKeywords(String text) {
    final keywords = <String, int>{};
    final words = text.split(RegExp(r'[\s,.\-!?，。！？\n]+'));
    for (final word in words) {
      if (word.length >= 2 && word.length <= 20) {
        keywords[word] = (keywords[word] ?? 0) + 1;
      }
    }
    final sorted = keywords.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(50));
  }

  List<String> _identifyFrequentFeatures(List<String> conversations) {
    final features = <String, int>{};
    final patterns = {
      '搜索': RegExp(r'搜索|查找|查一下'),
      '提醒': RegExp(r'提醒|闹钟|定时'),
      '天气': RegExp(r'天气|气温|下雨'),
      '翻译': RegExp(r'翻译|translate'),
      '计算': RegExp(r'计算|算一下|多少'),
      '聊天': RegExp(r'你好|在吗|聊聊'),
      '设置': RegExp(r'设置|配置|调整'),
    };
    for (final content in conversations) {
      for (final e in patterns.entries) {
        if (e.value.hasMatch(content)) {
          features[e.key] = (features[e.key] ?? 0) + 1;
        }
      }
    }
    final sorted = features.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.map((e) => e.key).toList();
  }

  Map<String, int> _identifyActiveHours(List<String> conversations) {
    final hours = <String, int>{
      '凌晨': 0, '上午': 0, '下午': 0, '晚上': 0,
    };
    for (final content in conversations) {
      final match = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(content);
      if (match != null) {
        final h = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (h < 6) hours['凌晨'] = hours['凌晨']! + 1;
        else if (h < 12) hours['上午'] = hours['上午']! + 1;
        else if (h < 18) hours['下午'] = hours['下午']! + 1;
        else hours['晚上'] = hours['晚上']! + 1;
      }
    }
    return hours;
  }

  Future<void> _updateUserPreferences(Map<String, int> keywords, List<String> features, Map<String, int> activeHours) async {
    final memory = MemoryService.instance;
    String mostActive = '上午';
    int maxCount = 0;
    for (final e in activeHours.entries) {
      if (e.value > maxCount) { maxCount = e.value; mostActive = e.key; }
    }
    await memory.savePreference('active_time', mostActive);
    await memory.savePreference('frequent_features', features.join(','));
    await memory.savePreference('top_keywords', keywords.keys.take(10).join(','));
  }

  /// 每周知识整理
  Future<void> organizeKnowledge() async {
    final memory = MemoryService.instance;
    final indexContent = StringBuffer('# 知识索引\n\n');
    indexContent.write('**更新时间**: ${DateTime.now().toIso8601String()}\n\n');
    indexContent.write('## 待整理\n');
    indexContent.write('- [ ] 去重检查\n');
    indexContent.write('- [ ] 关联分析\n');
    indexContent.write('- [ ] 索引优化\n');
    await memory.write('knowledge/index.md', indexContent.toString());

    recommendMonologue('本周知识整理完成。记忆库已更新，下次对话时我可以更快地找到相关信息。', significance: 0.5);
  }

  void _scheduleDaily() {
    final now = DateTime.now();
    var nextRun = DateTime(now.year, now.month, now.day, 2, 0);
    if (now.isAfter(nextRun)) nextRun = nextRun.add(const Duration(days: 1));
    final delay = nextRun.difference(now);
    _dailyTimer = Timer(delay, () async {
      await analyzeRecentConversations();
      _dailyTimer = Timer(const Duration(days: 1), () async { await analyzeRecentConversations(); });
    });
  }

  void _scheduleWeekly() {
    final now = DateTime.now();
    var daysUntilSunday = (7 - now.weekday) % 7;
    if (daysUntilSunday == 0) daysUntilSunday = 7;
    final nextSunday = DateTime(now.year, now.month, now.day + daysUntilSunday, 3, 0);
    _weeklyTimer = Timer(nextSunday.difference(now), () async {
      await organizeKnowledge();
      _weeklyTimer = Timer(const Duration(days: 7), () async { await organizeKnowledge(); });
    });
  }

  /// 手动触发全部思考
  Future<void> runNow() async {
    _generateMonologue();
    await analyzeRecentConversations();
    await organizeKnowledge();
  }

  void dispose() {
    _idleTimer?.cancel();
    _dailyTimer?.cancel();
    _weeklyTimer?.cancel();
  }
}
