import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/method_channel_helper.dart';
import '../utils/tool_definitions.dart';
import 'memory_service.dart';
import 'skills_manager.dart';

/// Agent角色定义 - 使用包名引用工具集
class AgentRole {
  final String name; final String english; final String emoji;
  final String description; final String systemPrompt;
  final List<String> packages; // 引用包名而非具体工具
  final List<String> extraTools; // 额外工具（非包内）
  final double priority; final bool canCollaborate;
  const AgentRole({
    required this.name, required this.english, required this.emoji,
    required this.description, required this.systemPrompt,
    this.packages = const [], this.extraTools = const [],
    this.priority = 0.5, this.canCollaborate = true,
  });
  
  /// 获取该Agent所有可用工具
  List<Map<String, dynamic>> getTools() {
    final tools = ToolDefinitions.getToolsByPackages(packages);
    final extraToolNames = extraTools.toSet();
    if (canCollaborate) extraToolNames.add('agent_query');
    return tools.where((t) => 
      extraToolNames.contains(t['function']?['name'])
    ).toList() + tools.where((t) => 
      !extraToolNames.contains(t['function']?['name'])
    ).toList();
  }
}

class AgentInstance {
  final AgentRole role;
  final List<Map<String, dynamic>> _history = [];
  bool isBusy = false;
  AgentInstance({required this.role});
  List<Map<String, dynamic>> get history => List.unmodifiable(_history);
  void addMessage(Map<String, dynamic> msg) { _history.add(msg); while (_history.length > 60) _history.removeAt(0); }
  void clearHistory() => _history.clear();
}

class TaskAssignment {
  final String agentName; final double confidence; final String reason;
  final String? suggestedCollaboration;
  const TaskAssignment({required this.agentName, required this.confidence, required this.reason, this.suggestedCollaboration});
}

class AgentTeamService {
  static final AgentTeamService instance = AgentTeamService._internal();
  AgentTeamService._internal();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MethodChannelHelper _channel = MethodChannelHelper();
  String _apiKey = ''; String _model = 'gpt-4o-mini';
  bool _initialized = false; bool _enabled = true;
  final List<AgentRole> _roles = [];
  final Map<String, AgentInstance> _agents = {};
  bool get enabled => _enabled; bool get initialized => _initialized;
  List<AgentRole> get roles => List.unmodifiable(_roles);
  Map<String, AgentInstance> get agents => Map.unmodifiable(_agents);

  Future<void> init() async {
    if (_initialized) return;
    _apiKey = await _secureStorage.read(key: 'ai_api_key') ?? '';
    _model = await _secureStorage.read(key: 'ai_model') ?? 'gpt-4o-mini';
    _registerAgents();
    // 预加载技能
    try { await SkillsManager.instance.loadSkills(); } catch (_) {}
    _initialized = true;
  }
  void setEnabled(bool value) => _enabled = value;
  Future<void> reloadConfig() async {
    _apiKey = await _secureStorage.read(key: 'ai_api_key') ?? _apiKey;
    _model = await _secureStorage.read(key: 'ai_model') ?? _model;
  }

  void _registerAgents() {
    _roles.addAll([
      AgentRole(name: '天璇', english: 'Merak', emoji: '⭐', description: '通用对话助手', 
        packages: ['search', 'memory', 'weather'],
        extraTools: ['speak'],
        systemPrompt: '你是天璇，天枢的总管助手。负责与用户对话、协调其他Agent。遇到不擅长的领域，用agent_query向专业Agent求助。', 
        priority: 0.5),
      AgentRole(name: '天玑', english: 'Phecda', emoji: '🔍', description: '互联网搜索专家', 
        packages: ['search', 'weather'],
        systemPrompt: '你是天玑，天枢的搜索专家。用web_search搜索，web_fetch抓取网页，给用户结构化摘要并附来源。', 
        priority: 0.7),
      AgentRole(name: '天权', english: 'Megrez', emoji: '💻', description: '编程与代码专家', 
        packages: ['file', 'search'],
        extraTools: ['speak'],
        systemPrompt: '你是天权，天枢的代码专家。读写文件、执行命令、编写代码。先理解需求再给出完整代码加注释。', 
        priority: 0.8),
      AgentRole(name: '玉衡', english: 'Alioth', emoji: '📱', description: '手机设备控制专家', 
        packages: ['device', 'notification'],
        systemPrompt: '你是玉衡，天枢的设备控制专家。打开应用、点击屏幕、输入文字、截屏、读取通知、获取设备状态。', 
        priority: 0.6),
      AgentRole(name: '开阳', english: 'Mizar', emoji: '🧩', description: '推理分析专家', 
        packages: ['search', 'file'],
        systemPrompt: '你是开阳，天枢的推理分析专家。分解问题逐步推理多角度验证给出严谨结论。必要时可调用代码或搜索工具辅助分析。', 
        priority: 0.9),
      AgentRole(name: '摇光', english: 'Alkaid', emoji: '📝', description: '记忆管理专家', 
        packages: ['memory', 'file'],
        systemPrompt: '你是摇光，天枢的记忆管理专家。用search_memory搜索记忆库帮用户回忆之前的信息，用文件工具读写记忆文件。', 
        priority: 0.7),
    ]);
    for (final role in _roles) { _agents[role.name] = AgentInstance(role: role); }
  }

