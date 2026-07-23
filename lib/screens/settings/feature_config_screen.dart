import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 功能配置界面 - 开关各功能模块
class FeatureConfigScreen extends StatefulWidget {
  const FeatureConfigScreen({super.key});

  @override
  State<FeatureConfigScreen> createState() => _FeatureConfigScreenState();
}

class _FeatureConfigScreenState extends State<FeatureConfigScreen> {
  // 功能开关
  bool _enableMemory = true;
  bool _enableConsciousness = true;
  bool _enablePredict = true;
  bool _enableBackgroundThinking = true;
  bool _enableAgentTeam = true;
  bool _enableSkills = true;
  bool _enableAutoSync = true;
  bool _enableTrigger = true;
  bool _enableMcp = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableMemory = prefs.getBool('feat_memory') ?? true;
      _enableConsciousness = prefs.getBool('feat_consciousness') ?? true;
      _enablePredict = prefs.getBool('feat_predict') ?? true;
      _enableBackgroundThinking = prefs.getBool('feat_bg_thinking') ?? true;
      _enableAgentTeam = prefs.getBool('feat_agent_team') ?? true;
      _enableSkills = prefs.getBool('feat_skills') ?? true;
      _enableAutoSync = prefs.getBool('feat_auto_sync') ?? true;
      _enableTrigger = prefs.getBool('feat_trigger') ?? true;
      _enableMcp = prefs.getBool('feat_mcp') ?? true;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('功能配置', style: TextStyle(color: _text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('核心功能', [
            _buildFeatureTile('记忆系统', '存储和检索对话记忆', Icons.memory, _enableMemory, (v) {
              setState(() => _enableMemory = v);
              _saveSetting('feat_memory', v);
            }),
            _buildFeatureTile('意识蒸馏', '7维人格画像系统', Icons.psychology, _enableConsciousness, (v) {
              setState(() => _enableConsciousness = v);
              _saveSetting('feat_consciousness', v);
            }),
            _buildFeatureTile('智能预判', '基于时间/场景的预测', Icons.auto_awesome, _enablePredict, (v) {
              setState(() => _enablePredict = v);
              _saveSetting('feat_predict', v);
            }),
          ]),
          _buildSection('智能体', [
            _buildFeatureTile('Agent 团队', '6专家协作系统', Icons.groups, _enableAgentTeam, (v) {
              setState(() => _enableAgentTeam = v);
              _saveSetting('feat_agent_team', v);
            }),
            _buildFeatureTile('技能系统', '31个内置技能', Icons.extension, _enableSkills, (v) {
              setState(() => _enableSkills = v);
              _saveSetting('feat_skills', v);
            }),
          ]),
          _buildSection('后台服务', [
            _buildFeatureTile('后台思考', '内心独白可视化', Icons.auto_fix_high, _enableBackgroundThinking, (v) {
              setState(() => _enableBackgroundThinking = v);
              _saveSetting('feat_bg_thinking', v);
            }),
            _buildFeatureTile('自动同步', '数据自动备份', Icons.sync, _enableAutoSync, (v) {
              setState(() => _enableAutoSync = v);
              _saveSetting('feat_auto_sync', v);
            }),
            _buildFeatureTile('触发器', '定时任务执行', Icons.timer, _enableTrigger, (v) {
              setState(() => _enableTrigger = v);
              _saveSetting('feat_trigger', v);
            }),
          ]),
          _buildSection('高级', [
            _buildFeatureTile('MCP Server', '暴露能力给外部Agent', Icons.dns, _enableMcp, (v) {
              setState(() => _enableMcp = v);
              _saveSetting('feat_mcp', v);
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

  Widget _buildFeatureTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: value ? _text : _text2, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: _text2, fontSize: 11)),
      value: value,
      onChanged: onChanged,
      activeColor: _gold,
      dense: true,
    );
  }
}
