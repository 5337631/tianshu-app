// ═══════════════════════════════════════════════════════════════
// 天枢 - 主设置页（对标 HermesApp SettingsScreen）
// 分区块：账号/模型/主题/语音/聊天/工具/关于
// ═══════════════════════════════════════════════════════════════
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../services/trigger_service.dart';
import '../../services/background_thinking_service.dart';
import '../../utils/method_channel_helper.dart';
import '../../models/model_registry.dart';
import '../../models/model_parameters.dart';
import '../model_config_screen.dart';
import 'theme_settings_screen.dart';
import 'speech_settings_screen.dart';
import 'chat_history_screen.dart';
import 'chat_backup_screen.dart';
import 'tool_permission_screen.dart';
import 'github_account_screen.dart';
import 'token_usage_screen.dart';
import '../terminal_screen.dart';
import 'prompt_template_screen.dart';
import 'display_settings_screen.dart';
import 'emoji_settings_screen.dart';
import 'context_summary_screen.dart';
import 'external_api_screen.dart';
import 'feature_config_screen.dart';
import 'gateway_screen.dart';
import 'mnn_download_screen.dart';
import 'update_screen.dart';
import 'about_screen.dart';
import '../effects_demo_screen.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _channel = MethodChannelHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('设置', style: TextStyle(color: _text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('账号', [
            _buildNavTile(Icons.cloud, 'GitHub 账号', '同步配置与备份', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GitHubAccountScreen()))),
          ]),
          _buildSection('AI 模型', [
            _buildNavTile(Icons.smart_toy, '模型配置', '提供商/模型/参数/端点', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelConfigScreen()))),
            _buildNavTile(Icons.tune, '模型参数', 'Temperature/Top-p/Max Tokens等', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ModelConfigScreen()))),
            _buildNavTile(Icons.person, '提示词管理', 'System Prompt 模板', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromptTemplateScreen()))),
            _buildNavTile(Icons.bar_chart, 'Token 用量', '统计与趋势', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TokenUsageScreen()))),
          ]),
          _buildSection('外观', [
            _buildNavTile(Icons.palette, '主题设置', '颜色/背景/字体/布局', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()))),
            _buildNavTile(Icons.display_settings, '显示设置', '全局显示选项', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DisplaySettingsScreen()))),
            _buildNavTile(Icons.emoji_emotions, '自定义表情', '管理表情包', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmojiSettingsScreen()))),
            _buildNavTile(Icons.auto_awesome, '特效演示', 'Uiverse风格UI特效', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EffectsDemoScreen()))),
          ]),
          _buildSection('语音', [
            _buildNavTile(Icons.record_voice_over, '语音服务', 'TTS 合成 / STT 识别', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeechSettingsScreen()))),
          ]),
          _buildSection('聊天', [
            _buildNavTile(Icons.history, '聊天历史', '搜索/筛选/管理', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatHistoryScreen()))),
            _buildNavTile(Icons.backup, '备份与恢复', '导出/导入聊天记录', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatBackupScreen()))),
            _buildNavTile(Icons.summarize, '上下文总结', '总结阈值/触发配置', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContextSummaryScreen()))),
            _buildNavTile(Icons.http, '外部 HTTP 聊天', '自定义 API 端点', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExternalApiScreen()))),
          ]),
          _buildSection('工具', [
            _buildNavTile(Icons.security, '工具权限', '管理工具调用权限', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ToolPermissionScreen()))),
            _buildNavTile(Icons.build, '功能配置', '开关各功能模块', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeatureConfigScreen()))),
            _buildNavTile(Icons.terminal, '终端', 'Shell 命令执行', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TerminalScreen()))),
          ]),
          _buildSection('系统', [
            _buildNavTile(Icons.router, 'Hermes 网关', '飞书/外部平台接入', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GatewayScreen()))),
            _buildNavTile(Icons.memory, 'MNN 模型下载', '本地推理模型', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MnnDownloadScreen()))),
            _buildNavTile(Icons.update, '检查更新', '版本升级', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateScreen()))),
            _buildNavTile(Icons.info, '关于', '版本/开源协议', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()))),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: _glass, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
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
      ),
    );
  }

  Widget _buildNavTile(IconData icon, String title, String subtitle, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: _gold, size: 22),
      title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: _text2, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: _text2, size: 18) : null,
      onTap: onTap, dense: true,
    );
  }
}