  Future<TaskAssignment> analyzeIntent(String userMessage, {String? context}) async {
    final m = userMessage.toLowerCase();
    // 复合意图检测 - 识别需要多Agent协作的场景
    final needSearch = m.contains(RegExp(r'搜索|查|搜|找|资讯|新闻|信息|资料|网页|网站'));
    final needCode = m.contains(RegExp(r'代码|编程|写|函数|bug|调试|运行|命令|文件|git|python|java|flutter|dart|javascript|sql|算法|脚本'));
    final needDevice = m.contains(RegExp(r'打开|启动|点击|截屏|截图|音量|亮度|通知|位置|安装|应用|app|设置|拍照|微信|抖音|闹钟|屏幕|电话|短信'));
    final needReason = m.contains(RegExp(r'为什么|分析|推理|逻辑|比较|区别|论证|证明|计算|数学|概率|因果|对比|如何|怎样|原理|本质'));
    final needMemory = m.contains(RegExp(r'记得|之前|上次|回忆|忘记|记忆|记一下|记住|说过|提到过|记录|保存|忘|想一下|想起|印象'));
    
    // 复合意图 → 分配给天璇（总管），由它协调协作
    final intentCount = [needSearch, needCode, needDevice, needReason, needMemory].where((x) => x).length;
    if (intentCount >= 2) {
      // 复合意图，天璇作为总管协调
      String collab = '';
      if (needSearch) collab += '天玑,';
      if (needCode) collab += '天权,';
      if (needDevice) collab += '玉衡,';
      if (needReason) collab += '开阳,';
      if (needMemory) collab += '摇光,';
      return TaskAssignment(agentName: '天璇', confidence: 0.9, reason: '复合意图，需协调Agent协作', suggestedCollaboration: collab);
    }
    
    if (needSearch) return const TaskAssignment(agentName: '天玑', confidence: 0.9, reason: '搜索意图');
    if (needCode) return const TaskAssignment(agentName: '天权', confidence: 0.9, reason: '代码意图');
    if (needDevice) return const TaskAssignment(agentName: '玉衡', confidence: 0.85, reason: '设备控制意图');
    if (needReason) return const TaskAssignment(agentName: '开阳', confidence: 0.8, reason: '推理分析意图');
    if (needMemory) return const TaskAssignment(agentName: '摇光', confidence: 0.85, reason: '记忆管理意图');
    
    // LLM路由
    if (await _ensureApiKey()) {
      try {
        final descs = _roles.map((r) => '- ${r.emoji} ${r.name}(${r.english}): ${r.description}').join('\n');
        final prompt = '选Agent处理消息。可用: $descs。消息: "$userMessage"。输出JSON: {"agent":"名","confidence":0-1,"reason":"理由"}';
        final resp = await http.post(Uri.parse('https://api.openai.com/v1/chat/completions'), headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'}, body: json.encode({'model': 'gpt-4o-mini', 'messages': [{'role': 'system', 'content': '路由引擎'}, {'role': 'user', 'content': prompt}], 'max_tokens': 200, 'temperature': 0.1}));
        if (resp.statusCode == 200) {
          final c = json.decode(resp.body)['choices'][0]['message']['content'] ?? '';
          final jm = RegExp(r'\{[^}]+\}').firstMatch(c);
          if (jm != null) {
            final r = json.decode(jm.group(0)!);
            final n = r['agent']?.toString() ?? '';
            if (_roles.any((a) => a.name == n)) return TaskAssignment(agentName: n, confidence: (r['confidence'] ?? 0.5).toDouble(), reason: r['reason']?.toString() ?? '');
          }
        }
      } catch (_) {}
    }
    return const TaskAssignment(agentName: '天璇', confidence: 0.5, reason: '默认通用助手');
  }

  List<Map<String, dynamic>> getToolsForAgent(String agentName) {
    final role = _roles.firstWhere((r) => r.name == agentName, orElse: () => _roles.first);
    return role.getTools();
  }

  Future<bool> _ensureApiKey() async {
    if (_apiKey.isEmpty) {
      _apiKey = await _secureStorage.read(key: 'ai_api_key') ?? '';
      _model = await _secureStorage.read(key: 'ai_model') ?? 'gpt-4o-mini';
    }
    return _apiKey.isNotEmpty;
  }

  /// 多智能体对话流
  Stream<String> chatStream(String userMessage) async* {
    if (!await _ensureApiKey()) {
      yield '请先在设置中配置AI API Key';
      return;
    }
    final assignment = await analyzeIntent(userMessage);
    final agentName = _enabled ? assignment.agentName : '天璇';
    final role = _roles.firstWhere((r) => r.name == agentName, orElse: () => _roles.first);
    yield '${role.emoji} ${role.name}(${role.english}) 已接诊 (${(assignment.confidence * 100).toInt()}%匹配)\n专注: ${role.description}\n\n';
    final agent = _agents[agentName]!;
    final tools = getToolsForAgent(agentName);
    String memCtx = '';
    try {
      final mems = await MemoryService.instance.search(userMessage, limit: 3);
      if (mems.isNotEmpty) {
        memCtx = '\n相关记忆:\n${mems.map((m) => '- ${m.content}').join('\n')}';
      }
    } catch (_) {}
    // 注入技能上下文
    String skillsCtx = '';
    try {
      skillsCtx = SkillsManager.instance.getSkillsContextForAgent(agentName);
    } catch (_) {}
    // 协作提示
    String collabHint = '';
    if (assignment.suggestedCollaboration != null) {
      collabHint = '\n\n【协作提示】用户请求涉及多个领域，需要时可调用 agent_query 向以下专家求助: ${assignment.suggestedCollaboration}';
    }
    final msgs = <Map<String, dynamic>>[
      Map.from({'role': 'system', 'content': '${role.systemPrompt}\n当前角色: ${role.emoji} ${role.name}(${role.english})\n专注: ${role.description}$memCtx$skillsCtx$collabHint'}),
      ...agent.history,
      Map.from({'role': 'user', 'content': userMessage}),
    ];
    String full = '';
    int cnt = 0;
    for (int turn = 0; turn < 5; turn++) {
      try {
        final resp = await http.post(
          Uri.parse('https://api.openai.com/v1/chat/completions'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: json.encode(Map.from({
            'model': _model,
            'messages': msgs,
            'tools': tools,
            'tool_choice': 'auto',
            'max_tokens': 4096,
          })),
        );
        if (resp.statusCode != 200) {
          yield 'API调用失败: ${resp.statusCode}';
          return;
        }
        final msg = json.decode(resp.body)['choices'][0]['message'];
        if (msg.containsKey('tool_calls')) {
          final calls = msg['tool_calls'] as List;
          if (calls.isEmpty) break;
          msgs.add(Map.from({
            'role': 'assistant',
            'content': msg['content'] ?? '',
            'tool_calls': calls,
          }));
          for (final call in calls) {
            cnt++;
            yield '第${cnt}步: 调用${call['function']['name']}...\n';
            msgs.add(Map.from({
              'role': 'tool',
              'tool_call_id': call['id'],
              'content': json.encode(await _executeTool(call)),
            }));
          }
        } else {
          final c = msg['content'] ?? '';
          full += c;
          yield c;
          break;
        }
      } catch (e) {
        yield '\n错误: $e';
        return;
      }
    }
    agent.addMessage(Map.from({'role': 'user', 'content': userMessage}));
    if (full.isNotEmpty) {
      agent.addMessage(Map.from({'role': 'assistant', 'content': full}));
    }
    if (cnt >= 5) {
      yield '\n共执行$cnt次工具调用。';
    }
  }

  /// 执行工具
  Future<Map<String, dynamic>> _executeTool(Map<String, dynamic> call) async {
    final f = call['function'];
    final name = f['name'];
    final args = _safeDecode(f['arguments']);
    try {
      switch (name) {
        // ═══════════════════════════════════════
        //  搜索工具
        // ═══════════════════════════════════════
        case 'web_search': return await _toolWebSearch(args['query'] ?? '');
        case 'web_fetch': return await _toolWebFetch(args['url'] ?? '');

        // ═══════════════════════════════════════
        //  天气工具
        // ═══════════════════════════════════════
        case 'get_weather': return await _toolGetWeather(args['city'] ?? '');

        // ═══════════════════════════════════════
        //  设备控制工具 (Playwright 模式)
        // ═══════════════════════════════════════
        case 'device': return await _toolDevice(
          action: args['action'] ?? 'snapshot',
          ref: args['ref'],
          text: args['text'],
          x: args['x'],
          y: args['y'],
          direction: args['direction'],
          key: args['key'],
          package: args['package'],
        );
        case 'take_screenshot': return await _toolTakeScreenshot();
        case 'read_notifications': return await _toolReadNotifications();
        case 'speak': return await _toolSpeak(args['text'] ?? '');
        case 'get_location': return await _toolGetLocation();
        case 'get_battery': return await _toolGetBattery();
        case 'set_alarm': return await _toolSetAlarm(args['time'] ?? '', args['label'] ?? '');
        case 'send_notification': return await _toolSendNotification(args['title'] ?? '', args['body'] ?? '');
        case 'get_screen_state': return await _toolGetScreenState();
        case 'list_apps': return await _toolListApps();
        case 'install_app': return await _toolInstallApp(args['apk_path'] ?? '');
        case 'start_activity': return await _toolStartActivity(args['component'] ?? '');
        case 'eye': return await _toolEye();
        case 'log': return await _toolLog(args['filter'] ?? '');

        // ═══════════════════════════════════════
        //  文件操作工具
        // ═══════════════════════════════════════
        case 'read_file': return await _toolReadFile(args['path'] ?? '');
        case 'write_file': return await _toolWriteFile(args['path'] ?? '', args['content'] ?? '');
        case 'edit_file': return await _toolEditFile(args['path'] ?? '', args['old_text'] ?? '', args['new_text'] ?? '');
        case 'list_files': return await _toolListFiles(args['path'] ?? '/sdcard');
        case 'exec_command': return await _toolExecCommand(args['command'] ?? '');
        case 'javascript': return await _toolJavaScript(args['code'] ?? '');
        case 'get_system_info': return await _toolGetSystemInfo();

        // ═══════════════════════════════════════
        //  记忆工具
        // ═══════════════════════════════════════
        case 'search_memory': return await _toolSearchMemory(args['query'] ?? '');
        case 'memory_get': return await _toolMemoryGet(args['key'] ?? '');

        // ═══════════════════════════════════════
        //  剪贴板工具
        // ═══════════════════════════════════════
        case 'get_clipboard': return await _toolGetClipboard();
        case 'set_clipboard': return await _toolSetClipboard(args['text'] ?? '');

        // ═══════════════════════════════════════
        //  通知工具
        // ═══════════════════════════════════════
        case 'notification_summary': return await _toolNotificationSummary();

        // ═══════════════════════════════════════
        //  Agent 协作工具
        // ═══════════════════════════════════════
        case 'agent_query': return await _toolAgentQuery(args['agent'] ?? '', args['query'] ?? '');

        // ═══════════════════════════════════════
        //  技能管理工具
        // ═══════════════════════════════════════
        case 'skills_search': return await _toolSkillsSearch(args['query'] ?? '', args['category']);
        case 'skills_install': return await _toolSkillsInstall(args['skill_id'] ?? '');
        case 'skills_update': return await _toolSkillsUpdate(args['skill_id'] ?? '');
        case 'skills_uninstall': return await _toolSkillsUninstall(args['skill_id'] ?? '');

        // ═══════════════════════════════════════
        //  配置管理工具
        // ═══════════════════════════════════════
        case 'config_get': return await _toolConfigGet(args['key'] ?? '');
        case 'config_set': return await _toolConfigSet(args['key'] ?? '', args['value'] ?? '');

        default: return Map.from({'error': '未知工具: $name'});
      }
    } catch (e) {
      return Map.from({'error': '$name失败: $e'});
    }
  }

  Map<String, dynamic> _safeDecode(String s) {
    try {
      return json.decode(s) as Map<String, dynamic>;
    } catch (_) {
      return Map<String, dynamic>();
    }
  }

  // 工具方法
  
  /// Agent间通信 - 向其他Agent发送查询
  Future<Map<String, dynamic>> _toolAgentQuery(String agentName, String query) async {
    if (!_agents.containsKey(agentName)) {
      return Map.from({'error': 'Agent $agentName 不存在，可用: ${_agents.keys.join(", ")}'});
    }
    final targetAgent = _agents[agentName]!;
    if (targetAgent.isBusy) {
      return Map.from({'error': '$agentName 正忙，稍后再试'});
    }
    targetAgent.isBusy = true;
    try {
      final role = targetAgent.role;
      final tools = role.getTools();
      final msgs = <Map<String, dynamic>>[
        Map.from({'role': 'system', 'content': '${role.systemPrompt}\n你正在被其他Agent调用。请简短回答，直接给出结果。'}),
        ...targetAgent.history,
        Map.from({'role': 'user', 'content': query}),
      ];
      final resp = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $_apiKey'},
        body: json.encode(Map.from({
          'model': _model, 'messages': msgs, 'tools': tools,
          'tool_choice': 'auto', 'max_tokens': 2048,
        })),
      );
      if (resp.statusCode == 200) {
        final msg = json.decode(resp.body)['choices'][0]['message'];
        String result = msg['content'] ?? '';
        // 处理工具调用
        if (msg.containsKey('tool_calls')) {
          for (final call in msg['tool_calls'] as List) {
            final toolResult = await _executeTool(call);
            result += '\n[${call['function']['name']}]: ${json.encode(toolResult)}';
          }
        }
        targetAgent.addMessage(Map.from({'role': 'user', 'content': query}));
        targetAgent.addMessage(Map.from({'role': 'assistant', 'content': result}));
        return Map.from({'result': result, 'agent': agentName});
      }
      return Map.from({'error': '${agentName}响应失败: ${resp.statusCode}'});
    } catch (e) {
      return Map.from({'error': '调用$agentName失败: $e'});
    } finally {
      targetAgent.isBusy = false;
    }
  }

  Future<Map<String, dynamic>> _toolWebSearch(String query) async {
    try {
      final url = 'https://html.duckduckgo.com/html/?q=${Uri.encodeComponent(query)}';
      final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36'});
      if (resp.statusCode == 200) {
        final body = resp.body;
        final results = <String>[];
        final reg = RegExp(r'<a[^>]*class="result__a"[^>]*href="(https?://[^"]+)"[^>]*>([^<]+)</a>');
        for (final m in reg.allMatches(body).take(5)) {
          final t = m.group(2)?.trim() ?? '';
          final u = m.group(1) ?? '';
          if (t.isNotEmpty && u.isNotEmpty) results.add('$t: $u');
        }
        if (results.isEmpty) {
          final sr = RegExp(r'class="result__snippet"[^>]*>([^<]+)');
          for (final m in sr.allMatches(body).take(5)) {
            final s = m.group(1)?.trim() ?? '';
            if (s.isNotEmpty) results.add(s);
          }
        }
        return Map.from({'results': results.isNotEmpty ? results.join('\n') : '未找到相关结果'});
      }
      return Map.from({'results': '搜索失败: ${resp.statusCode}'});
    } catch (e) {
      return Map.from({'error': e.toString()});
    }
  }

  Future<Map<String, dynamic>> _toolWebFetch(String url) async {
    try {
      final resp = await http.get(Uri.parse(url), headers: {'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36'});
      if (resp.statusCode == 200) {
        String c = resp.body;
        c = c.replaceAll(RegExp(r'<script[\s\S]*?</script>'), '');
        c = c.replaceAll(RegExp(r'<style[\s\S]*?</style>'), '');
        c = c.replaceAll(RegExp(r'<[^>]+>'), '');
        c = c.replaceAll(RegExp(r'\s+'), ' ').trim();
        return Map.from({'content': c.substring(0, min(5000, c.length))});
      }
      return Map.from({'error': 'HTTP ${resp.statusCode}'});
    } catch (e) {
      return Map.from({'error': e.toString()});
    }
  }

  Future<Map<String, dynamic>> _toolGetWeather(String city) async {
    try {
      final resp = await http.get(Uri.parse('https://wttr.in/${Uri.encodeComponent(city)}?format=j1'), headers: {'User-Agent': 'curl/7.64.1'});
      if (resp.statusCode == 200) {
        final d = json.decode(resp.body)['current_condition'][0];
        return Map.from({
          'city': city,
          'current': '${d['temp_C']}C',
          'desc': d['weatherDesc'][0]['value'],
          'humidity': '${d['humidity']}%',
        });
      }
      return Map.from({'error': '天气查询失败'});
    } catch (e) {
      return Map.from({'error': e.toString()});
    }
  }

  Future<Map<String, dynamic>> _toolTakeScreenshot() async {
    final r = await _channel.takeScreenshot();
    return r != null ? Map.from({'success': true, 'path': r}) : Map.from({'error': '截屏失败'});
  }

  Future<Map<String, dynamic>> _toolReadNotifications() async {
    final r = await _channel.getNotifications();
    try {
      final n = json.decode(r) as List;
      return Map.from({
        'count': n.length,
        'latest': n.take(3).map((x) => '[${x['app']}] ${x['title']}').join('\n'),
      });
    } catch (_) {
      return Map.from({'notifications': r, 'count': 0});
    }
  }

  Future<Map<String, dynamic>> _toolOpenApp(String pkg) async {
    final map = <String, String>{
      '微信': 'com.tencent.mm',
      'QQ': 'com.tencent.mobileqq',
      '支付宝': 'com.eg.android.AlipayGphone',
      '抖音': 'com.ss.android.ugc.aweme',
      '淘宝': 'com.taobao.taobao',
      '设置': 'com.android.settings',
      '相机': 'com.android.camera',
      'Chrome': 'com.android.chrome',
      '电话': 'com.android.dialer',
      '短信': 'com.android.mms',
      '高德地图': 'com.autonavi.minimap',
      '钉钉': 'com.alibaba.android.rimet',
      '飞书': 'com.ss.android.lark',
    };
    await _channel.execCommand('monkey -p ${map[pkg] ?? pkg} -c android.intent.category.LAUNCHER 1');
    return Map.from({'success': true, 'opened': pkg});
  }

  Future<Map<String, dynamic>> _toolTapScreen(int x, int y) async {
    return Map.from({'success': await _channel.performClick(x, y)});
  }

  Future<Map<String, dynamic>> _toolTypeText(String text) async {
    final e = text.replaceAll("'", "'\\''").replaceAll('\n', ' ').replaceAll('\r', '');
    final r = await _channel.execCommand("input text '$e'");
    return Map.from({'success': r['exitCode'] == 0});
  }

  Future<Map<String, dynamic>> _toolReadFile(String path) async {
    final c = await _channel.readFile(path);
    return Map.from({'content': c ?? '文件不存在'});
  }

  Future<Map<String, dynamic>> _toolWriteFile(String path, String content) async {
    final enc = base64.encode(utf8.encode(content));
    await _channel.execCommand("echo '$enc' | base64 -d > '$path'");
    return Map.from({'success': true, 'path': path, 'length': content.length});
  }

  Future<Map<String, dynamic>> _toolExecCommand(String cmd) async {
    final r = await _channel.execCommand(cmd);
    return Map.from({
      'stdout': r['stdout'] ?? '',
      'stderr': r['stderr'] ?? '',
      'exitCode': r['exitCode'] ?? -1,
    });
  }

  Future<Map<String, dynamic>> _toolSearchMemory(String query) async {
    final r = await MemoryService.instance.search(query);
    return r.isEmpty
        ? Map.from({'results': '未找到相关记忆'})
        : Map.from({'results': r.map((x) => '- ${x.content}').join('\n')});
  }

  Future<Map<String, dynamic>> _toolSpeak(String text) async {
    return Map.from({'success': await _channel.speak(text)});
  }

  Future<Map<String, dynamic>> _toolGetLocation() async {
    final r = await _channel.getLocation();
    return r != null ? Map.from({'location': r}) : Map.from({'error': '无法获取位置'});
  }

  Future<Map<String, dynamic>> _toolGetBattery() async {
    final r = await _channel.getDeviceState();
    return r != null
        ? Map.from({'level': '${r['batteryLevel'] ?? '?'}%', 'charging': r['isCharging'] ?? false})
        : Map.from({'error': '无法获取电量'});
  }

  Future<Map<String, dynamic>> _toolSetAlarm(String time, String label) async {
    final p = time.split(':');
    if (p.length != 2) return Map.from({'error': '时间格式错误'});
    await _channel.execCommand('am start -a android.intent.action.SET_ALARM --ei android.intent.extra.alarm.HOUR ${p[0]} --ei android.intent.extra.alarm.MINUTES ${p[1]} --es android.intent.extra.alarm.MESSAGE "$label"');
    return Map.from({'success': true, 'alarm': '$time $label'});
  }

  Future<Map<String, dynamic>> _toolSendNotification(String title, String body) async {
    await _channel.speak('$title. $body');
    return Map.from({'success': true, 'notification': '$title: $body'});
  }

  Future<Map<String, dynamic>> _toolListFiles(String path) async {
    final r = await _channel.execCommand('ls -la "$path"');
    return Map.from({'files': r['stdout'] ?? '无法列出', 'path': path});
  }

  Future<Map<String, dynamic>> _toolGetSystemInfo() async {
    final r = await _channel.execCommand('getprop ro.product.model');
    return Map.from({'device': (r['stdout']?.toString() ?? '').trim(), 'platform': 'Android'});
  }

  Future<Map<String, dynamic>> _toolListApps() async {
    final r = await _channel.execCommand('pm list packages -3');
    final apps = (r['stdout']?.toString() ?? '')
        .split('\n')
        .where((l) => l.isNotEmpty)
        .map((l) => l.replaceAll('package:', ''))
        .take(30)
        .join('\n');
    return Map.from({'apps': apps.isNotEmpty ? apps : '无法获取应用列表'});
  }

  Future<Map<String, dynamic>> _toolGetClipboard() async {
    final r = await _channel.pasteFromClipboard();
    return Map.from({'text': r.isEmpty ? '剪贴板为空' : r});
  }

  Future<Map<String, dynamic>> _toolSetClipboard(String text) async {
    await _channel.copyToClipboard(text);
    return Map.from({'success': true, 'text': text});
  }

  Future<Map<String, dynamic>> _toolGetScreenState() async {
    final r = await _channel.getDeviceState();
    return r != null
        ? Map.from({'screenOn': r['screenOn'] ?? 'unknown', 'resolution': '${r['screenWidth'] ?? 0}x${r['screenHeight'] ?? 0}'})
        : Map.from({'error': '无法获取屏幕状态'});
  }

  Future<Map<String, dynamic>> _toolNotificationSummary() async {
    return await _toolReadNotifications();
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
        return Map.from({'error': 'tap 需要 ref 或 x,y 坐标'});
      case 'type':
        if (ref != null && text != null) {
          return await _toolDeviceTypeByRef(ref, text);
        } else if (text != null) {
          return await _toolTypeText(text);
        }
        return Map.from({'error': 'type 需要 text'});
      case 'scroll':
        if (direction != null) {
          return await _toolDeviceScroll(direction);
        }
        return Map.from({'error': 'scroll 需要 direction'});
      case 'press':
        if (key != null) {
          return await _toolDevicePress(key);
        }
        return Map.from({'error': 'press 需要 key'});
      case 'open':
        if (package != null) {
          return await _toolOpenApp(package);
        }
        return Map.from({'error': 'open 需要 package'});
      default:
        return Map.from({'error': '未知 action: $action'});
    }
  }

