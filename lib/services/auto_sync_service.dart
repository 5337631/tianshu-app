import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'memory_service.dart';

/// 同步配置
class SyncConfig {
  final bool telegramEnabled;
  final bool emailEnabled;
  final String? telegramBotToken;
  final String? telegramChatId;
  final String? emailImapServer;
  final int? emailImapPort;
  final String? emailUsername;
  final String? emailPassword;

  SyncConfig({
    this.telegramEnabled = false,
    this.emailEnabled = false,
    this.telegramBotToken,
    this.telegramChatId,
    this.emailImapServer,
    this.emailImapPort,
    this.emailUsername,
    this.emailPassword,
  });

  Map<String, dynamic> toJson() => {
    'telegramEnabled': telegramEnabled,
    'emailEnabled': emailEnabled,
    'telegramBotToken': telegramBotToken,
    'telegramChatId': telegramChatId,
    'emailImapServer': emailImapServer,
    'emailImapPort': emailImapPort,
    'emailUsername': emailUsername,
    'emailPassword': emailPassword,
  };

  factory SyncConfig.fromJson(Map<String, dynamic> json) => SyncConfig(
    telegramEnabled: json['telegramEnabled'] ?? false,
    emailEnabled: json['emailEnabled'] ?? false,
    telegramBotToken: json['telegramBotToken'],
    telegramChatId: json['telegramChatId'],
    emailImapServer: json['emailImapServer'],
    emailImapPort: json['emailImapPort'],
    emailUsername: json['emailUsername'],
    emailPassword: json['emailPassword'],
  );
}

/// 同步消息
class SyncMessage {
  final String source; // telegram, email
  final String? sender;
  final String? title;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SyncMessage({
    required this.source,
    this.sender,
    this.title,
    required this.content,
    required this.timestamp,
    this.metadata,
  });
}

/// 自动同步服务
class AutoSyncService {
  static final AutoSyncService instance = AutoSyncService._internal();
  AutoSyncService._internal();

  Timer? _telegramTimer;
  Timer? _emailTimer;
  SyncConfig _config = SyncConfig();
  bool _initialized = false;
  int _lastTelegramUpdateId = 0;

  /// 获取配置
  SyncConfig get config => _config;

  /// 初始化同步服务
  Future<void> init() async {
    if (_initialized) return;

    await _loadConfig();

    // 启动定时同步
    if (_config.telegramEnabled) {
      _startTelegramSync();
    }
    if (_config.emailEnabled) {
      _startEmailSync();
    }

    _initialized = true;
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('sync_config');
    if (configJson != null) {
      _config = SyncConfig.fromJson(json.decode(configJson));
    }
  }

  /// 保存配置
  Future<void> saveConfig(SyncConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_config', json.encode(config.toJson()));

    // 重启同步定时器
    _telegramTimer?.cancel();
    _emailTimer?.cancel();

    if (config.telegramEnabled) {
      _startTelegramSync();
    }
    if (config.emailEnabled) {
      _startEmailSync();
    }
  }

  /// 启动 Telegram 同步
  void _startTelegramSync() {
    _telegramTimer = Timer.periodic(const Duration(minutes: 5), (_) => syncTelegram());
  }

  /// 启动 Email 同步
  void _startEmailSync() {
    _emailTimer = Timer.periodic(const Duration(minutes: 60), (_) => syncEmail());
  }

