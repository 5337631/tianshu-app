import 'package:flutter/material.dart';
import '../../services/feishu_service.dart';

const Color deepSpaceBlue = Color(0xFF0A0A1A);
const Color starGold = Color(0xFFFFD700);
const Color glassWhite = Color(0x12FFFFFF);
const Color glassBorder = Color(0x1AFFFFFF);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0x8AFFFFFF);

/// 飞书配置界面
class FeishuConfigScreen extends StatefulWidget {
  const FeishuConfigScreen({super.key});

  @override
  State<FeishuConfigScreen> createState() => _FeishuConfigScreenState();
}

class _FeishuConfigScreenState extends State<FeishuConfigScreen> {
  final _appIdController = TextEditingController();
  final _appSecretController = TextEditingController();
  final _verificationTokenController = TextEditingController();
  final _encryptKeyController = TextEditingController();
  
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _appIdController.dispose();
    _appSecretController.dispose();
    _verificationTokenController.dispose();
    _encryptKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = FeishuService.instance.getConfig();
    setState(() {
      _isConnected = config['connected'] ?? false;
    });
  }

  Future<void> _saveConfig() async {
    if (_appIdController.text.isEmpty || _appSecretController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 App ID 和 App Secret')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FeishuService.instance.configure(
        appId: _appIdController.text.trim(),
        appSecret: _appSecretController.text.trim(),
        verificationToken: _verificationTokenController.text.trim(),
        encryptKey: _encryptKeyController.text.trim(),
      );

      setState(() {
        _isConnected = FeishuService.instance.isConnected;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isConnected ? '连接成功' : '配置已保存，连接失败'),
            backgroundColor: _isConnected ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepSpaceBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('飞书配置', style: TextStyle(color: textPrimary)),
        actions: [
          // 连接状态指示器
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isConnected ? Colors.green : Colors.orange,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? '已连接' : '未连接',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 说明卡片
            _buildInfoCard(),
            const SizedBox(height: 20),

            // 配置表单
            _buildConfigForm(),
            const SizedBox(height: 20),

            // 保存按钮
            _buildSaveButton(),
            const SizedBox(height: 20),

            // 使用说明
            _buildHelpSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: starGold, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '飞书集成说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '配置飞书应用后，天枢可以通过飞书接收和回复消息。\n\n'
              '1. 在飞书开放平台创建应用\n'
              '2. 获取 App ID 和 App Secret\n'
              '3. 开启机器人能力\n'
              '4. 配置事件订阅 URL',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '应用配置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _appIdController,
              label: 'App ID',
              hint: 'cli_xxxxxxxxxxxxxxxx',
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _appSecretController,
              label: 'App Secret',
              hint: 'xxxxxxxxxxxxxxxxxxxxxxxx',
              isPassword: true,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _verificationTokenController,
              label: 'Verification Token (可选)',
              hint: 'xxxxxxxxxxxxxxxxxxxxxxxx',
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _encryptKeyController,
              label: 'Encrypt Key (可选)',
              hint: 'xxxxxxxxxxxxxxxxxxxxxxxx',
              isPassword: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool isPassword = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: glassWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: glassBorder),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            style: const TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: _isLoading ? null : _saveConfig,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [starGold, Color(0xFFFFA500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: starGold.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: deepSpaceBlue,
                  ),
                )
              : const Text(
                  '保存配置',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: deepSpaceBlue,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: glassWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: starGold, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '配置文件导入',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '也可以通过配置文件导入：\n\n'
              '将配置保存到 /sdcard/.tianshu/config/channels.json：\n'
              '{\n'
              '  "feishu": {\n'
              '    "enabled": true,\n'
              '    "appId": "cli_xxx",\n'
              '    "appSecret": "xxx"\n'
              '  }\n'
              '}',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
