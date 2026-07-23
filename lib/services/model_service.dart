import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 模型信息
class ModelInfo {
  final String id;
  final String name;
  final String provider;
  final bool reasoning;
  final bool toolCall;
  final int contextWindow;
  final int maxOutput;

  ModelInfo({
    required this.id,
    required this.name,
    required this.provider,
    this.reasoning = false,
    this.toolCall = true,
    this.contextWindow = 128000,
    this.maxOutput = 4096,
  });

  factory ModelInfo.fromJson(Map<String, dynamic> json, String provider) {
    return ModelInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? json['id'] ?? '',
      provider: provider,
      reasoning: json['reasoning'] ?? false,
      toolCall: json['tool_call'] ?? true,
      contextWindow: json['context_window'] ?? 128000,
      maxOutput: json['max_output'] ?? 4096,
    );
  }
}

/// 模型服务 - 动态获取模型列表
class ModelService {
  static final ModelService instance = ModelService._internal();
  ModelService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 获取OpenAI兼容API的模型列表
  Future<List<ModelInfo>> fetchModels({
    required String provider,
    required String apiKey,
    String? baseUrl,
  }) async {
    try {
      String endpoint;
      Map<String, String> headers;

      switch (provider) {
        case 'openai':
          endpoint = '${baseUrl ?? "https://api.openai.com/v1"}/models';
          headers = {'Authorization': 'Bearer $apiKey'};
          break;
        case 'anthropic':
          // Anthropic没有模型列表API，返回预设列表
          return _getAnthropicModels();
        case 'gemini':
          return _getGeminiModels(apiKey);
        case 'deepseek':
          endpoint = '${baseUrl ?? "https://api.deepseek.com/v1"}/models';
          headers = {'Authorization': 'Bearer $apiKey'};
          break;
        case 'openrouter':
          endpoint = '${baseUrl ?? "https://openrouter.ai/api/v1"}/models';
          headers = {'Authorization': 'Bearer $apiKey'};
          break;
        case 'mimo':
          endpoint = '${baseUrl ?? "https://api.xiaomi.com/v1"}/models';
          headers = {'Authorization': 'Bearer $apiKey'};
          break;
        default:
          // 自定义端点
          if (baseUrl != null && baseUrl.isNotEmpty) {
            endpoint = '$baseUrl/models';
            headers = {'Authorization': 'Bearer $apiKey'};
          } else {
            return [];
          }
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = <ModelInfo>[];

        if (data['data'] != null) {
          for (final model in data['data']) {
            models.add(ModelInfo.fromJson(model, provider));
          }
        }

        // 按ID排序
        models.sort((a, b) => a.id.compareTo(b.id));
        return models;
      }
      return [];
    } catch (e) {
      print('ModelService.fetchModels error: $e');
      return [];
    }
  }

  /// Anthropic预设模型列表
  List<ModelInfo> _getAnthropicModels() {
    return [
      ModelInfo(id: 'claude-opus-4-6', name: 'Claude Opus 4.6', provider: 'anthropic', reasoning: true, contextWindow: 1000000, maxOutput: 128000),
      ModelInfo(id: 'claude-sonnet-4-6', name: 'Claude Sonnet 4.6', provider: 'anthropic', reasoning: true, contextWindow: 1000000, maxOutput: 128000),
      ModelInfo(id: 'claude-sonnet-4-5', name: 'Claude Sonnet 4.5', provider: 'anthropic', reasoning: true, contextWindow: 1000000, maxOutput: 64000),
      ModelInfo(id: 'claude-sonnet-4', name: 'Claude Sonnet 4', provider: 'anthropic', reasoning: true, contextWindow: 200000, maxOutput: 64000),
      ModelInfo(id: 'claude-haiku-4-5', name: 'Claude Haiku 4.5', provider: 'anthropic', reasoning: true, contextWindow: 200000, maxOutput: 62000),
      ModelInfo(id: 'claude-3-7-sonnet', name: 'Claude 3.7 Sonnet', provider: 'anthropic', reasoning: true, contextWindow: 200000, maxOutput: 64000),
    ];
  }

  /// Gemini动态获取模型列表
  Future<List<ModelInfo>> _getGeminiModels(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final models = <ModelInfo>[];

        if (data['models'] != null) {
          for (final model in data['models']) {
            final name = model['name'] ?? '';
            final displayName = model['displayName'] ?? name;
            final supportedMethods = model['supportedGenerationMethods'] ?? [];

            // 只保留支持generateContent的模型
            if (supportedMethods.contains('generateContent')) {
              models.add(ModelInfo(
                id: name.replaceFirst('models/', ''),
                name: displayName,
                provider: 'gemini',
                toolCall: true,
                contextWindow: model['inputTokenLimit'] ?? 128000,
                maxOutput: model['outputTokenLimit'] ?? 8192,
              ));
            }
          }
        }
        return models;
      }
      return _getGeminiPresetModels();
    } catch (e) {
      return _getGeminiPresetModels();
    }
  }

  /// Gemini预设模型列表（fallback）
  List<ModelInfo> _getGeminiPresetModels() {
    return [
      ModelInfo(id: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro', provider: 'gemini', reasoning: true, contextWindow: 1048576, maxOutput: 65536),
      ModelInfo(id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash', provider: 'gemini', reasoning: true, contextWindow: 1048576, maxOutput: 65536),
      ModelInfo(id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash', provider: 'gemini', contextWindow: 1048576, maxOutput: 8192),
    ];
  }

  /// 测试API连接
  Future<bool> testConnection({
    required String provider,
    required String apiKey,
    String? baseUrl,
  }) async {
    try {
      final models = await fetchModels(
        provider: provider,
        apiKey: apiKey,
        baseUrl: baseUrl,
      );
      return models.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
