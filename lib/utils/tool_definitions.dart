/// 工具包定义 - 按功能分组
class ToolPackage {
  final String name;
  final String description;
  final List<String> toolNames;
  const ToolPackage({required this.name, required this.description, required this.toolNames});
}

/// 共享工具定义 - 天枢所有工具统一注册
/// 修改此文件后，ai_service 和 agent_team_service 自动生效
class ToolDefinitions {
  /// 所有工具包
  static const List<ToolPackage> packages = [
    ToolPackage(name: 'search', description: '互联网搜索', toolNames: ['web_search', 'web_fetch']),
    ToolPackage(name: 'weather', description: '天气查询', toolNames: ['get_weather']),
    ToolPackage(name: 'device', description: '设备控制 (Playwright)', toolNames: [
      'device', 'take_screenshot', 'read_notifications', 'get_location', 'get_battery',
      'set_alarm', 'send_notification', 'get_screen_state', 'list_apps', 'speak',
      'install_app', 'start_activity', 'eye', 'log',
    ]),
    ToolPackage(name: 'file', description: '文件操作', toolNames: [
      'read_file', 'write_file', 'edit_file', 'list_files', 'exec_command',
      'get_system_info', 'javascript',
    ]),
    ToolPackage(name: 'memory', description: '记忆管理', toolNames: ['search_memory', 'memory_get']),
    ToolPackage(name: 'clipboard', description: '剪贴板', toolNames: ['get_clipboard', 'set_clipboard']),
    ToolPackage(name: 'notification', description: '通知摘要', toolNames: ['notification_summary']),
    ToolPackage(name: 'agent', description: 'Agent协作', toolNames: ['agent_query']),
    ToolPackage(name: 'skills', description: '技能管理', toolNames: ['skills_search', 'skills_install', 'skills_update', 'skills_uninstall']),
    ToolPackage(name: 'config', description: '配置管理', toolNames: ['config_get', 'config_set']),
  ];

  /// 根据包名获取工具列表
  static List<Map<String, dynamic>> getToolsByPackage(String packageName) {
    final pkg = packages.firstWhere((p) => p.name == packageName, orElse: () => packages.first);
    return allTools.where((t) => pkg.toolNames.contains(t['function']?['name'])).toList();
  }

  /// 根据多个包名获取工具列表
  static List<Map<String, dynamic>> getToolsByPackages(List<String> packageNames) {
    final names = <String>{};
    for (final pn in packageNames) {
      final pkg = packages.where((p) => p.name == pn);
      for (final p in pkg) {
        names.addAll(p.toolNames);
      }
    }
    return allTools.where((t) => names.contains(t['function']?['name'])).toList();
  }

