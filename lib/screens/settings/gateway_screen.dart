import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/feishu_service.dart';
import '../../services/discord_service.dart';
import 'feishu_config_screen.dart';
import 'discord_config_screen.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// Hermes 网关设置界面 - 飞书/外部平台接入
class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key});

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen> {
  bool _feishuConnected = false;
  bool _discordConnected = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _loadStatus() {
    setState(() {
      _feishuConnected = FeishuService.instance.isConnected;
      _discordConnected = DiscordService.instance.isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hermes 网关', style: TextStyle(color: _text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildSection('消息渠道', [
            _buildChannelTile(
              '飞书',
              Icons.chat,
              _feishuConnected,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeishuConfigScreen())).then((_) => _loadStatus()),
            ),
            _buildChannelTile(
              'Discord',
              Icons.gamepad,
              _discordConnected,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DiscordConfigScreen())).then((_) => _loadStatus()),
            ),
          ]),
          _buildSection('MCP Server', [
            _buildInfoTile('端口', '8399'),
            _buildInfoTile('协议', 'Streamable HTTP'),
            _buildInfoTile('能力', '无障碍 / 截屏 / 文件'),
          ]),
          _buildHelpCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final activeCount = (_feishuConnected ? 1 : 0) + (_discordConnected ? 1 : 0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: activeCount > 0
                ? [Colors.green.withOpacity(0.2), _glass]
                : [_glass, _glass],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: activeCount > 0 ? Colors.green : _border),
        ),
        child: Column(
          children: [
            Icon(
              Icons.wifi,
              color: activeCount > 0 ? Colors.green : _text2,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              activeCount > 0 ? '$activeCount 个渠道已连接' : '未连接任何渠道',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: activeCount > 0 ? Colors.green : _text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '通过飞书或 Discord 远程控制天枢',
              style: TextStyle(fontSize: 12, color: _text2),
            ),
          ],
        ),
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

  Widget _buildChannelTile(String name, IconData icon, bool isConnected, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: isConnected ? Colors.green : _text2, size: 22),
      title: Text(name, style: const TextStyle(color: _text, fontSize: 14)),
      subtitle: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.orange,
            ),
          ),
          const SizedBox(width: 6),
          Text(isConnected ? '已连接' : '未配置', style: TextStyle(color: isConnected ? Colors.green : _text2, fontSize: 11)),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: _text2, size: 18),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: _text, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: _gold, fontSize: 12)),
      dense: true,
    );
  }

  Widget _buildHelpCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _glass, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.help_outline, color: _gold, size: 20),
              const SizedBox(width: 8),
              const Text('使用说明', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
            ]),
            const SizedBox(height: 8),
            const Text(
              '配置飞书或 Discord 后，可以通过消息远程控制天枢：\n\n'
              '1. 在飞书/Discord 中发送消息给天枢\n'
              '2. 天枢自动处理并回复\n'
              '3. 支持工具调用、代码执行等完整功能\n\n'
              'MCP Server 可将天枢能力暴露给 Claude Desktop 等外部 Agent。',
              style: TextStyle(fontSize: 12, color: _text2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
