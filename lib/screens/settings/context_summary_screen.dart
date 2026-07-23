import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/context_manager.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 上下文总结设置界面
class ContextSummaryScreen extends StatefulWidget {
  const ContextSummaryScreen({super.key});

  @override
  State<ContextSummaryScreen> createState() => _ContextSummaryScreenState();
}

class _ContextSummaryScreenState extends State<ContextSummaryScreen> {
  bool _autoSummarize = true;
  int _summaryThreshold = 20;
  int _maxHistoryTurns = 20;
  int _maxTokenBudget = 8000;
  bool _preserveSystemMessages = true;
  bool _preserveRecentMessages = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSummarize = prefs.getBool('ctx_auto_summarize') ?? true;
      _summaryThreshold = prefs.getInt('ctx_summary_threshold') ?? 20;
      _maxHistoryTurns = prefs.getInt('ctx_max_history') ?? 20;
      _maxTokenBudget = prefs.getInt('ctx_max_tokens') ?? 8000;
      _preserveSystemMessages = prefs.getBool('ctx_preserve_system') ?? true;
      _preserveRecentMessages = prefs.getBool('ctx_preserve_recent') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is int) await prefs.setInt(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('上下文总结', style: TextStyle(color: _text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('自动总结', [
            _buildSwitchTile('启用自动总结', '当对话过长时自动总结', _autoSummarize, (v) {
              setState(() => _autoSummarize = v);
              _saveSetting('ctx_auto_summarize', v);
              ContextManager.instance.configure(autoSummarize: v);
            }),
            _buildSliderTile('触发阈值', '$_summaryThreshold 轮对话后总结', _summaryThreshold.toDouble(), 10, 50, (v) {
              setState(() => _summaryThreshold = v.toInt());
              _saveSetting('ctx_summary_threshold', v.toInt());
            }),
          ]),
          _buildSection('历史管理', [
            _buildSliderTile('最大历史轮数', '保留最近 $_maxHistoryTurns 轮', _maxHistoryTurns.toDouble(), 5, 50, (v) {
              setState(() => _maxHistoryTurns = v.toInt());
              _saveSetting('ctx_max_history', v.toInt());
              ContextManager.instance.configure(maxHistoryTurns: v.toInt());
            }),
            _buildSliderTile('Token 预算', '$_maxTokenBudget tokens', _maxTokenBudget.toDouble(), 2000, 16000, (v) {
              setState(() => _maxTokenBudget = v.toInt());
              _saveSetting('ctx_max_tokens', v.toInt());
              ContextManager.instance.configure(maxTokenBudget: v.toInt());
            }),
          ]),
          _buildSection('保留策略', [
            _buildSwitchTile('保留系统消息', '总结时始终保留 System Prompt', _preserveSystemMessages, (v) {
              setState(() => _preserveSystemMessages = v);
              _saveSetting('ctx_preserve_system', v);
            }),
            _buildSwitchTile('保留最近消息', '总结时保留最近 3 条消息', _preserveRecentMessages, (v) {
              setState(() => _preserveRecentMessages = v);
              _saveSetting('ctx_preserve_recent', v);
            }),
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: _text2, fontSize: 11)),
      value: value,
      onChanged: onChanged,
      activeColor: _gold,
      dense: true,
    );
  }

  Widget _buildSliderTile(String title, String subtitle, double value, double min, double max, ValueChanged<double> onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(color: _text2, fontSize: 11)),
          Slider(value: value, min: min, max: max, onChanged: onChanged, activeColor: _gold),
        ],
      ),
      dense: true,
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
              const Text('上下文管理说明', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
            ]),
            const SizedBox(height: 8),
            const Text(
              '上下文管理采用 4 层防护：\n'
              '1. 限制历史轮数，避免过长对话\n'
              '2. 工具结果裁剪，截断过长返回\n'
              '3. Token 预算控制，防止超限\n'
              '4. 自动总结，压缩旧对话',
              style: TextStyle(fontSize: 12, color: _text2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
