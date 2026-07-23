// 语音服务设置页（对标 HermesApp SpeechServicesSettingsScreen）
// TTS/STT 配置：服务类型、HTTP 端点、语音选择、参数调节

import 'dart:convert';
import 'package:flutter/material.dart';

class SpeechSettingsScreen extends StatefulWidget {
  const SpeechSettingsScreen({super.key});
  @override
  State<SpeechSettingsScreen> createState() => _SpeechSettingsScreenState();
}

class _SpeechSettingsScreenState extends State<SpeechSettingsScreen> {
  String _ttsServiceType = 'system';
  bool _ttsEnabled = true;
  double _ttsSpeechRate = 1.0;
  double _ttsPitch = 1.0;
  String _ttsUrlTemplate = 'https://api.example.com/tts';
  String _ttsApiKey = '';
  String _ttsVoiceId = 'default';
  String _ttsModelName = 'tts-1';
  String _ttsLocaleTag = 'zh-CN';
  String _ttsHttpMethod = 'POST';
  String _ttsRequestBody = '{"input":"{{text}}","voice":"{{voice}}"}';
  String _ttsContentType = 'application/json';
  
  bool _sttEnabled = true;
  String _sttServiceType = 'system';
  String _sttEndpointUrl = '';
  String _sttApiKey = '';
  String _sttModelName = 'whisper-1';
  String _sttLocale = 'zh';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('语音服务', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('TTS 语音合成', [
            _buildSwitchTile('启用 TTS', '文字转语音', Icons.volume_up, _ttsEnabled, (v) => _ttsEnabled = v),
            if (_ttsEnabled) ...[
              _buildDropdownTile('服务类型', _ttsServiceType, ['system', 'http', 'none'], ['系统 TTS', 'HTTP API', '禁用'], (v) => _ttsServiceType = v),
              _buildSliderTile('语速', _ttsSpeechRate, 0.1, 3.0, (v) => _ttsSpeechRate = v),
              _buildSliderTile('音调', _ttsPitch, 0.1, 2.0, (v) => _ttsPitch = v),
              if (_ttsServiceType == 'http') ...[
                _buildTextField('URL 模板', _ttsUrlTemplate, (v) => _ttsUrlTemplate = v),
                _buildTextField('API Key', _ttsApiKey, (v) => _ttsApiKey = v, obscure: true),
                _buildTextField('语音 ID', _ttsVoiceId, (v) => _ttsVoiceId = v),
                _buildTextField('模型名', _ttsModelName, (v) => _ttsModelName = v),
                _buildDropdownTile('HTTP 方法', _ttsHttpMethod, ['POST', 'GET'], ['POST', 'GET'], (v) => _ttsHttpMethod = v),
                _buildTextField('请求体模板', _ttsRequestBody, (v) => _ttsRequestBody = v, maxLines: 3),
                _buildTextField('Content-Type', _ttsContentType, (v) => _ttsContentType = v),
              ],
            ],
          ]),
          const SizedBox(height: 16),
          _buildSection('STT 语音识别', [
            _buildSwitchTile('启用 STT', '语音转文字', Icons.mic, _sttEnabled, (v) => _sttEnabled = v),
            if (_sttEnabled) ...[
              _buildDropdownTile('服务类型', _sttServiceType, ['system', 'http', 'none'], ['系统 STT', 'HTTP API', '禁用'], (v) => _sttServiceType = v),
              _buildTextField('端点 URL', _sttEndpointUrl, (v) => _sttEndpointUrl = v),
              _buildTextField('API Key', _sttApiKey, (v) => _sttApiKey = v, obscure: true),
              _buildTextField('模型名', _sttModelName, (v) => _sttModelName = v),
              _buildTextField('语言', _sttLocale, (v) => _sttLocale = v),
            ],
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0x8AFFFFFF), letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x12FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _buildSliderTile(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(child: Slider(value: value, min: min, max: max, activeColor: const Color(0xFFFFD700), onChanged: onChanged)),
          SizedBox(width: 36, child: Text(value.toStringAsFixed(1), style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String label, String value, List<String> values, List<String> labels, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13))),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0x1AFFFFFF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0x1AFFFFFF)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  items: List.generate(values.length, (i) => DropdownMenuItem(value: values[i], child: Text(labels[i]))),
                  onChanged: (v) { if (v != null) onChanged(v); },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String value, ValueChanged<String> onChanged, {bool obscure = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextField(
        controller: TextEditingController(text: value),
        style: const TextStyle(color: Colors.white, fontSize: 13),
        obscureText: obscure,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: onChanged,
      ),
    );
  }
}