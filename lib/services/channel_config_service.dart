import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 渠道配置
class ChannelConfig {
  final String name;
  final String type; // telegram, email, mcp
  final bool enabled;
  final Map<String, String> settings;

  ChannelConfig({
    required this.name,
    required this.type,
    this.enabled = false,
    this.settings = const {},
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'enabled': enabled,
    'settings': settings,
  };

  factory ChannelConfig.fromJson(Map<String, dynamic> json) => ChannelConfig(
    name: json['name'] ?? '',
    type: json['type'] ?? '',
    enabled: json['enabled'] ?? false,
    settings: Map<String, String>.from(json['settings'] ?? {}),
  );

  ChannelConfig copyWith({bool? enabled, Map<String, String>? settings}) {
    return ChannelConfig(
      name: name,
      type: type,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
    );
  }
}

/// 渠道配置服务
class ChannelConfigService {
  static final ChannelConfigService instance = ChannelConfigService._internal();
  ChannelConfigService._internal();

  SharedPreferences? _prefs;
  List<ChannelConfig> _channels = [];
  bool _initialized = false;

  List<ChannelConfig> get channels => List.unmodifiable(_channels);

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    await _loadChannels();
    _initialized = true;
  }

  Future<void> _loadChannels() async {
    final json = _prefs?.getString('channel_configs');
    if (json != null) {
      try {
        final list = jsonDecode(json) as List;
        _channels = list.map((e) => ChannelConfig.fromJson(e)).toList();
      } catch (_) {
        _channels = [];
      }
    }

    // 确保有默认渠道
    if (_channels.isEmpty) {
      _channels = [
        ChannelConfig(name: 'Telegram', type: 'telegram'),
        ChannelConfig(name: 'Email', type: 'email'),
        ChannelConfig(name: 'MCP', type: 'mcp'),
      ];
      await _saveChannels();
    }
  }

  Future<void> _saveChannels() async {
    final json = jsonEncode(_channels.map((e) => e.toJson()).toList());
    await _prefs?.setString('channel_configs', json);
  }

  /// 更新渠道配置
  Future<void> updateChannel(String name, {bool? enabled, Map<String, String>? settings}) async {
    final index = _channels.indexWhere((c) => c.name == name);
    if (index >= 0) {
      _channels[index] = _channels[index].copyWith(
        enabled: enabled,
        settings: settings,
      );
      await _saveChannels();
    }
  }

  /// 获取渠道配置
  ChannelConfig? getChannel(String name) {
    try {
      return _channels.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  /// 获取已启用的渠道
  List<ChannelConfig> getEnabledChannels() {
    return _channels.where((c) => c.enabled).toList();
  }

  /// 按类型获取渠道
  List<ChannelConfig> getChannelsByType(String type) {
    return _channels.where((c) => c.type == type).toList();
  }

  /// 添加自定义渠道
  Future<void> addChannel(ChannelConfig channel) async {
    _channels.add(channel);
    await _saveChannels();
  }

  /// 删除渠道
  Future<void> removeChannel(String name) async {
    _channels.removeWhere((c) => c.name == name);
    await _saveChannels();
  }

  /// 获取渠道摘要
  Map<String, dynamic> getSummary() {
    final enabled = _channels.where((c) => c.enabled).length;
    final byType = <String, int>{};
    for (final c in _channels) {
      byType[c.type] = (byType[c.type] ?? 0) + 1;
    }

    return {
      'total': _channels.length,
      'enabled': enabled,
      'byType': byType,
    };
  }
}