  Future<Map<String, dynamic>> _toolDeviceSnapshot() async {
    final result = await _channel.playwrightSnapshot();
    if (result != null) {
      return Map.from({
        'success': true,
        'uiTree': result['uiTree'] ?? '',
        'elements': result['elements'] ?? [],
        'currentActivity': result['currentActivity'] ?? '',
      });
    }
    final hierarchy = await _channel.getUiHierarchy();
    return Map.from({
      'success': hierarchy.isNotEmpty,
      'uiTree': hierarchy,
      'elements': [],
      'note': '使用基础模式，建议开启无障碍服务获取完整UI树',
    });
  }

  Future<Map<String, dynamic>> _toolDeviceTapByRef(String ref) async {
    final success = await _channel.playwrightTapByRef(ref);
    return Map.from({'success': success, 'action': 'tap', 'ref': ref});
  }

  Future<Map<String, dynamic>> _toolDeviceTypeByRef(String ref, String text) async {
    final success = await _channel.playwrightTypeByRef(ref, text);
    return Map.from({'success': success, 'action': 'type', 'ref': ref, 'text': text});
  }

  Future<Map<String, dynamic>> _toolDeviceScroll(String direction) async {
    final success = await _channel.playwrightScroll(direction);
    return Map.from({'success': success, 'action': 'scroll', 'direction': direction});
  }

