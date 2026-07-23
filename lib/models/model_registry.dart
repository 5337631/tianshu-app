// ═══════════════════════════════════════════════════════════════
// 天枢 - 模型注册表（模仿 HermesApp models_dev_snapshot.json）
// 声明式模型定义: 每个模型带完整元数据
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';

/// 模型元数据
class ModelInfo {
  final String id;
  final String name;
  final String family;
  final bool reasoning;
  final bool toolCall;
  final bool structuredOutput;
  final int contextWindow;
  final int maxOutput;
  final double? inputPrice;
  final double? outputPrice;
  final String? knowledge;

  const ModelInfo({
    required this.id,
    required this.name,
    this.family = '',
    this.reasoning = false,
    this.toolCall = true,
    this.structuredOutput = false,
    required this.contextWindow,
    this.maxOutput = 4096,
    this.inputPrice,
    this.outputPrice,
    this.knowledge,
  });

  String get contextLabel => contextWindow >= 1000000
      ? '${(contextWindow / 1000000).toStringAsFixed(0)}M'
      : contextWindow >= 1000
          ? '${(contextWindow / 1000).toStringAsFixed(0)}K'
          : '$contextWindow';

  String get priceLabel {
    if (inputPrice == null || outputPrice == null) return '';
    return '\$${inputPrice!.toStringAsFixed(1)}/\$${outputPrice!.toStringAsFixed(1)}';
  }

  List<String> get badgeLabels {
    final labels = <String>[];
    if (reasoning) labels.add('🧠 推理');
    if (toolCall) labels.add('🔧 工具');
    if (structuredOutput) labels.add('📋 结构化');
    if (contextWindow >= 1000000) labels.add('📦 超长上下文');
    return labels;
  }
}

/// 提供商配置
class ProviderInfo {
  final String id;
  final String name;
  final IconData icon;
  final String baseUrl;
  final String? docUrl;
  final List<ModelInfo> models;
  final bool supportsCustomEndpoint;

  const ProviderInfo({
    required this.id,
    required this.name,
    required this.icon,
    required this.baseUrl,
    this.docUrl,
    required this.models,
    this.supportsCustomEndpoint = false,
  });
}

