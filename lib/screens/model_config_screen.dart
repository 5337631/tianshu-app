import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/model_service.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 提供商配置
class ProviderConfig {
  final String id;
  final String name;
  final IconData icon;
  final String defaultBaseUrl;
  final bool supportDynamicModels;
  final bool supportCustomEndpoint;

  const ProviderConfig({
    required this.id,
    required this.name,
    required this.icon,
    required this.defaultBaseUrl,
    this.supportDynamicModels = true,
    this.supportCustomEndpoint = false,
  });
}

/// 模型配置界面 - 对齐HermesApp
class ModelConfigScreen extends StatefulWidget {
  const ModelConfigScreen({super.key});

  @override
  State<ModelConfigScreen> createState() => _ModelConfigScreenState();
}

class _ModelConfigScreenState extends State<ModelConfigScreen> {
  final ModelService _modelService = ModelService.instance;

  // 提供商列表
  final List<ProviderConfig> _providers = const [
    ProviderConfig(id: 'openai', name: 'OpenAI', icon: Icons.psychology, defaultBaseUrl: 'https://api.openai.com/v1'),
    ProviderConfig(id: 'anthropic', name: 'Anthropic', icon: Icons.auto_awesome, defaultBaseUrl: 'https://api.anthropic.com/v1', supportDynamicModels: false),
    ProviderConfig(id: 'gemini', name: 'Gemini', icon: Icons.flash_on, defaultBaseUrl: 'https://generativelanguage.googleapis.com/v1beta'),
    ProviderConfig(id: 'deepseek', name: 'DeepSeek', icon: Icons.explore, defaultBaseUrl: 'https://api.deepseek.com/v1', supportCustomEndpoint: true),
    ProviderConfig(id: 'openrouter', name: 'OpenRouter', icon: Icons.hub, defaultBaseUrl: 'https://openrouter.ai/api/v1', supportCustomEndpoint: true),
    ProviderConfig(id: 'mimo', name: 'MiMo (小米)', icon: Icons.phone_android, defaultBaseUrl: 'https://api.xiaomi.com/v1'),
    ProviderConfig(id: 'custom', name: '自定义', icon: Icons.settings_ethernet, defaultBaseUrl: '', supportCustomEndpoint: true, supportDynamicModels: false),
  ];

  // 当前配置
  String _selectedProvider = 'openai';
  String _selectedModel = '';
  String _apiKey = '';
  String _customBaseUrl = '';
  bool _hasApiKey = false;
  bool _isLoadingModels = false;
  List<ModelInfo> _availableModels = [];

  // 模型参数
  double _temperature = 0.7;
  double _topP = 1.0;
  int _maxTokens = 4096;
  bool _enableReasoning = false;
  bool _enableStreaming = true;

  // Fallback Chain
  List<String> _fallbackChain = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final config = AiService.instance.getConfig();
    setState(() {
      _selectedProvider = config['provider'] ?? 'openai';
      _selectedModel = config['model'] ?? '';
      _hasApiKey = config['hasApiKey'] ?? false;
      _apiKey = config['apiKey'] ?? '';
      _customBaseUrl = config['customEndpoint'] ?? '';
    });