  Future<Map<String, dynamic>> _toolDevicePress(String key) async {
    final success = await _channel.playwrightPress(key);
    return Map.from({'success': success, 'action': 'press', 'key': key});
  }

  // ═══════════════════════════════════════
  //  新增 Android 工具实现
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> _toolInstallApp(String apkPath) async {
    final result = await _channel.installApk(apkPath);
    return Map.from(result);
  }

  Future<Map<String, dynamic>> _toolStartActivity(String component) async {
    final success = await _channel.startActivity(component);
    return Map.from({'success': success, 'component': component});
  }

  Future<Map<String, dynamic>> _toolEye() async {
    final result = await _channel.takePhoto();
    if (result != null) {
      return Map.from({
        'success': true,
        'path': result['path'] ?? '',
        'width': result['width'] ?? 0,
        'height': result['height'] ?? 0,
      });
    }
    return Map.from({'error': '拍照失败'});
  }

  Future<Map<String, dynamic>> _toolLog(String filter) async {
    final logs = await _channel.getLogs(filter: filter, count: 50);
    return Map.from({'logs': logs});
  }

  // ═══════════════════════════════════════
  //  文件操作工具实现
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> _toolEditFile(String path, String oldText, String newText) async {
    try {
      final content = await _channel.readFile(path);
      if (content.isEmpty) {
        return Map.from({'error': '文件不存在或为空'});
      }
      if (!content.contains(oldText)) {
        return Map.from({'error': '未找到要替换的文本'});
      }
      final newContent = content.replaceFirst(oldText, newText);
      final encoded = base64.encode(utf8.encode(newContent));
      await _channel.execCommand("echo '$encoded' | base64 -d > '$path'");
      return Map.from({'success': true, 'path': path, 'replacements': 1});
    } catch (e) {
      return Map.from({'error': e.toString()});
    }
  }

