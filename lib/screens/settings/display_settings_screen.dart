import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 显示设置界面
class DisplaySettingsScreen extends StatefulWidget {
  const DisplaySettingsScreen({super.key});

  @override
  State<DisplaySettingsScreen> createState() => _DisplaySettingsScreenState();
}

class _DisplaySettingsScreenState extends State<DisplaySettingsScreen> {
  bool _showTimestamp = true;
  bool _showAvatar = true;
  bool _compactMode = false;
  bool _autoScroll = true;
  bool _showToolCalls = true;
  double _fontSize = 14.0;
  String _messageAlign = 'left';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showTimestamp = prefs.getBool('display_timestamp') ?? true;
      _showAvatar = prefs.getBool('display_avatar') ?? true;
      _compactMode = prefs.getBool('display_compact') ?? false;
      _autoScroll = prefs.getBool('display_autoscroll') ?? true;
      _showToolCalls = prefs.getBool('display_toolcalls') ?? true;
      _fontSize = prefs.getDouble('display_fontsize') ?? 14.0;
      _messageAlign = prefs.getString('display_align') ?? 'left';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is double) await prefs.setDouble(key, value);
    if (value is String) await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('显示设置', style: TextStyle(color: _text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('消息显示', [
            _buildSwitchTile('显示时间戳', '在消息旁显示发送时间', _showTimestamp, (v) {
              setState(() => _showTimestamp = v);
              _saveSetting('display_timestamp', v);
            }),
            _buildSwitchTile('显示头像', '显示用户和 AI 头像', _showAvatar, (v) {
              setState(() => _showAvatar = v);
              _saveSetting('display_avatar', v);
            }),
            _buildSwitchTile('紧凑模式', '减少消息间距', _compactMode, (v) {
              setState(() => _compactMode = v);
              _saveSetting('display_compact', v);
            }),
            _buildSwitchTile('自动滚动', '新消息自动滚动到底部', _autoScroll, (v) {
              setState(() => _autoScroll = v);
              _saveSetting('display_autoscroll', v);
            }),
            _buildSwitchTile('显示工具调用', '展示 AI 的工具调用过程', _showToolCalls, (v) {
              setState(() => _showToolCalls = v);
              _saveSetting('display_toolcalls', v);
            }),
          ]),
          _buildSection('字体', [
            _buildSliderTile('字体大小', '${_fontSize.toInt()}px', _fontSize, 12, 20, (v) {
              setState(() => _fontSize = v);
              _saveSetting('display_fontsize', v);
            }),
          ]),
          _buildSection('对齐方式', [
            _buildRadioTile('左对齐', 'left', _messageAlign, (v) {
              setState(() => _messageAlign = v);
              _saveSetting('display_align', v);
            }),
            _buildRadioTile('居中', 'center', _messageAlign, (v) {
              setState(() => _messageAlign = v);
              _saveSetting('display_align', v);
            }),
          ]),
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

  Widget _buildSliderTile(String title, String valueText, double value, double min, double max, ValueChanged<double> onChanged) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
      subtitle: Slider(value: value, min: min, max: max, onChanged: onChanged, activeColor: _gold),
      trailing: Text(valueText, style: const TextStyle(color: _gold, fontSize: 12)),
      dense: true,
    );
  }

  Widget _buildRadioTile(String title, String groupValue, String value, ValueChanged<String> onChanged) {
    return RadioListTile<String>(
      title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
      value: value,
      groupValue: groupValue,
      onChanged: (v) => onChanged(v!),
      activeColor: _gold,
      dense: true,
    );
  }
}