  /// 同步 Telegram 消息
  Future<List<SyncMessage>> syncTelegram() async {
    if (_config.telegramBotToken == null || _config.telegramChatId == null) {
      return [];
    }

    try {
      final url = 'https://api.telegram.org/bot${_config.telegramBotToken}/getUpdates?offset=$_lastTelegramUpdateId&limit=100';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['ok'] == true) {
          final updates = data['result'] as List;
          final messages = <SyncMessage>[];

          for (final update in updates) {
            _lastTelegramUpdateId = update['update_id'] + 1;

            if (update.containsKey('message')) {
              final message = update['message'];
              messages.add(SyncMessage(
                source: 'telegram',
                sender: message['from']?['first_name'],
                content: message['text'] ?? '',
                timestamp: DateTime.fromMillisecondsSinceEpoch(message['date'] * 1000),
                metadata: {
                  'chatId': message['chat']?['id'],
                  'messageId': message['message_id'],
                },
              ));
            }
          }

          // 保存同步数据
          await _saveSyncData('telegram', messages);
          return messages;
        }
      }
    } catch (e) {
      // 静默处理错误
    }

    return [];
  }

  /// 同步 Email（框架实现，完整 IMAP 需添加 imap_client 依赖）
  Future<List<SyncMessage>> syncEmail() async {
    if (_config.emailImapServer == null || _config.emailUsername == null) {
      return [];
    }

    final messages = <SyncMessage>[];

    try {
      // Email 同步分两步：
      // 1. 添加依赖: dart pub add imap_client
      // 2. 解封以下代码:
      //
      // final client = ImapClient();
      // await client.connect(
      //   _config.emailImapServer!,
      //   _config.emailImapPort ?? 993,
      //   isSecure: true,
      // );
      // await client.login(_config.emailUsername!, _config.emailPassword!);
      // final inbox = await client.selectInbox();
      // final uids = await inbox.searchUnseen();
      // for (final uid in uids.take(20)) {
      //   final msg = await inbox.fetchMessage(uid);
      //   messages.add(SyncMessage(
      //     source: 'email',
      //     sender: msg.from?.first.address,
      //     title: msg.subject,
      //     content: msg.textBody ?? '',
      //     timestamp: msg.date ?? DateTime.now(),
      //   ));
      // }
      // await client.logout();

      // 保存同步数据
      if (messages.isNotEmpty) {
        await _saveSyncData('email', messages);
      }
    } catch (e) {
      // 静默处理错误
    }

    return messages;
  }

  /// 保存同步数据
  Future<void> _saveSyncData(String source, List<SyncMessage> messages) async {
    if (messages.isEmpty) return;

    final memory = MemoryService.instance;
    final date = DateTime.now().toIso8601String().split('T')[0];
    final path = 'sync/$source-$date.md';

    final content = StringBuffer('# $source 同步数据\n\n');
    content.write('**同步时间**: ${DateTime.now().toIso8601String()}\n\n');

    for (final msg in messages) {
      content.write('---\n\n');
      if (msg.sender != null) content.write('**发送者**: ${msg.sender}\n');
      if (msg.title != null) content.write('**标题**: ${msg.title}\n');
      content.write('**时间**: ${msg.timestamp.toIso8601String()}\n\n');
      content.write('${msg.content}\n\n');
    }

    await memory.append(path, content.toString());
  }

  /// 生成晨间简报
  Future<String> generateMorningBriefing() async {
    final memory = MemoryService.instance;
    final now = DateTime.now();
    final dateStr = now.toIso8601String().split('T')[0];

    final briefing = StringBuffer('# 晨间简报\n\n');
    briefing.write('**日期**: $dateStr\n\n');

    // 读取同步数据
    final telegramData = await memory.read('sync/telegram-$dateStr.md');
    final emailData = await memory.read('sync/email-$dateStr.md');

    if (telegramData.isNotEmpty) {
      briefing.write('## Telegram\n\n');
      briefing.write('有新消息\n\n');
    }

    if (emailData.isNotEmpty) {
      briefing.write('## Email\n\n');
      briefing.write('有新邮件\n\n');
    }

    // 读取今日待办
    final tasks = await memory.read('user/tasks.md');
    if (tasks.isNotEmpty) {
      briefing.write('## 今日待办\n\n');
      briefing.write(tasks);
    }

    return briefing.toString();
  }

  /// 手动同步所有
  Future<void> syncNow(String source) async {
    switch (source) {
      case 'telegram':
        await syncTelegram();
        break;
      case 'email':
        await syncEmail();
        break;
    }
  }

  /// 销毁
  void dispose() {
    _telegramTimer?.cancel();
    _emailTimer?.cancel();
  }
}
