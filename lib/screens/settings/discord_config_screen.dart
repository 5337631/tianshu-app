import 'package:flutter/material.dart';
import '../../services/discord_service.dart';

const Color deepSpaceBlue = Color(0xFF0A0A1A);
const Color starGold = Color(0xFFFFD700);
const Color glassWhite = Color(0x12FFFFFF);
const Color glassBorder = Color(0x1AFFFFFF);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0x8AFFFFFF);

/// Discord 配置界面
class DiscordConfigScreen extends StatefulWidget {
  const DiscordConfigScreen({super.key});

  @override
  State<DiscordConfigScreen> createState() => _DiscordConfigScreenState();
}

class _DiscordConfigScreenState extends State<DiscordConfigScreen> {
  final _botTokenController = TextEditingController();
  final _guildIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _botTokenController.dispose();
    _guildIdController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    final config = DiscordService.instance.getConfig();
    setState(() {
      _isConnected = config['connected'] ?? false;
    });
  }

  Future<void> _saveConfig() async {
    if (_botTokenController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写 Bot Token')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await DiscordService.instance.configure(
        botToken: _botTokenController.text.trim(),
        guildId: _guildIdController.text.trim(),
      );

      setState(() {
        _isConnected = DiscordService.instance.isConnected;
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
        title: const Text('Discord 配置', style: TextStyle(color: textPrimary)),
        actions: [
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
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildConfigForm(),
            const SizedBox(height: 20),
            _buildSaveButton(),
            const SizedBox(height: 20),
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
                  'Discord 集成说明',
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
              '配置 Discord 机器人后，天枢可以通过 Discord 接收和回复消息。\n\n'
              '1. 在 Discord 开发者门户创建应用\n'
              '2. 创建 Bot 并获取 Token\n'
              '3. 开启 Message Content Intent\n'
              '4. 邀请 Bot 到你的服务器',
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
              'Bot 配置',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _botTokenController,
              label: 'Bot Token',
              hint: 'MTxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
              isPassword: true,
            ),
            const SizedBox(height: 12),

            _buildTextField(
              controller: _guildIdController,
              label: 'Server ID (可选)',
              hint: '123456789012345678',
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
              '  "discord": {\n'
              '    "enabled": true,\n'
              '    "botToken": "MTxxxxxxxx"\n'
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