/// 模型注册表
class ModelRegistry {
  static const List<ProviderInfo> providers = [
    ProviderInfo(
      id: 'openai', name: 'OpenAI', icon: Icons.psychology,
      baseUrl: 'https://api.openai.com/v1',
      models: [
        ModelInfo(id: 'gpt-5.4', name: 'GPT-5.4', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 1050000, maxOutput: 128000, inputPrice: 2.5, outputPrice: 15, knowledge: '2025-08'),
        ModelInfo(id: 'gpt-5.4-pro', name: 'GPT-5.4 Pro', reasoning: true, toolCall: true, contextWindow: 1050000, maxOutput: 128000, inputPrice: 30, outputPrice: 180, knowledge: '2025-08'),
        ModelInfo(id: 'gpt-5.3-codex', name: 'GPT-5.3 Codex', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 128000, inputPrice: 1.75, outputPrice: 14, knowledge: '2025-08'),
        ModelInfo(id: 'gpt-5.2', name: 'GPT-5.2', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 128000, inputPrice: 1.75, outputPrice: 14, knowledge: '2025-08'),
        ModelInfo(id: 'gpt-5.2-codex', name: 'GPT-5.2 Codex', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 128000, inputPrice: 1.75, outputPrice: 14, knowledge: '2025-08'),
        ModelInfo(id: 'gpt-5.1', name: 'GPT-5.1', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 128000, inputPrice: 1.25, outputPrice: 10, knowledge: '2024-09'),
        ModelInfo(id: 'gpt-5.1-codex', name: 'GPT-5.1 Codex', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 128000, inputPrice: 1.25, outputPrice: 10, knowledge: '2024-09'),
        ModelInfo(id: 'gpt-5.1-codex-mini', name: 'GPT-5.1 Codex Mini', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 100000, inputPrice: 0.25, outputPrice: 2, knowledge: '2024-09'),
        ModelInfo(id: 'gpt-5', name: 'GPT-5', reasoning: true, toolCall: true, contextWindow: 400000, maxOutput: 128000, inputPrice: 1.25, outputPrice: 10, knowledge: '2024-09'),
        ModelInfo(id: 'gpt-5-pro', name: 'GPT-5 Pro', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 272000, inputPrice: 15, outputPrice: 120, knowledge: '2024-09'),
        ModelInfo(id: 'gpt-5-codex', name: 'GPT-5 Codex', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 400000, maxOutput: 128000, inputPrice: 1.25, outputPrice: 10, knowledge: '2024-10'),
        ModelInfo(id: 'gpt-5-mini', name: 'GPT-5 Mini', reasoning: true, toolCall: true, contextWindow: 128000, maxOutput: 32000, inputPrice: 0.25, outputPrice: 2, knowledge: '2024-05'),
        ModelInfo(id: 'gpt-5-nano', name: 'GPT-5 Nano', reasoning: true, toolCall: true, contextWindow: 16000, maxOutput: 4000, inputPrice: 0.05, outputPrice: 0.4, knowledge: '2024-05'),
        ModelInfo(id: 'o4-mini', name: 'o4 Mini', reasoning: true, toolCall: true, contextWindow: 200000, maxOutput: 100000, inputPrice: 1.1, outputPrice: 4.4, knowledge: '2024-06'),
        ModelInfo(id: 'gpt-4.1', name: 'GPT-4.1', reasoning: false, toolCall: true, contextWindow: 1047576, maxOutput: 32768, inputPrice: 2, outputPrice: 8, knowledge: '2024-04'),
        ModelInfo(id: 'gpt-4.1-mini', name: 'GPT-4.1 Mini', reasoning: false, toolCall: true, contextWindow: 1047576, maxOutput: 32768, inputPrice: 0.4, outputPrice: 1.6, knowledge: '2024-04'),
        ModelInfo(id: 'gpt-4o-mini', name: 'GPT-4o Mini', reasoning: false, toolCall: true, contextWindow: 128000, maxOutput: 16384, inputPrice: 0.15, outputPrice: 0.6, knowledge: '2024-10'),
      ],
    ),
    ProviderInfo(
      id: 'anthropic', name: 'Anthropic', icon: Icons.auto_awesome,
      baseUrl: 'https://api.anthropic.com/v1',
      models: [
        ModelInfo(id: 'claude-opus-4-6', name: 'Claude Opus 4.6', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 1000000, maxOutput: 128000, inputPrice: 5, outputPrice: 25, knowledge: '2025-05'),
        ModelInfo(id: 'claude-sonnet-4-6', name: 'Claude Sonnet 4.6', reasoning: true, toolCall: true, structuredOutput: true, contextWindow: 1000000, maxOutput: 128000, inputPrice: 3, outputPrice: 15, knowledge: '2025-08'),
        ModelInfo(id: 'claude-sonnet-4-5', name: 'Claude Sonnet 4.5', reasoning: true, toolCall: true, contextWindow: 1000000, maxOutput: 64000, inputPrice: 3, outputPrice: 15, knowledge: '2025-07'),
        ModelInfo(id: 'claude-opus-4-5', name: 'Claude Opus 4.5', reasoning: true, toolCall: true, contextWindow: 200000, maxOutput: 64000, inputPrice: 5, outputPrice: 25, knowledge: '2025-03'),
        ModelInfo(id: 'claude-sonnet-4', name: 'Claude Sonnet 4', reasoning: true, toolCall: true, contextWindow: 200000, maxOutput: 64000, inputPrice: 3, outputPrice: 15, knowledge: '2025-03'),
        ModelInfo(id: 'claude-opus-4', name: 'Claude Opus 4', reasoning: true, toolCall: true, contextWindow: 200000, maxOutput: 32000, inputPrice: 15, outputPrice: 75, knowledge: '2025-03'),
        ModelInfo(id: 'claude-opus-4-1', name: 'Claude Opus 4.1', reasoning: true, toolCall: true, contextWindow: 200000, maxOutput: 32000, inputPrice: 15, outputPrice: 75, knowledge: '2025-03'),
        ModelInfo(id: 'claude-haiku-4-5', name: 'Claude Haiku 4.5', reasoning: true, toolCall: true, contextWindow: 200000, maxOutput: 62000, inputPrice: 1, outputPrice: 5, knowledge: '2025-02'),
        ModelInfo(id: 'claude-3-7-sonnet', name: 'Claude 3.7 Sonnet', reasoning: true, toolCall: true, contextWindow: 200000, maxOutput: 64000, inputPrice: 3, outputPrice: 15, knowledge: '2024-01'),
      ],
    ),
    ProviderInfo(
      id: 'gemini', name: 'Gemini', icon: Icons.flash_on,
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      models: [
        ModelInfo(id: 'gemini-3-pro-preview', name: 'Gemini 3 Pro', reasoning: true, toolCall: true, contextWindow: 1048576, maxOutput: 65536, inputPrice: 2, outputPrice: 12, knowledge: '2025-01'),
        ModelInfo(id: 'gemini-3-flash-preview', name: 'Gemini 3 Flash', reasoning: true, toolCall: true, contextWindow: 1048576, maxOutput: 65536, inputPrice: 0.5, outputPrice: 3, knowledge: '2025-01'),
        ModelInfo(id: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro', reasoning: true, toolCall: true, contextWindow: 1048576, maxOutput: 65536, inputPrice: 1.25, outputPrice: 10, knowledge: '2025-01'),
        ModelInfo(id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash', reasoning: true, toolCall: true, contextWindow: 1048576, maxOutput: 65536, inputPrice: 0.3, outputPrice: 2.5, knowledge: '2025-01'),
        ModelInfo(id: 'gemini-2.5-flash-lite', name: 'Gemini 2.5 Flash Lite', reasoning: false, toolCall: true, contextWindow: 1048576, maxOutput: 64000, inputPrice: 0.075, outputPrice: 0.3, knowledge: '2025-01'),
        ModelInfo(id: 'gemini-2.0-flash', name: 'Gemini 2.0 Flash', reasoning: false, toolCall: true, contextWindow: 1048576, maxOutput: 8192, inputPrice: 0.1, outputPrice: 0.4, knowledge: '2024-08'),
      ],
    ),
    ProviderInfo(
      id: 'deepseek', name: 'DeepSeek', icon: Icons.explore,
      baseUrl: 'https://api.deepseek.com/v1',
      supportsCustomEndpoint: true,
      models: [
        ModelInfo(id: 'deepseek-chat', name: 'DeepSeek V3', reasoning: false, toolCall: true, contextWindow: 128000, maxOutput: 16000, inputPrice: 0.27, outputPrice: 1.1, knowledge: '2024-07'),
        ModelInfo(id: 'deepseek-reasoner', name: 'DeepSeek R1', reasoning: true, toolCall: true, contextWindow: 128000, maxOutput: 32000, inputPrice: 0.55, outputPrice: 2.19, knowledge: '2025-01'),
      ],
    ),
    ProviderInfo(
      id: 'openrouter', name: 'OpenRouter', icon: Icons.hub,
      baseUrl: 'https://openrouter.ai/api/v1',
      supportsCustomEndpoint: true,
      models: [
        ModelInfo(id: 'openrouter/auto', name: 'OpenRouter Auto', reasoning: true, toolCall: true, contextWindow: 128000, maxOutput: 64000),
      ],
    ),
    ProviderInfo(
      id: 'custom', name: '自定义', icon: Icons.settings_ethernet,
      baseUrl: '', supportsCustomEndpoint: true,
      models: [
        ModelInfo(id: 'custom-model', name: '自定义模型', reasoning: false, toolCall: true, contextWindow: 128000, maxOutput: 4096),
      ],
    ),
  ];

  static ProviderInfo getProvider(String id) {
    return providers.firstWhere((p) => p.id == id, orElse: () => providers.first);
  }

  static List<ModelInfo> getModels(String providerId) {
    return getProvider(providerId).models;
  }

  static ModelInfo? getModel(String providerId, String modelId) {
    try {
      return getProvider(providerId).models.firstWhere((m) => m.id == modelId);
    } catch (_) {
      return null;
    }
  }
}