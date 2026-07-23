import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/method_channel_helper.dart';
import '../utils/tool_definitions.dart';
import 'memory_service.dart';

/// AI 模型提供商
enum AiProvider {
  openai,
  anthropic,
  gemini,
  mimo,
  deepseek,
  openrouter,
}

/// AI 服务 - 统一接口，自动调用工具
class AiService {
  static final AiService instance = AiService._internal();
  AiService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MethodChannelHelper _channel = MethodChannelHelper();

  AiProvider _provider = AiProvider.openai;
  String _apiKey = '';
  String _model = 'gpt-4';

  /// 当前对话历史
  final List<Map<String, dynamic>> _conversationHistory = [];

  /// 最大重试次数
  static const int _maxRetries = 3;

  /// 最大对话历史条数
  static const int _maxHistoryLength = 40;

  /// 工具定义 - 引用共享定义
  List<Map<String, dynamic>> get _tools => ToolDefinitions.allTools;

  /// 初始化
  Future<void> init() async {
    _apiKey = await _secureStorage.read(key: 'ai_api_key') ?? '';
    _model = await _secureStorage.read(key: 'ai_model') ?? 'gpt-4';
    final providerStr = await _secureStorage.read(key: 'ai_provider') ?? 'openai';
    _provider = AiProvider.values.firstWhere(
      (p) => p.name == providerStr,
      orElse: () => AiProvider.openai,
    );
  }

  /// 配置 API
  Future<void> configure({
    required AiProvider provider,
    required String apiKey,
    String? model,
    String? customEndpoint,
  }) async {
    _provider = provider;
    _apiKey = apiKey;
    if (model != null) _model = model;

    await _secureStorage.write(key: 'ai_api_key', value: apiKey);
    await _secureStorage.write(key: 'ai_model', value: _model);
    await _secureStorage.write(key: 'ai_provider', value: provider.name);

    // 保存自定义端点
    if (customEndpoint != null) {
      await _secureStorage.write(key: 'custom_endpoint_${provider.name}', value: customEndpoint);
    }
  }

  /// 发送消息并处理工具调用（支持多轮工具调用链）
  Future<String> sendMessage(String userMessage) async {
    if (_apiKey.isEmpty) {
      return '请先在设置中配置 AI API Key';
    }

    // 添加用户消息到历史
    _conversationHistory.add({'role': 'user', 'content': userMessage});

    // 裁剪历史，防止无限制增长
    _trimHistory();

    // 获取记忆上下文
    final memoryContext = await _getMemoryContext(userMessage);

    try {
      // 多轮工具调用循环（最多 10 轮防止无限循环）
      for (int turn = 0; turn < 10; turn++) {
        final response = await _callAiApiWithRetry(memoryContext);

        if (response.containsKey('tool_calls')) {
          final toolCalls = response['tool_calls'] as List;
          if (toolCalls.isEmpty) break;

          // 添加助手消息（含工具调用请求）
          _conversationHistory.add({
            'role': 'assistant',
            'content': response['content'] ?? '',
            'tool_calls': toolCalls,
          });

          // 执行所有工具
          for (final toolCall in toolCalls) {
            final result = await _executeTool(toolCall);
            _conversationHistory.add({
              'role': 'tool',
              'tool_call_id': toolCall['id'],
              'content': json.encode(result),
            });
          }
        } else {
          // AI 没有调用工具，返回文字回复
          final assistantMessage = response['content'] ?? '处理完成';
          _conversationHistory.add({'role': 'assistant', 'content': assistantMessage});
          return assistantMessage;
        }
      }

      return '工具调用次数过多，请简化请求';
    } catch (e) {
      return 'AI 调用失败: $e';
    }
  }

