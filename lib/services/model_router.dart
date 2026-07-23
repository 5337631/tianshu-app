import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// 模型配置
class ModelConfig {
  final String id;
  final String provider;
  final String name;
  final String? apiKey;
  final String? baseUrl;
  final bool reasoning;
  final int contextWindow;

  ModelConfig({
    required this.id,
    required this.provider,
    required this.name,
    this.apiKey,
    this.baseUrl,
    this.reasoning = false,
    this.contextWindow = 4096,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'provider': provider,
    'name': name,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'reasoning': reasoning,
    'contextWindow': contextWindow,
  };

  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
    id: json['id'] ?? '',
    provider: json['provider'] ?? '',
    name: json['name'] ?? '',
    apiKey: json['apiKey'],
    baseUrl: json['baseUrl'],
    reasoning: json['reasoning'] ?? false,
    contextWindow: json['contextWindow'] ?? 4096,
  );
}

/// 模型智能路由服务
class ModelRouter {
  static final ModelRouter instance = ModelRouter._internal();
  ModelRouter._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _initialized = false;
  List<ModelConfig> _models = [];
  List<String> _fallbackChain = [];
  Map<String, List<String>> _apiKeys = {};
  List<String> _allowlist = [];
  List<String> _blocklist = [];

  bool get isInitialized => _initialized;
  List<ModelConfig> get models => List.unmodifiable(_models);

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    await _loadConfig();
    _initialized = true;
  }

  /// 加载配置
  Future<void> _loadConfig() async {
    try {
      final jsonStr = await _secureStorage.read(key: 'model_router_config');
      if (jsonStr != null) {
        final config = json.decode(jsonStr);
        _fallbackChain = List<String>.from(config['fallbackChain'] ?? []);
        _allowlist = List<String>.from(config['allowlist'] ?? []);
        _blocklist = List<String>.from(config['blocklist'] ?? []);

        // 加载 API Keys
        final keys = config['apiKeys'] ?? {};
        keys.forEach((k, v) {
          _apiKeys[k] = List<String>.from(v);
        });

        // 加载模型列表
        final models = config['models'] ?? [];
        _models = (models as List).map((m) => ModelConfig.fromJson(m)).toList();
      }
    } catch (_) {}
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    try {
      final config = {
        'fallbackChain': _fallbackChain,
        'allowlist': _allowlist,
        'blocklist': _blocklist,
        'apiKeys': _apiKeys,
        'models': _models.map((m) => m.toJson()).toList(),
      };
      await _secureStorage.write(key: 'model_router_config', value: json.encode(config));
    } catch (_) {}
  }

  /// 路由到最佳模型
  Future<ModelConfig?> route(String taskType) async {
    // 过滤掉 blocklist 中的模型
    final available = _models.where((m) => !_blocklist.contains(m.id)).toList();

    // 如果有 allowlist，只使用 allowlist 中的模型
    final candidates = _allowlist.isNotEmpty
        ? available.where((m) => _allowlist.contains(m.id)).toList()
        : available;

    if (candidates.isEmpty) return null;

    // 根据任务类型选择模型
    for (final model in candidates) {
      if (taskType == 'reasoning' && model.reasoning) {
        return model;
      }
    }

    // 使用 fallback chain
    for (final modelId in _fallbackChain) {
      final model = candidates.firstWhere(
        (m) => m.id == modelId,
        orElse: () => candidates.first,
      );
      return model;
    }

    return candidates.first;
  }

  /// 轮换 API Key
  String? rotateApiKey(String provider) {
    final keys = _apiKeys[provider];
    if (keys == null || keys.isEmpty) return null;

    // 简单轮换：返回第一个，实际应该记录使用次数
    return keys.first;
  }

  /// 添加模型
  Future<void> addModel(ModelConfig model) async {
    _models.add(model);
    await _saveConfig();
  }

  /// 移除模型
  Future<void> removeModel(String modelId) async {
    _models.removeWhere((m) => m.id == modelId);
    await _saveConfig();
  }

  /// 设置 Fallback Chain
  Future<void> setFallbackChain(List<String> chain) async {
    _fallbackChain = chain;
    await _saveConfig();
  }

  /// 设置 Allowlist
  Future<void> setAllowlist(List<String> models) async {
    _allowlist = models;
    await _saveConfig();
  }

  /// 设置 Blocklist
  Future<void> setBlocklist(List<String> models) async {
    _blocklist = models;
    await _saveConfig();
  }

  /// 添加 API Key
  Future<void> addApiKey(String provider, String key) async {
    _apiKeys.putIfAbsent(provider, () => []);
    if (!_apiKeys[provider]!.contains(key)) {
      _apiKeys[provider]!.add(key);
    }
    await _saveConfig();
  }
}
