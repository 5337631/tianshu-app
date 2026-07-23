import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 关于界面
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('关于', style: TextStyle(color: _text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Logo
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('天枢', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _bg)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('天枢 AI 助手', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _text))),
          const SizedBox(height: 4),
          const Center(child: Text('v1.0.0+1', style: TextStyle(fontSize: 14, color: _text2))),
          const SizedBox(height: 32),

          // 信息卡片
          _buildSection('应用信息', [
            _buildInfoTile('版本', '1.0.0+1'),
            _buildInfoTile('构建', '2026-07-23'),
            _buildInfoTile('Flutter', '3.29.3'),
            _buildInfoTile('平台', 'Android'),
          ]),
          _buildSection('开源协议', [
            _buildInfoTile('许可证', 'MIT License'),
            _buildInfoTile('Copyright', '2026 Tianshu'),
          ]),
          _buildSection('链接', [
            _buildLinkTile('GitHub', Icons.code, 'https://github.com/tianshu'),
            _buildLinkTile('文档', Icons.book, 'https://docs.tianshu.ai'),
            _buildLinkTile('反馈', Icons.bug_report, 'https://github.com/tianshu/issues'),
          ]),
          const SizedBox(height: 32),
          const Center(
            child: Text(
              '由天枢团队用心打造',
              style: TextStyle(fontSize: 12, color: _text2),
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              '让 AI 真正为你所用',
              style: TextStyle(fontSize: 12, color: _text2),
            ),
          ),
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

  Widget _buildInfoTile(String label, String value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: _text, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: _text2, fontSize: 12)),
      dense: true,
    );
  }

  Widget _buildLinkTile(String label, IconData icon, String url) {
    return ListTile(
      leading: Icon(icon, color: _gold, size: 20),
      title: Text(label, style: const TextStyle(color: _text, fontSize: 14)),
      trailing: const Icon(Icons.open_in_new, color: _text2, size: 16),
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      dense: true,
    );
  }
}
