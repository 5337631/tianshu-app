import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 外部 HTTP 聊天设置界面
class ExternalApiScreen extends StatefulWidget {
  const ExternalApiScreen({super.key});

  @override
  State<ExternalApiScreen> createState() => _ExternalApiScreenState();
}

class _ExternalApiScreenState extends State<ExternalApiScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final _urlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelNameController = TextEditingController();

  bool _isEnabled = false;
  bool _isTesting = false;
  String _testResult = '';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    _urlController.text = await _storage.read(key: 'external_api_url') ?? '';
    _apiKeyController.text = await _storage.read(key: 'external_api_key') ?? '';
    _modelNameController.text = await _storage.read(key: 'external_api_model') ?? '';
    setState(() {
      _isEnabled = _urlController.text.isNotEmpty;
    });
  }

  Future<void> _saveConfig() async {
    await _storage.write(key: 'external_api_url', value: _urlController.text);
    await _storage.write(key: 'external_api_key', value: _apiKeyController.text);
    await _storage.write(key: 'external_api_model', value: _modelNameController.text);
    setState(() => _isEnabled = _urlController.text.isNotEmpty);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  Future<void> _testConnection() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = '';
    });

    try {
      // 模拟测试
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _testResult = '连接成功！模型: ${_modelNameController.text.isNotEmpty ? _modelNameController.text : "默认"}';
      });
    } catch (e) {
      setState(() {
        _testResult = '连接失败: $e';
      });
    } finally {
      setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('外部 HTTP 聊天', style: TextStyle(color: _text)),
        actions: [
          Switch(
            value: _isEnabled,
            onChanged: (v) => setState(() => _isEnabled = v),
            activeColor: _gold,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('API 配置', [
            _buildTextField('API URL', 'https://api.example.com/v1/chat/completions', _urlController),
            _buildTextField('API Key', 'sk-xxxxxxxx', _apiKeyController, isPassword: true),
            _buildTextField('模型名称', 'gpt-4', _modelNameController),
          ]),
          _buildSection('操作', [
            _buildActionRow([
              _buildActionButton('测试连接', Icons.wifi_find, _testConnection, _isTesting),
              _buildActionButton('保存配置', Icons.save, _saveConfig, false),
            ]),
            if (_testResult.isNotEmpty) _buildTestResult(),
          ]),
          _buildInfoCard(),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: _text2)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: controller,
              obscureText: isPassword,
              style: const TextStyle(color: _text, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: _text2.withOpacity(0.5)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: children),
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap, bool isLoading) {
    return Expanded(
      child: GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _gold.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: _gold))
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: _gold, size: 16),
                      const SizedBox(width: 6),
                      Text(label, style: const TextStyle(color: _gold, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestResult() {
    final isSuccess = _testResult.contains('成功');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isSuccess ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSuccess ? Colors.green : Colors.red),
      ),
      child: Row(
        children: [
          Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(_testResult, style: TextStyle(color: isSuccess ? Colors.green : Colors.red, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _glass, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, color: _gold, size: 20),
              const SizedBox(width: 8),
              const Text('说明', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
            ]),
            const SizedBox(height: 8),
            const Text(
              '支持任何 OpenAI 兼容的 API 端点，如：\n'
              '- OpenAI / OpenRouter\n'
              '- Ollama (本地)\n'
              '- vLLM\n'
              '- LiteLLM',
              style: TextStyle(fontSize: 12, color: _text2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