    // 加载模型列表
    if (_hasApiKey) {
      await _fetchModels();
    }
  }

  /// 动态获取模型列表
  Future<void> _fetchModels() async {
    if (!_hasApiKey || _apiKey.isEmpty) return;

    setState(() => _isLoadingModels = true);

    try {
      final provider = _providers.firstWhere((p) => p.id == _selectedProvider);
      final models = await _modelService.fetchModels(
        provider: _selectedProvider,
        apiKey: _apiKey,
        baseUrl: _customBaseUrl.isNotEmpty ? _customBaseUrl : provider.defaultBaseUrl,
      );

      setState(() {
        _availableModels = models;
        // 如果当前选中的模型不在列表中，选择第一个
        if (models.isNotEmpty && !models.any((m) => m.id == _selectedModel)) {
          _selectedModel = models.first.id;
        }
      });
    } catch (e) {
      print('获取模型列表失败: $e');
    } finally {
      setState(() => _isLoadingModels = false);
    }
  }

  Future<void> _saveConfig() async {
    await AiService.instance.configure(
      provider: _getAiProvider(_selectedProvider),
      apiKey: _apiKey,
      model: _selectedModel,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  AiProvider _getAiProvider(String name) {
    switch (name) {
      case 'openai': return AiProvider.openai;
      case 'anthropic': return AiProvider.anthropic;
      case 'gemini': return AiProvider.gemini;
      default: return AiProvider.openai;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('模型配置', style: TextStyle(color: _text)),
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text('保存', style: TextStyle(color: _gold, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('API 配置', [
            _buildProviderTile(),
            _buildApiKeyTile(),
            if (_getCurrentProvider()?.supportCustomEndpoint == true)
              _buildCustomEndpointTile(),
          ]),
          const SizedBox(height: 12),
          _buildSection('模型选择', [
            _buildModelTile(),
          ]),
          const SizedBox(height: 12),
          _buildSection('模型参数', [
            _buildSliderTile('Temperature', _temperature, 0, 2, (v) => setState(() => _temperature = v)),
            _buildSliderTile('Top P', _topP, 0, 1, (v) => setState(() => _topP = v)),
            _buildIntSliderTile('Max Tokens', _maxTokens, 256, 16384, (v) => setState(() => _maxTokens = v.round())),
            SwitchListTile(
              title: const Text('流式输出', style: TextStyle(color: _text, fontSize: 14)),
              value: _enableStreaming,
              onChanged: (v) => setState(() => _enableStreaming = v),
              activeColor: _gold,
              dense: true,
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('连接测试', [
            _buildTestButton(),
          ]),
        ],
      ),
    );
  }

  ProviderConfig? _getCurrentProvider() {
    try {
      return _providers.firstWhere((p) => p.id == _selectedProvider);
    } catch (_) {
      return null;
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: _glass, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text2, letterSpacing: 1)),
            ),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderTile() {
    final provider = _getCurrentProvider();
    return ListTile(
      leading: Icon(provider?.icon ?? Icons.cloud, color: _gold, size: 22),
      title: const Text('AI 提供商', style: TextStyle(color: _text, fontSize: 14)),
      subtitle: Text(provider?.name ?? _selectedProvider, style: const TextStyle(color: _text2, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: _text2, size: 18),
      onTap: _showProviderSelector,
      dense: true,
    );
  }

  Widget _buildApiKeyTile() {
    return ListTile(
      leading: Icon(_hasApiKey ? Icons.vpn_key : Icons.key_off, color: _gold, size: 22),
      title: const Text('API Key', style: TextStyle(color: _text, fontSize: 14)),
      subtitle: Text(
        _hasApiKey ? '${_apiKey.substring(0, 10)}...' : '点击配置',
        style: TextStyle(color: _hasApiKey ? Colors.green : Colors.orange, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: _text2, size: 18),
      onTap: _showApiKeyDialog,
      dense: true,
    );
  }

  Widget _buildCustomEndpointTile() {
    return ListTile(
      leading: const Icon(Icons.link, color: _gold, size: 22),
      title: const Text('自定义端点', style: TextStyle(color: _text, fontSize: 14)),
      subtitle: Text(
        _customBaseUrl.isNotEmpty ? _customBaseUrl : '使用默认',
        style: const TextStyle(color: _text2, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, color: _text2, size: 18),
      onTap: _showEndpointDialog,
      dense: true,
    );
  }

  Widget _buildModelTile() {
    return ListTile(
      leading: const Icon(Icons.smart_toy, color: _gold, size: 22),
      title: const Text('模型', style: TextStyle(color: _text, fontSize: 14)),
      subtitle: Row(
        children: [
          if (_isLoadingModels)
            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
          else
            Icon(_availableModels.isNotEmpty ? Icons.check_circle : Icons.warning, 
              color: _availableModels.isNotEmpty ? Colors.green : Colors.orange, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _selectedModel.isNotEmpty ? _selectedModel : (_isLoadingModels ? '加载中...' : '请先配置API Key'),
              style: const TextStyle(color: _text2, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasApiKey)
            IconButton(
              icon: Icon(_isLoadingModels ? Icons.hourglass_empty : Icons.refresh, color: _gold, size: 18),
              onPressed: _isLoadingModels ? null : _fetchModels,
            ),
          const Icon(Icons.chevron_right, color: _text2, size: 18),
        ],
      ),
      onTap: _showModelSelector,
      dense: true,
    );
  }

  Widget _buildSliderTile(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: _text, fontSize: 14)),
              const Spacer(),
              Text(value.toStringAsFixed(2), style: const TextStyle(color: _gold, fontSize: 12)),
            ],
          ),
          Slider(value: value, min: min, max: max, onChanged: onChanged, activeColor: _gold),
        ],
      ),
    );
  }

  Widget _buildIntSliderTile(String label, int value, int min, int max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: const TextStyle(color: _text, fontSize: 14)),
              const Spacer(),
              Text(value.toString(), style: const TextStyle(color: _gold, fontSize: 12)),
            ],
          ),
          Slider(value: value.toDouble(), min: min.toDouble(), max: max.toDouble(), onChanged: onChanged, activeColor: _gold),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _testConnection,
          icon: const Icon(Icons.wifi_tethering, color: _gold),
          label: const Text('测试连接', style: TextStyle(color: _gold)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _border),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  // 对话框
  void _showProviderSelector() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: const Text('选择提供商', style: TextStyle(color: _text)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _providers.map((p) {
              final isSelected = p.id == _selectedProvider;
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(p.icon, color: isSelected ? _gold : _text2, size: 20),
                    const SizedBox(width: 8),
                    Text(p.name, style: TextStyle(color: isSelected ? _gold : _text)),
                  ],
                ),
                value: p.id,
                groupValue: _selectedProvider,
                activeColor: _gold,
                onChanged: (v) {
                  if (v != null) {
                    setState(() {
                      _selectedProvider = v;
                      _availableModels = [];
                      _selectedModel = '';
                    });
                    Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: const Text('配置 API Key', style: TextStyle(color: _text)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: _text),
          obscureText: true,
          decoration: InputDecoration(
            hintText: 'sk-...',
            hintStyle: TextStyle(color: _text2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: _text2))),
          TextButton(
            onPressed: () async {
              setState(() {
                _apiKey = controller.text.trim();
                _hasApiKey = _apiKey.isNotEmpty;
              });
              Navigator.pop(ctx);
              // 自动获取模型列表
              if (_hasApiKey) {
                await _fetchModels();
              }
            },
            child: const Text('保存', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }

  void _showEndpointDialog() {
    final controller = TextEditingController(text: _customBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: const Text('自定义端点', style: TextStyle(color: _text)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: _text),
          decoration: InputDecoration(
            hintText: 'https://api.example.com/v1',
            hintStyle: TextStyle(color: _text2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _border)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: _text2))),
          TextButton(
            onPressed: () {
              setState(() => _customBaseUrl = controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('保存', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }

  void _showModelSelector() {
    if (_availableModels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置API Key并获取模型列表')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: Row(
          children: [
            const Text('选择模型', style: TextStyle(color: _text)),
            const Spacer(),
            Text('${_availableModels.length} 个', style: const TextStyle(color: _text2, fontSize: 12)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _availableModels.length,
            itemBuilder: (context, index) {
              final model = _availableModels[index];
              final isSelected = model.id == _selectedModel;
              return Card(
                color: isSelected ? _gold.withOpacity(0.1) : _glass,
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: isSelected ? _gold : _border),
                ),
                child: ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? _gold : _text2,
                    size: 20,
                  ),
                  title: Text(model.name, style: TextStyle(color: isSelected ? _gold : _text, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  subtitle: Text(
                    '${model.contextWindow >= 1000000 ? "${(model.contextWindow / 1000000).toStringAsFixed(0)}M" : "${(model.contextWindow / 1000).toStringAsFixed(0)}K"} ctx',
                    style: const TextStyle(color: _text2, fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (model.reasoning)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text('推理', style: TextStyle(color: Colors.purple, fontSize: 10)),
                        ),
                    ],
                  ),
                  onTap: () {
                    setState(() => _selectedModel = model.id);
                    Navigator.pop(ctx);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_hasApiKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置API Key')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('测试连接中...')),
    );

    final provider = _getCurrentProvider();
    final success = await _modelService.testConnection(
      provider: _selectedProvider,
      apiKey: _apiKey,
      baseUrl: _customBaseUrl.isNotEmpty ? _customBaseUrl : provider?.defaultBaseUrl,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '连接成功！' : '连接失败'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }
}