  Future<Map<String, dynamic>> _toolJavaScript(String code) async {
    final result = await _channel.executeJavaScript(code);
    return Map.from(result);
  }

  // ═══════════════════════════════════════
  //  记忆工具实现
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> _toolMemoryGet(String key) async {
    final content = await MemoryService.instance.read(key);
    if (content.isEmpty) {
      return Map.from({'error': '记忆不存在'});
    }
    return Map.from({'key': key, 'content': content});
  }

  // ═══════════════════════════════════════
  //  技能管理工具实现 (占位)
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> _toolSkillsSearch(String query, String? category) async {
    return Map.from({'skills': [], 'note': 'ClawHub 集成待实现'});
  }

  Future<Map<String, dynamic>> _toolSkillsInstall(String skillId) async {
    return Map.from({'success': false, 'note': 'ClawHub 集成待实现'});
  }

  Future<Map<String, dynamic>> _toolSkillsUpdate(String skillId) async {
    return Map.from({'success': false, 'note': 'ClawHub 集成待实现'});
  }

  Future<Map<String, dynamic>> _toolSkillsUninstall(String skillId) async {
    return Map.from({'success': false, 'note': 'ClawHub 集成待实现'});
  }

  // ═══════════════════════════════════════
  //  配置管理工具实现 (占位)
  // ═══════════════════════════════════════

  Future<Map<String, dynamic>> _toolConfigGet(String key) async {
    final value = await _channel.configGet(key);
    return Map.from({'key': key, 'value': value});
  }

  Future<Map<String, dynamic>> _toolConfigSet(String key, String value) async {
    final success = await _channel.configSet(key, value);
    return Map.from({'success': success, 'key': key});
  }

  /// 清空所有智能体的对话历史
  void clearAllHistories() {
    for (final a in _agents.values) {
      a.clearHistory();
    }
  }
}
