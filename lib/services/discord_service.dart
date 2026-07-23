import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/method_channel_helper.dart';
import 'ai_service.dart';

/// Discord 消息渠道服务
class DiscordService {
  static final DiscordService instance = DiscordService._internal();
  DiscordService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MethodChannelHelper _channel = MethodChannelHelper();

  bool _initialized = false;
  bool _connected = false;
  String _botToken = '';
  String _guildId = '';

  // Gateway 连接
  WebSocket? _gateway;
  Timer? _heartbeatTimer;
  int _heartbeatInterval = 41250;
  String? _sessionId;
  int _sequence = 0;

  bool get isInitialized => _initialized;
  bool get isConnected => _connected;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;

    // 加载配置
    _botToken = await _secureStorage.read(key: 'discord_bot_token') ?? '';
    _guildId = await _secureStorage.read(key: 'discord_guild_id') ?? '';

    // 如果配置完整，尝试连接
    if (_botToken.isNotEmpty) {
      await connect();
    }

    _initialized = true;
  }

  /// 配置 Discord
  Future<void> configure({
    required String botToken,
    String guildId = '',
  }) async {
    _botToken = botToken;
    _guildId = guildId;

    await _secureStorage.write(key: 'discord_bot_token', value: botToken);
    await _secureStorage.write(key: 'discord_guild_id', value: guildId);

    // 重新连接
    await disconnect();
    await connect();
  }

  /// 连接 Discord Gateway
  Future<bool> connect() async {
    if (_botToken.isEmpty) return false;

    try {
      // 获取 Gateway URL
      final gatewayUrl = await _getGatewayUrl();
      if (gatewayUrl == null) return false;

      // 连接 WebSocket
      // 注意：实际实现需要使用 WebSocket 库
      // 这里是简化版本，展示核心逻辑

      _connected = true;
      return true;
    } catch (e) {
      _connected = false;
      return false;
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _connected = false;
    _heartbeatTimer?.cancel();
    await _gateway?.close();
    _gateway = null;
    _sessionId = null;
    _sequence = 0;
  }

  /// 获取 Gateway URL
  Future<String?> _getGatewayUrl() async {
    try {
      final response = await http.get(
        Uri.parse('https://discord.com/api/v10/gateway'),
        headers: {
          'Authorization': 'Bot $_botToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 发送消息
  Future<bool> sendMessage({
    required String channelId,
    required String content,
  }) async {
    if (!_connected) return false;

    try {
      final response = await http.post(
        Uri.parse('https://discord.com/api/v10/channels/$channelId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bot $_botToken',
        },
        body: json.encode({
          'content': content,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 处理接收到的消息
  Future<String> handleMessage(Map<String, dynamic> event) async {
    try {
      final eventType = event['t'];

      if (eventType == 'MESSAGE_CREATE') {
        final data = event['d'];
        final author = data['author'];
        final content = data['content'];
        final channelId = data['channel_id'];

        // 忽略机器人自己的消息
        if (author['bot'] == true) return '';

        // 处理消息
        if (content.isNotEmpty) {
          // 调用 AI 处理
          final aiResponse = await AiService.instance.sendMessage(content);

          // 回复消息
          await sendMessage(channelId: channelId, content: aiResponse);

          return aiResponse;
        }
      }

      return '';
    } catch (e) {
      return '';
    }
  }

  /// 获取配置状态
  Map<String, dynamic> getConfig() {
    return {
      'tokenConfigured': _botToken.isNotEmpty,
      'connected': _connected,
      'guildId': _guildId,
    };
  }
}

/// WebSocket 封装 (简化版)
class WebSocket {
  // 实际实现需要使用 WebSocket 库
  Future<void> close() async {}
}