  /// 带重试的 AI API 调用
  Future<Map<String, dynamic>> _callAiApiWithRetry(String memoryContext) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        return await _callAiApi(memoryContext);
      } catch (e) {
        if (attempt == _maxRetries - 1) rethrow;
        await Future.delayed(Duration(seconds: 1 << attempt));
      }
    }
    throw Exception('AI API 调用失败');
  }

  /// 裁剪历史记录
  void _trimHistory() {
    while (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeAt(0);
    }
  }

  /// 发送消息并流式获取回复（SSE 流式输出）
  Stream<String> sendMessageStream(String userMessage) async* {
    if (_apiKey.isEmpty) {
      yield '请先在设置中配置 AI API Key';
      return;
    }

    _conversationHistory.add({'role': 'user', 'content': userMessage});
    _trimHistory();
    final memoryContext = await _getMemoryContext(userMessage);

    try {
      String fullContent = '';
      final systemPrompt = '你是天枢，一个智能助手。\n\n你的能力：\n- 搜索互联网信息\n- 获取天气预报\n- 读取手机通知\n- 控制手机（打开应用、点击、输入）\n- 读写文件\n- 执行命令\n- 搜索记忆\n- 语音播报\n- 获取位置和电量\n\n当用户请求某个操作时，使用合适的工具来完成。\n如果不需要工具，直接回复文字即可。\n\n$memoryContext';

      // 使用 OpenAI SSE 流式 API
      final messages = [
        {'role': 'system', 'content': systemPrompt},
        ..._conversationHistory,
      ];

      final http.Client client = http.Client();
      try {
        final request = http.Request('POST', Uri.parse('https://api.openai.com/v1/chat/completions'));
        request.headers.addAll({
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'Accept': 'text/event-stream',
        });
        request.body = json.encode({
          'model': _model,
          'messages': messages,
          'stream': true,
        'tools': _tools,
      });

        final response = await client.send(request);
        final stream = response.stream.transform(utf8.decoder);

        await for (final chunk in _parseSSEStream(stream)) {
          fullContent += chunk;
          yield chunk;
        }

        // 检查是否有工具调用
        if (fullContent.contains('[TOOL_CALL]')) {
          // 非流式模式处理工具调用
          final finalResponse = await sendMessage('');
          _conversationHistory.add({'role': 'assistant', 'content': finalResponse});
          yield '\n\n$finalResponse';
          return;
        }

        _conversationHistory.add({'role': 'assistant', 'content': fullContent});
      } finally {
        client.close();
      }
    } catch (e) {
      yield 'AI 调用失败: $e';
    }
  }

  /// 解析 SSE 流
  Stream<String> _parseSSEStream(Stream<String> rawStream) async* {
    String buffer = '';
    await for (final chunk in rawStream) {
      buffer += chunk;
      while (buffer.contains('\n')) {
        final lineEnd = buffer.indexOf('\n');
        final line = buffer.substring(0, lineEnd).trim();
        buffer = buffer.substring(lineEnd + 1);

        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') return;
          try {
            final jsonData = json.decode(data);
            final delta = jsonData['choices'][0]['delta'];
            if (delta['content'] != null) {
              yield delta['content'];
            }
          } catch (_) {}
        }
      }
    }
  }

  /// 调用 AI API
  Future<Map<String, dynamic>> _callAiApi(String memoryContext) async {
    final systemPrompt = '''你是天枢，一个智能助手。

你的能力：
- 搜索互联网信息
- 获取天气预报
- 读取手机通知
- 控制手机（打开应用、点击、输入）
- 读写文件
- 执行命令
- 搜索记忆
- 语音播报
- 获取位置和电量

当用户请求某个操作时，使用合适的工具来完成。
如果不需要工具，直接回复文字即可。

$memoryContext''';

    switch (_provider) {
      case AiProvider.openai:
        return await _callOpenAi(systemPrompt);
      case AiProvider.anthropic:
        return await _callAnthropic(systemPrompt);
      case AiProvider.gemini:
    case AiProvider.mimo:
    case AiProvider.deepseek:
    case AiProvider.openrouter:
        return await _callGemini(systemPrompt);
      case AiProvider.mimo:
      case AiProvider.deepseek:
      case AiProvider.openrouter:
        return await _callOpenAiCompatible(systemPrompt);
    }
  }

  /// OpenAI API 调用
  Future<Map<String, dynamic>> _callOpenAi(String systemPrompt) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ..._conversationHistory,
    ];

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: json.encode({
        'model': _model,
        'messages': messages,
        'tools': _tools,
        'tool_choice': 'auto',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message'];
    } else {
      throw Exception('OpenAI API error: ${response.statusCode}');
    }
  }

  /// OpenAI 兼容 API 调用 (MiMo/DeepSeek/OpenRouter)
  Future<Map<String, dynamic>> _callOpenAiCompatible(String systemPrompt) async {
    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ..._conversationHistory,
    ];

    // 获取Base URL
    String baseUrl;
    switch (_provider) {
      case AiProvider.mimo:
        baseUrl = 'https://api.xiaomi.com/v1';
        break;
      case AiProvider.deepseek:
        baseUrl = 'https://api.deepseek.com/v1';
        break;
      case AiProvider.openrouter:
        baseUrl = 'https://openrouter.ai/api/v1';
        break;
      default:
        baseUrl = 'https://api.openai.com/v1';
    }

    // 读取自定义端点
    final customEndpoint = await _secureStorage.read(key: 'custom_endpoint_${_provider.name}');
    if (customEndpoint != null && customEndpoint.isNotEmpty) {
      baseUrl = customEndpoint;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: json.encode({
        'model': _model,
        'messages': messages,
        'tools': _tools,
        'tool_choice': 'auto',
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message'];
    } else {
      throw Exception('${_provider.name} API error: ${response.statusCode}');
    }
  }

  /// Anthropic API 调用
  Future<Map<String, dynamic>> _callAnthropic(String systemPrompt) async {
    // 过滤掉 system 消息，Anthropic 的 messages 只支持 user/assistant/tool
    final filteredMessages = _conversationHistory
        .where((m) => m['role'] != 'system')
        .map((m) {
          final msg = Map<String, dynamic>.from(m);
          msg.remove('tool_calls');
          // Anthropic 用 content 数组，不用单个 content 字符串
          if (msg['role'] == 'tool') {
            return {
              'role': 'user',
              'content': [
                {
                  'type': 'tool_result',
                  'tool_use_id': msg['tool_call_id'],
                  'content': msg['content'],
                }
              ],
            };
          }
          return msg;
        }).toList();

    // 提取工具定义（Anthropic 格式）
    final anthropicTools = _tools.map((t) => t['function']).toList();

    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: json.encode({
        'model': _model,
        'max_tokens': 4096,
        'system': systemPrompt,
        'messages': filteredMessages,
        'tools': anthropicTools,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final contentBlocks = data['content'] as List;
      String? textContent;
      List<Map<String, dynamic>> toolCalls = [];

      for (final block in contentBlocks) {
        if (block['type'] == 'text') {
          textContent = block['text'];
        } else if (block['type'] == 'tool_use') {
          toolCalls.add({
            'id': block['id'],
            'function': {
              'name': block['name'],
              'arguments': json.encode(block['input']),
            },
          });
        }
      }

      if (toolCalls.isNotEmpty) {
        return {
          'content': textContent ?? '',
          'tool_calls': toolCalls,
        };
      }
      return {'content': textContent ?? ''};
    } else {
      throw Exception('Anthropic API error: ${response.statusCode}');
    }
  }

  /// Gemini API 调用
  Future<Map<String, dynamic>> _callGemini(String systemPrompt) async {
    // Gemini 使用 system_instruction + contents 分开传
    // 转换消息历史为 Gemini 格式
    final List<Map<String, dynamic>> geminiContents = [];
    for (final msg in _conversationHistory) {
      final role = msg['role'];
      if (role == 'system') continue;

      String geminiRole;
      if (role == 'assistant') {
        geminiRole = 'model';
      } else if (role == 'tool') {
        // Gemini 把 tool_result 放 user 的 functionResponse 里
        geminiContents.add({
          'role': 'user',
          'parts': [{
            'functionResponse': {
              'name': msg['tool_call_id'] ?? 'unknown',
              'response': {'result': msg['content']},
            },
          }],
        });
        continue;
      } else {
        geminiRole = 'user';
      }

      // 检查是否有工具调用
      if (msg.containsKey('tool_calls')) {
        final toolCalls = msg['tool_calls'] as List;
        final parts = <Map<String, dynamic>>[];
        if (msg['content'] != null && (msg['content'] as String).isNotEmpty) {
          parts.add({'text': msg['content']});
        }
        for (final tc in toolCalls) {
          parts.add({
            'functionCall': {
              'name': tc['function']['name'],
              'args': json.decode(tc['function']['arguments']),
            },
          });
        }
        geminiContents.add({'role': geminiRole, 'parts': parts});
      } else {
        geminiContents.add({
          'role': geminiRole,
          'parts': [{'text': msg['content'] ?? ''}],
        });
      }
    }

    // 工具定义（Gemini 格式）
    final geminiTools = [{
      'function_declarations': _tools.map((t) => t['function']).toList(),
    }];

    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'system_instruction': {
          'parts': [{'text': systemPrompt}],
        },
        'contents': geminiContents,
        'tools': geminiTools,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final candidate = data['candidates'][0];
      final parts = candidate['content']['parts'] as List;
      String? textContent;
      List<Map<String, dynamic>> toolCalls = [];

      for (final part in parts) {
        if (part.containsKey('text')) {
          textContent = part['text'];
        }
        if (part.containsKey('functionCall')) {
          toolCalls.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'function': {
              'name': part['functionCall']['name'],
              'arguments': json.encode(part['functionCall']['args']),
            },
          });
        }
      }

      if (toolCalls.isNotEmpty) {
        return {
          'content': textContent ?? '',
          'tool_calls': toolCalls,
        };
      }
      return {'content': textContent ?? ''};
    } else {
      throw Exception('Gemini API error: ${response.statusCode}');
    }
  }

  /// 执行工具调用
  Future<Map<String, dynamic>> _executeTool(Map<String, dynamic> toolCall) async {
    final function = toolCall['function'];
    final name = function['name'];
    final args = json.decode(function['arguments']);

    try {
      switch (name) {
        // ═══════════════════════════════════════
        //  搜索工具
        // ═══════════════════════════════════════
        case 'web_search':
          return await _toolWebSearch(args['query']);
        case 'web_fetch':
          return await _toolWebFetch(args['url']);

        // ═══════════════════════════════════════
        //  天气工具
        // ═══════════════════════════════════════
        case 'get_weather':
          return await _toolGetWeather(args['city']);

        // ═══════════════════════════════════════
        //  设备控制工具 (Playwright 模式)
        // ═══════════════════════════════════════
        case 'device':
          return await _toolDevice(
            action: args['action'],
            ref: args['ref'],
            text: args['text'],
            x: args['x'],
            y: args['y'],
            direction: args['direction'],
            key: args['key'],
            package: args['package'],
          );
        case 'take_screenshot':
          return await _toolTakeScreenshot();
        case 'read_notifications':
          return await _toolReadNotifications();
        case 'speak':
          return await _toolSpeak(args['text']);
        case 'get_location':
          return await _toolGetLocation();
        case 'get_battery':
          return await _toolGetBattery();
        case 'set_alarm':
          return await _toolSetAlarm(args['time'], args['label'] ?? '');
        case 'send_notification':
          return await _toolSendNotification(args['title'], args['body']);
        case 'get_screen_state':
          return await _toolGetScreenState();
        case 'list_apps':
          return await _toolListApps();
        case 'install_app':
          return await _toolInstallApp(args['apk_path']);
        case 'start_activity':
          return await _toolStartActivity(args['component']);
        case 'eye':
          return await _toolEye();
        case 'log':
          return await _toolLog(args['filter'] ?? '');

        // ═══════════════════════════════════════
        //  文件操作工具
        // ═══════════════════════════════════════
        case 'read_file':
          return await _toolReadFile(args['path']);
        case 'write_file':
          return await _toolWriteFile(args['path'], args['content']);
        case 'edit_file':
          return await _toolEditFile(args['path'], args['old_text'], args['new_text']);
        case 'list_files':
          return await _toolListFiles(args['path']);
        case 'exec_command':
          return await _toolExecCommand(args['command']);
        case 'javascript':
          return await _toolJavaScript(args['code']);
        case 'get_system_info':
          return await _toolGetSystemInfo();

        // ═══════════════════════════════════════
        //  记忆工具
        // ═══════════════════════════════════════
        case 'search_memory':
          return await _toolSearchMemory(args['query']);
        case 'memory_get':
          return await _toolMemoryGet(args['key']);

        // ═══════════════════════════════════════
        //  剪贴板工具
        // ═══════════════════════════════════════
        case 'get_clipboard':
          return await _toolGetClipboard();
        case 'set_clipboard':
          return await _toolSetClipboard(args['text']);

        // ═══════════════════════════════════════
        //  通知工具
        // ═══════════════════════════════════════
        case 'notification_summary':
          return await _toolNotificationSummary();

        // ═══════════════════════════════════════
        //  技能管理工具
        // ═══════════════════════════════════════
        case 'skills_search':
          return await _toolSkillsSearch(args['query'], args['category']);
        case 'skills_install':
          return await _toolSkillsInstall(args['skill_id']);
        case 'skills_update':
          return await _toolSkillsUpdate(args['skill_id']);
        case 'skills_uninstall':
          return await _toolSkillsUninstall(args['skill_id']);

        // ═══════════════════════════════════════
        //  配置管理工具
        // ═══════════════════════════════════════
        case 'config_get':
          return await _toolConfigGet(args['key']);
        case 'config_set':
          return await _toolConfigSet(args['key'], args['value']);

        default:
          return {'error': 'Unknown tool: $name'};
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ══════════════════════════════════════
  //  工具实现
  // ══════════════════════════════════════

  Future<Map<String, dynamic>> _toolWebSearch(String query) async {
    try {
      // 使用 DuckDuckGo HTML 搜索（无需 API Key）
      final url = 'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
      });

      if (response.statusCode == 200) {
        final body = response.body;
        final results = <String>[];

        // 提取结果：DuckDuckGo html 版使用 result__a 链接
        // 方法：找 <a rel="nofollow" class="result__a" href="...">标题</a>
        final linkRegex = RegExp(r'<a[^>]*class="result__a"[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>');
        final matches = linkRegex.allMatches(body);

        // 如果上面没匹配到，尝试更通用的模式
        if (matches.isEmpty) {
          // 找 <a class="result__a" href="...">标题</a>（无 rel）
          final linkRegex2 = RegExp(r'<a class="result__a"[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>');
          final matches2 = linkRegex2.allMatches(body);
          for (final match in matches2.take(5)) {
            final title = match.group(2)?.trim() ?? '';
            final url2 = match.group(1) ?? '';
            if (title.isNotEmpty && url2.isNotEmpty) {
              results.add('$title: $url2');
            }
          }
        } else {
          for (final match in matches.take(5)) {
            final title = match.group(2)?.trim() ?? '';
            final url2 = match.group(1) ?? '';
            if (title.isNotEmpty && url2.isNotEmpty) {
              results.add('$title: $url2');
            }
          }
        }

        // 最后的备选：提取所有链接
        if (results.isEmpty) {
          final fallbackRegex = RegExp(r'<a[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>');
          final fallbackMatches = fallbackRegex.allMatches(body);
          for (final match in fallbackMatches.take(5)) {
            final title = match.group(2)?.trim() ?? '';
            final url2 = match.group(1) ?? '';
            if (title.isNotEmpty && url2.isNotEmpty && !url2.contains('duckduckgo.com')) {
              results.add('$title: $url2');
            }
          }
        }

        if (results.isEmpty) {
          return {'results': '未找到相关结果'};
        }
        return {'results': results.join('\n')};
      }
      return {'results': '搜索失败: ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _toolWebFetch(String url) async {
    try {
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36',
      });
      if (response.statusCode == 200) {
        // 简单去除 HTML 标签
        String content = response.body;
        content = content.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>'), '');
        content = content.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), '');
        content = content.replaceAll(RegExp(r'<[^>]+>'), '');
        content = content.replaceAll(RegExp(r'\s+'), ' ').trim();
        return {'content': content.substring(0, 5000)};
      }
      return {'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _toolGetWeather(String city) async {
    try {
      // 使用 wttr.in 免费天气 API
      final url = 'https://wttr.in/${Uri.encodeComponent(city)}?format=j1';
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'curl/7.64.1',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final current = data['current_condition'][0];
        final temp = current['temp_C'];
        final feelsLike = current['FeelsLikeC'];
        final humidity = current['humidity'];
        final desc = current['weatherDesc'][0]['value'];
        final wind = current['windspeedKmph'];
        final windDir = current['winddir16Point'];

        // 获取今天的预报
        final today = data['weather'][0];
        final maxTemp = today['maxtempC'];
        final minTemp = today['mintempC'];

        return {
          'city': city,
          'current': '$temp°C (体感 $feelsLike°C)',
          'description': desc,
          'humidity': '$humidity%',
          'wind': '$wind km/h $windDir',
          'today': '$minTemp°C ~ $maxTemp°C',
        };
      }
      return {'error': '天气查询失败'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _toolTakeScreenshot() async {
    final result = await _channel.takeScreenshot();
    return result ?? {'error': '截屏失败'};
  }

  Future<Map<String, dynamic>> _toolReadNotifications() async {
    final result = await _channel.getNotifications();
    try {
      final List<dynamic> notifications = json.decode(result);
      if (notifications.isEmpty) {
        return {'notifications': '暂无通知', 'count': 0};
      }

      // 按应用分组统计
      final Map<String, int> appCounts = {};
      final List<String> summaries = [];

      for (final notif in notifications) {
        final app = notif['app'] ?? '未知';
        appCounts[app] = (appCounts[app] ?? 0) + 1;
      }

      // 生成摘要
      final sortedApps = appCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      for (final entry in sortedApps.take(5)) {
        summaries.add('${entry.key}: ${entry.value}条');
      }

      return {
        'count': notifications.length,
        'byApp': summaries.join(', '),
        'latest': notifications.take(3).map((n) =>
          '[${n['app']}] ${n['title']}: ${n['body']?.toString().substring(0, 50) ?? ''}'
        ).join('\n'),
      };
    } catch (_) {
      return {'notifications': result, 'count': 0};
    }
  }

  Future<Map<String, dynamic>> _toolOpenApp(String packageName) async {
    // 常用应用包名映射
    final appMap = {
      '微信': 'com.tencent.mm',
      'QQ': 'com.tencent.mobileqq',
      '支付宝': 'com.eg.android.AlipayGphone',
      '抖音': 'com.ss.android.ugc.aweme',
      '淘宝': 'com.taobao.taobao',
      '高德地图': 'com.autonavi.minimap',
      'Gmail': 'com.google.android.gm',
      '设置': 'com.android.settings',
      '相机': 'com.android.camera',
      '相册': 'com.android.gallery3d',
      '哔哩哔哩': 'tv.danmaku.bili',
      '微博': 'com.sina.weibo',
      '小红书': 'com.xingin.xhs',
      '知乎': 'com.zhihu.android',
      '美团': 'com.sankuai.meituan',
      '饿了么': 'me.ele',
      '钉钉': 'com.alibaba.android.rimet',
      '飞书': 'com.ss.android.lark',
      '企业微信': 'com.tencent.wework',
      'Chrome': 'com.android.chrome',
      '浏览器': 'com.android.browser',
      '电话': 'com.android.dialer',
      '短信': 'com.android.mms',
    };

    final package = appMap[packageName] ?? packageName;

    // 方案1：用 monkey 启动（自动解析主 Activity）
    final result = await _channel.execCommand(
      'monkey -p $package -c android.intent.category.LAUNCHER 1'
    );
    if (result['exitCode'] == 0) {
      return {'success': true, 'opened': packageName};
    }

    // 方案2：用 pm resolve-activity 精确查找主 Activity
    final resolveResult = await _channel.execCommand(
      'pm resolve-activity --brief $package'
    );
    final activity = resolveResult['stdout']?.toString().trim() ?? '';
    if (activity.isNotEmpty && !activity.contains('Error')) {
      await _channel.execCommand('am start -n $activity');
      return {'success': true, 'opened': packageName, 'activity': activity};
    }

    // 方案3：回退到常见 Activity 命名模式
    for (final suffix in ['/.MainActivity', '/.Main', '/.SplashActivity', '/.LauncherActivity', '/.HomeActivity']) {
      final fallbackResult = await _channel.execCommand('am start -n $package$suffix 2>/dev/null');
      if (fallbackResult['exitCode'] == 0) {
        return {'success': true, 'opened': packageName, 'activity': '$package$suffix'};
      }
    }

    return {'success': false, 'error': '无法启动 $packageName'};
  }

  Future<Map<String, dynamic>> _toolTapScreen(int x, int y) async {
    final result = await _channel.performClick(x, y);
    return {'success': result};
  }

  Future<Map<String, dynamic>> _toolTypeText(String text) async {
    // 使用 input text 命令输入文字（安全转义特殊字符）
    // 替换单引号：' -> '\''  避免 shell 解析问题
    final escaped = text
        .replaceAll("'", "'\\''")
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', ' ')
        .replaceAll('\r', '');
    final result = await _channel.execCommand("input text '$escaped'");
    return {'success': result['exitCode'] == 0};
  }

  Future<Map<String, dynamic>> _toolReadFile(String path) async {
    final content = await _channel.readFile(path);
    return {'content': content};
  }

  Future<Map<String, dynamic>> _toolWriteFile(String path, String content) async {
    // 使用 base64 编码避免 Shell 注入
    final encoded = base64.encode(utf8.encode(content));
    await _channel.execCommand("echo '$encoded' | base64 -d > '$path'");
    return {'success': true, 'path': path, 'length': content.length};
  }

  Future<Map<String, dynamic>> _toolExecCommand(String command) async {
    final result = await _channel.execCommand(command);
    return result;
  }

  Future<Map<String, dynamic>> _toolSearchMemory(String query) async {
    final results = await MemoryService.instance.search(query);
    if (results.isEmpty) {
      return {'results': '未找到相关记忆'};
    }
    return {'results': results.map((r) => '- ${r.content}').join('\n')};
  }

  Future<Map<String, dynamic>> _toolSpeak(String text) async {
    await _channel.speak(text);
    return {'success': true};
  }

  Future<Map<String, dynamic>> _toolGetLocation() async {
    final result = await _channel.getLocation();
    return result ?? {'error': '无法获取位置'};
  }

  Future<Map<String, dynamic>> _toolGetBattery() async {
    final result = await _channel.getDeviceState();
    if (result != null) {
      final level = result['batteryLevel'] ?? -1;
      final charging = result['isCharging'] ?? false;
      return {
        'level': '$level%',
        'isCharging': charging,
        'status': charging ? '充电中' : (level < 20 ? '电量低' : '正常'),
      };
    }
    return {'error': '无法获取电量'};
  }

  Future<Map<String, dynamic>> _toolSetAlarm(String time, String label) async {
    final parts = time.split(':');
    if (parts.length != 2) {
      return {'error': '时间格式错误，请使用 HH:mm 格式'};
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return {'error': '时间无效，请使用 HH:mm 格式'};
    }

    // 方案1：使用系统闹钟 Intent（带 SKIP_UI）
    final result = await _channel.execCommand(
      'am start -a android.intent.action.SET_ALARM '
      '--ei android.intent.extra.alarm.HOUR $hour '
      '--ei android.intent.extra.alarm.MINUTES $minute '
      '--es android.intent.extra.alarm.MESSAGE "$label" '
      '--ez android.intent.extra.alarm.SKIP_UI true'
    );

    // 方案2：如果 SKIP_UI 失败，打开系统闹钟设置界面让用户手动确认
    if (result['exitCode'] != 0) {
      await _channel.execCommand(
        'am start -a android.intent.action.SET_ALARM '
        '--ei android.intent.extra.alarm.HOUR $hour '
        '--ei android.intent.extra.alarm.MINUTES $minute '
        '--es android.intent.extra.alarm.MESSAGE "$label"'
      );
      return {'success': true, 'alarm': '$time $label', 'note': '已打开闹钟设置，请确认'};
    }

    return {'success': true, 'alarm': '$time $label'};
  }

  Future<Map<String, dynamic>> _toolSendNotification(String title, String body) async {
    await _channel.speak('$title. $body');
    return {'success': true, 'spoken': true};
  }

  Future<Map<String, dynamic>> _toolNotificationSummary() async {
    final result = await _channel.getNotifications();
    try {
      final List<dynamic> notifications = json.decode(result);
      if (notifications.isEmpty) return {'summary': '暂无通知'};

      // 按应用分组
      final Map<String, List<String>> grouped = {};
      for (final notif in notifications) {
        final app = notif['app'] ?? '未知';
        final title = notif['title'] ?? '';
        final body = (notif['body'] ?? '').toString();
        grouped.putIfAbsent(app, () => []).add('$title: $body');
      }

      final buffer = StringBuffer('共 ${notifications.length} 条通知\n\n');
      for (final entry in grouped.entries) {
        buffer.writeln('【${entry.key}】(${entry.value.length}条)');
        for (final item in entry.value.take(3)) {
          buffer.writeln('  · $item');
        }
        if (entry.value.length > 3) {
          buffer.writeln('  ...还有${entry.value.length - 3}条');
        }
        buffer.writeln();
      }

      return {'summary': buffer.toString()};
    } catch (_) {
      return {'summary': '解析失败'};
    }
  }

  Future<Map<String, dynamic>> _toolListApps() async {
    final result = await _channel.execCommand('pm list packages -3');
    if (result['success'] == true) {
      final lines = (result['stdout'] as String).split('\n')
          .where((l) => l.startsWith('package:'))
          .map((l) => l.replaceFirst('package:', ''))
          .toList();
      return {'apps': lines.take(20).join('\n'), 'count': lines.length};
    }
    return {'error': '获取应用列表失败'};
  }

  Future<Map<String, dynamic>> _toolGetClipboard() async {
    final text = await _channel.pasteFromClipboard();
    return {'text': text.isEmpty ? '剪贴板为空' : text};
  }

  Future<Map<String, dynamic>> _toolSetClipboard(String text) async {
    await _channel.copyToClipboard(text);
    return {'success': true};
  }

  Future<Map<String, dynamic>> _toolGetScreenState() async {
    final result = await _channel.execCommand('dumpsys display | grep mScreenState');
    return {'state': result['stdout'] ?? 'unknown'};
  }

  Future<Map<String, dynamic>> _toolListFiles(String path) async {
    final result = await _channel.execCommand('ls -la "$path" 2>/dev/null | head -20');
    return {'files': result['stdout'] ?? '目录不存在或为空'};
  }

  Future<Map<String, dynamic>> _toolGetSystemInfo() async {
    final results = await Future.wait([
      _channel.execCommand('getprop ro.build.version.release'),
      _channel.execCommand('getprop ro.product.model'),
      _channel.execCommand('getprop ro.product.brand'),
      _channel.execCommand('getprop ro.build.display.id'),
    ]);

    return {
      'androidVersion': results[0]['stdout']?.trim() ?? 'unknown',
      'model': results[1]['stdout']?.trim() ?? 'unknown',
      'brand': results[2]['stdout']?.trim() ?? 'unknown',
      'buildId': results[3]['stdout']?.trim() ?? 'unknown',
    };
  }

  // ═══════════════════════════════════════
  //  Playwright 模式工具实现
  // ═══════════════════════════════════════

  /// device 工具 - Playwright 模式统一入口
  Future<Map<String, dynamic>> _toolDevice({
    required String action,
    String? ref,
    String? text,
    int? x,
    int? y,
    String? direction,
    String? key,
    String? package,
  }) async {
    switch (action) {
      case 'snapshot':
        return await _toolDeviceSnapshot();
      case 'tap':
        if (ref != null) {
          return await _toolDeviceTapByRef(ref);
        } else if (x != null && y != null) {
          return await _toolTapScreen(x, y);
        }
        return {'error': 'tap 需要 ref 或 x,y 坐标'};
      case 'type':
        if (ref != null && text != null) {
          return await _toolDeviceTypeByRef(ref, text);
        } else if (text != null) {
          return await _toolTypeText(text);
        }
        return {'error': 'type 需要 text'};
      case 'scroll':
        if (direction != null) {
          return await _toolDeviceScroll(direction);
        }
        return {'error': 'scroll 需要 direction'};
      case 'press':
        if (key != null) {
          return await _toolDevicePress(key);
        }
        return {'error': 'press 需要 key'};
      case 'open':
        if (package != null) {
          return await _toolOpenApp(package);
        }
        return {'error': 'open 需要 package'};
      default:
        return {'error': '未知 action: $action'};
    }
  }

  /// Playwright snapshot - 获取带 ref 编号的 UI 树
  Future<Map<String, dynamic>> _toolDeviceSnapshot() async {
    final result = await _channel.playwrightSnapshot();
    if (result != null) {
      return {
        'success': true,
        'uiTree': result['uiTree'] ?? '',
        'elements': result['elements'] ?? [],
        'currentActivity': result['currentActivity'] ?? '',
      };
    }
    // 回退到基础 getUiHierarchy
    final hierarchy = await _channel.getUiHierarchy();
    return {
      'success': hierarchy.isNotEmpty,
      'uiTree': hierarchy,
      'elements': [],
      'note': '使用基础模式，建议开启无障碍服务获取完整UI树',
    };
  }

  /// Playwright tap by ref - 点击指定 ref 元素
  Future<Map<String, dynamic>> _toolDeviceTapByRef(String ref) async {
    final success = await _channel.playwrightTapByRef(ref);
    return {'success': success, 'action': 'tap', 'ref': ref};
  }

  /// Playwright type by ref - 在指定 ref 元素输入文字
  Future<Map<String, dynamic>> _toolDeviceTypeByRef(String ref, String text) async {
    final success = await _channel.playwrightTypeByRef(ref, text);
    return {'success': success, 'action': 'type', 'ref': ref, 'text': text};
  }

  /// Playwright scroll - 滚动屏幕
  Future<Map<String, dynamic>> _toolDeviceScroll(String direction) async {
    final success = await _channel.playwrightScroll(direction);
    return {'success': success, 'action': 'scroll', 'direction': direction};
  }

  /// Playwright press - 按系统按键
  Future<Map<String, dynamic>> _toolDevicePress(String key) async {
    final success = await _channel.playwrightPress(key);
    return {'success': success, 'action': 'press', 'key': key};
  }

  // ═══════════════════════════════════════
  //  新增 Android 工具实现
  // ═══════════════════════════════════════

  /// install_app - 安装 APK
  Future<Map<String, dynamic>> _toolInstallApp(String apkPath) async {
    final result = await _channel.installApk(apkPath);
    return result;
  }

  /// start_activity - 启动 Activity
  Future<Map<String, dynamic>> _toolStartActivity(String component) async {
    final success = await _channel.startActivity(component);
    return {'success': success, 'component': component};
  }

  /// eye - 摄像头拍照
  Future<Map<String, dynamic>> _toolEye() async {
    final result = await _channel.takePhoto();
    if (result != null) {
      return {
        'success': true,
        'path': result['path'] ?? '',
        'width': result['width'] ?? 0,
        'height': result['height'] ?? 0,
      };
    }
    return {'error': '拍照失败'};
  }

  /// log - 查看系统日志
  Future<Map<String, dynamic>> _toolLog(String filter) async {
    final logs = await _channel.getLogs(filter: filter, count: 50);
    return {'logs': logs};
  }

  // ═══════════════════════════════════════
  //  文件操作工具实现
  // ═══════════════════════════════════════

  /// edit_file - 精确编辑文件 (diff 模式)
  Future<Map<String, dynamic>> _toolEditFile(String path, String oldText, String newText) async {
    try {
      final content = await _channel.readFile(path);
      if (content.isEmpty) {
        return {'error': '文件不存在或为空'};
      }

      if (!content.contains(oldText)) {
        return {'error': '未找到要替换的文本'};
      }

      final newContent = content.replaceFirst(oldText, newText);
      // 使用 base64 编码避免 Shell 注入
      final encoded = base64.encode(utf8.encode(newContent));
      await _channel.execCommand("echo '$encoded' | base64 -d > '$path'");

      return {
        'success': true,
        'path': path,
        'replacements': 1,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// javascript - 执行 JavaScript 代码
  Future<Map<String, dynamic>> _toolJavaScript(String code) async {
    final result = await _channel.executeJavaScript(code);
    return result;
  }

  // ═══════════════════════════════════════
  //  记忆工具实现
  // ═══════════════════════════════════════

  /// memory_get - 精确读取记忆
  Future<Map<String, dynamic>> _toolMemoryGet(String key) async {
    final content = await MemoryService.instance.read(key);
    if (content.isEmpty) {
      return {'error': '记忆不存在'};
    }
    return {'key': key, 'content': content};
  }

  // ═══════════════════════════════════════
  //  技能管理工具实现 (占位)
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> _toolSkillsSearch(String query, String? category) async {
    // TODO: 实现 ClawHub 搜索
    return {'skills': [], 'note': 'ClawHub 集成待实现'};
  }

  Future<Map<String, dynamic>> _toolSkillsInstall(String skillId) async {
    // TODO: 实现 ClawHub 安装
    return {'success': false, 'note': 'ClawHub 集成待实现'};
  }

  Future<Map<String, dynamic>> _toolSkillsUpdate(String skillId) async {
    // TODO: 实现技能更新
    return {'success': false, 'note': 'ClawHub 集成待实现'};
  }

  Future<Map<String, dynamic>> _toolSkillsUninstall(String skillId) async {
    // TODO: 实现技能卸载
    return {'success': false, 'note': 'ClawHub 集成待实现'};
  }

  // ═══════════════════════════════════════
  //  配置管理工具实现 (占位)
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> _toolConfigGet(String key) async {
    final value = await _channel.configGet(key);
    return {'key': key, 'value': value};
  }

  Future<Map<String, dynamic>> _toolConfigSet(String key, String value) async {
    final success = await _channel.configSet(key, value);
    return {'success': success, 'key': key};
  }

  /// 获取记忆上下文
  Future<String> _getMemoryContext(String query) async {
    final results = await MemoryService.instance.search(query, limit: 3);
    if (results.isEmpty) return '';

    final context = StringBuffer('\n## 相关记忆\n');
    for (final r in results) {
      context.write('- ${r.content}\n');
    }
    return context.toString();
  }

  /// 意识蒸馏 - 专门的蒸馏接口，不走工具调用
  Future<String?> distillConsciousness(String prompt) async {
    if (_apiKey.isEmpty) return null;

    try {
      switch (_provider) {
        case AiProvider.openai:
          return await _callOpenAiForDistill(prompt);
        case AiProvider.anthropic:
          return await _callAnthropicForDistill(prompt);
        case AiProvider.gemini:
    case AiProvider.mimo:
    case AiProvider.deepseek:
    case AiProvider.openrouter:
          return await _callGeminiForDistill(prompt);
      }
    } catch (e) {
      return null;
    }
  }

  Future<String> _callOpenAiForDistill(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: json.encode({
        'model': _model,
        'messages': [
          {'role': 'system', 'content': '你是一个专业的意识蒸馏引擎，擅长从个人信息中提炼核心特征。'},
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
        'max_tokens': 1000,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'];
    }
    throw Exception('OpenAI API error');
  }

  Future<String> _callAnthropicForDistill(String prompt) async {
    final response = await http.post(
      Uri.parse('https://api.anthropic.com/v1/messages'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: json.encode({
        'model': _model,
        'max_tokens': 1000,
        'system': '你是一个专业的意识蒸馏引擎，擅长从个人信息中提炼核心特征。',
        'messages': [
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['content'][0]['text'];
    }
    throw Exception('Anthropic API error');
  }

  Future<String> _callGeminiForDistill(String prompt) async {
    final response = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'contents': [{'parts': [{'text': '你是一个专业的意识蒸馏引擎。\n\n$prompt'}]}],
        'generationConfig': {'maxOutputTokens': 1000},
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    }
    throw Exception('Gemini API error');
  }

  /// 清空对话历史
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// 获取当前配置
  Map<String, dynamic> getConfig() {
    return {
      'provider': _provider.name,
      'model': _model,
      'hasApiKey': _apiKey.isNotEmpty,
      'apiKey': _apiKey,
    };
  }
}
