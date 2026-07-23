import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/method_channel_helper.dart';
import 'ai_service.dart';

/// 飞书消息渠道服务
class FeishuService {
  static final FeishuService instance = FeishuService._internal();
  FeishuService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MethodChannelHelper _channel = MethodChannelHelper();

  bool _initialized = false;
  bool _connected = false;
  String _appId = '';
  String _appSecret = '';
  String _verificationToken = '';
  String _encryptKey = '';

  // WebSocket 连接
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool get isInitialized => _initialized;
  bool get isConnected => _connected;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;

    // 加载配置
    _appId = await _secureStorage.read(key: 'feishu_app_id') ?? '';
    _appSecret = await _secureStorage.read(key: 'feishu_app_secret') ?? '';
    _verificationToken = await _secureStorage.read(key: 'feishu_verification_token') ?? '';
    _encryptKey = await _secureStorage.read(key: 'feishu_encrypt_key') ?? '';

    // 如果配置完整，尝试连接
    if (_appId.isNotEmpty && _appSecret.isNotEmpty) {
      await connect();
    }

    _initialized = true;
  }

  /// 配置飞书
  Future<void> configure({
    required String appId,
    required String appSecret,
    String verificationToken = '',
    String encryptKey = '',
  }) async {
    _appId = appId;
    _appSecret = appSecret;
    _verificationToken = verificationToken;
    _encryptKey = encryptKey;

    await _secureStorage.write(key: 'feishu_app_id', value: appId);
    await _secureStorage.write(key: 'feishu_app_secret', value: appSecret);
    await _secureStorage.write(key: 'feishu_verification_token', value: verificationToken);
    await _secureStorage.write(key: 'feishu_encrypt_key', value: encryptKey);

    // 重新连接
    await disconnect();
    await connect();
  }

  /// 连接飞书
  Future<bool> connect() async {
    if (_appId.isEmpty || _appSecret.isEmpty) return false;

    try {
      // 获取 tenant_access_token
      final token = await _getTenantAccessToken();
      if (token == null) return false;

      // 启动 WebSocket 长连接
      // 注意：实际实现需要使用飞书 SDK 或 WebSocket 库
      // 这里是简化版本，展示核心逻辑

      _connected = true;
      _startHeartbeat();
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
    _reconnectTimer?.cancel();
  }

  /// 获取 tenant_access_token
  Future<String?> _getTenantAccessToken() async {
    try {
      final response = await http.post(
        Uri.parse('https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'app_id': _appId,
          'app_secret': _appSecret,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['code'] == 0) {
          return data['tenant_access_token'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      if (_connected) {
        // 发送心跳
        await _getTenantAccessToken();
      }
    });
  }

  /// 发送消息
  Future<bool> sendMessage({
    required String chatId,
    required String content,
    String msgType = 'text',
  }) async {
    if (!_connected) return false;

    try {
      final token = await _getTenantAccessToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('https://open.feishu.cn/open-apis/im/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'receive_id': chatId,
          'msg_type': msgType,
          'content': msgType == 'text' ? json.encode({'text': content}) : content,
        }),
        // 添加 receive_id_type 参数
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 处理接收到的消息
  Future<String> handleMessage(String messageContent) async {
    try {
      final data = json.decode(messageContent);
      final eventType = data['header']['event_type'];

      if (eventType == 'im.message.receive_v1') {
        final event = data['event'];
        final message = event['message'];
        final chatId = message['chat_id'];
        final content = message['content'];
        final msgType = message['message_type'];

        // 解析消息内容
        String userMessage = '';
        if (msgType == 'text') {
          final contentData = json.decode(content);
          userMessage = contentData['text'] ?? '';
        }

        if (userMessage.isNotEmpty) {
          // 调用 AI 处理
          final aiResponse = await AiService.instance.sendMessage(userMessage);

          // 回复消息
          await sendMessage(chatId: chatId, content: aiResponse);

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
      'appId': _appId.isNotEmpty ? '已配置' : '未配置',
      'connected': _connected,
    };
  }
}