  static List<Map<String, dynamic>> get allTools => [
    // ═══════════════════════════════════════
    //  搜索工具
    // ═══════════════════════════════════════
    _tool('web_search', '搜索互联网信息', {
      'query': {'type': 'string', 'description': '搜索关键词'},
    }, required: ['query']),
    _tool('web_fetch', '抓取网页内容', {
      'url': {'type': 'string', 'description': '网页URL'},
    }, required: ['url']),

    // ═══════════════════════════════════════
    //  天气工具
    // ═══════════════════════════════════════
    _tool('get_weather', '获取天气信息', {
      'city': {'type': 'string', 'description': '城市名'},
    }, required: ['city']),

    // ═══════════════════════════════════════
    //  设备控制工具 (Playwright 模式)
    // ═══════════════════════════════════════
    _tool('device', '屏幕操作 (Playwright模式)', {
      'action': {
        'type': 'string',
        'enum': ['snapshot', 'tap', 'type', 'scroll', 'press', 'open'],
        'description': '操作类型: snapshot=获取UI树, tap=点击, type=输入, scroll=滚动, press=按键, open=打开应用',
      },
      'ref': {'type': 'string', 'description': '元素ref编号 (snapshot返回)'},
      'text': {'type': 'string', 'description': '输入文字或搜索文本'},
      'x': {'type': 'integer', 'description': 'X坐标 (tap操作)'},
      'y': {'type': 'integer', 'description': 'Y坐标 (tap操作)'},
      'direction': {
        'type': 'string',
        'enum': ['up', 'down', 'left', 'right'],
        'description': '滚动方向',
      },
      'key': {
        'type': 'string',
        'enum': ['back', 'home', 'recent', 'enter'],
        'description': '按键类型',
      },
      'package': {'type': 'string', 'description': '应用包名 (open操作)'},
    }, required: ['action']),

    _tool('take_screenshot', '截取手机屏幕', {}),
    _tool('read_notifications', '读取通知栏消息', {}),
    _tool('speak', '语音播报文字', {
      'text': {'type': 'string', 'description': '要播报的文字'},
    }, required: ['text']),
    _tool('get_location', '获取当前位置', {}),
    _tool('get_battery', '获取电量信息', {}),
    _tool('set_alarm', '设置闹钟', {
      'time': {'type': 'string', 'description': '时间HH:mm'},
      'label': {'type': 'string', 'description': '闹钟标签'},
    }, required: ['time']),
    _tool('send_notification', '发送通知', {
      'title': {'type': 'string', 'description': '通知标题'},
      'body': {'type': 'string', 'description': '通知内容'},
    }, required: ['title', 'body']),
    _tool('get_screen_state', '获取屏幕状态', {}),
    _tool('list_apps', '列出已安装应用', {}),

    // 新增 Android 工具
    _tool('install_app', '安装APK', {
      'apk_path': {'type': 'string', 'description': 'APK文件路径'},
    }, required: ['apk_path']),
    _tool('start_activity', '启动Activity', {
      'component': {'type': 'string', 'description': '组件名 (如 com.example/.MainActivity)'},
    }, required: ['component']),
    _tool('eye', '摄像头拍照', {}),
    _tool('log', '查看系统日志', {
      'filter': {'type': 'string', 'description': '过滤关键词'},
    }),

    // ═══════════════════════════════════════
    //  文件操作工具
    // ═══════════════════════════════════════
    _tool('read_file', '读取文件内容', {
      'path': {'type': 'string', 'description': '文件路径'},
    }, required: ['path']),
    _tool('write_file', '写入文件内容', {
      'path': {'type': 'string', 'description': '文件路径'},
      'content': {'type': 'string', 'description': '文件内容'},
    }, required: ['path', 'content']),
    _tool('edit_file', '精确编辑文件 (diff模式)', {
      'path': {'type': 'string', 'description': '文件路径'},
      'old_text': {'type': 'string', 'description': '要替换的原文'},
      'new_text': {'type': 'string', 'description': '替换为的新文'},
    }, required: ['path', 'old_text', 'new_text']),
    _tool('list_files', '列出目录文件', {
      'path': {'type': 'string', 'description': '目录路径'},
    }, required: ['path']),
    _tool('exec_command', '执行shell命令', {
      'command': {'type': 'string', 'description': '命令'},
    }, required: ['command']),
    _tool('javascript', '执行JavaScript代码', {
      'code': {'type': 'string', 'description': 'JS代码'},
    }, required: ['code']),
    _tool('get_system_info', '获取系统信息', {}),

    // ═══════════════════════════════════════
    //  记忆工具
    // ═══════════════════════════════════════
    _tool('search_memory', '搜索记忆库', {
      'query': {'type': 'string', 'description': '搜索关键词'},
    }, required: ['query']),
    _tool('memory_get', '精确读取记忆', {
      'key': {'type': 'string', 'description': '记忆键'},
    }, required: ['key']),

    // ═══════════════════════════════════════
    //  剪贴板工具
    // ═══════════════════════════════════════
    _tool('get_clipboard', '获取剪贴板内容', {}),
    _tool('set_clipboard', '设置剪贴板内容', {
      'text': {'type': 'string', 'description': '要复制的文字'},
    }, required: ['text']),

    // ═══════════════════════════════════════
    //  通知工具
    // ═══════════════════════════════════════
    _tool('notification_summary', '生成通知摘要', {}),

    // ═══════════════════════════════════════
    //  Agent 协作工具
    // ═══════════════════════════════════════
    _tool('agent_query', '向其他Agent发送查询', {
      'agent': {'type': 'string', 'description': '目标Agent名称：天璇/天玑/天权/玉衡/开阳/摇光'},
      'query': {'type': 'string', 'description': '查询内容'},
    }, required: ['agent', 'query']),

    // ═══════════════════════════════════════
    //  技能管理工具
    // ═══════════════════════════════════════
    _tool('skills_search', '搜索ClawHub技能', {
      'query': {'type': 'string', 'description': '搜索关键词'},
      'category': {'type': 'string', 'description': '分类筛选'},
    }, required: ['query']),
    _tool('skills_install', '从ClawHub安装技能', {
      'skill_id': {'type': 'string', 'description': '技能ID'},
    }, required: ['skill_id']),
    _tool('skills_update', '更新技能', {
      'skill_id': {'type': 'string', 'description': '技能ID'},
    }, required: ['skill_id']),
    _tool('skills_uninstall', '卸载技能', {
      'skill_id': {'type': 'string', 'description': '技能ID'},
    }, required: ['skill_id']),

    // ═══════════════════════════════════════
    //  配置管理工具
    // ═══════════════════════════════════════
    _tool('config_get', '读取配置项', {
      'key': {'type': 'string', 'description': '配置键 (如 models.openai.apiKey)'},
    }, required: ['key']),
    _tool('config_set', '写入配置项', {
      'key': {'type': 'string', 'description': '配置键'},
      'value': {'type': 'string', 'description': '配置值'},
    }, required: ['key', 'value']),
  ];

  static Map<String, dynamic> _tool(String name, String desc, Map<String, dynamic> props, {List<String>? required}) {
    final t = <String, dynamic>{
      'type': 'function',
      'function': <String, dynamic>{
        'name': name,
        'description': desc,
        'parameters': <String, dynamic>{
          'type': 'object',
          'properties': props,
        },
      },
    };
    if (required != null && required.isNotEmpty) {
      (t['function'] as Map)['parameters']['required'] = required;
    }
    return t;
  }
}
