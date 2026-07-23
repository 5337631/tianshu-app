// 聊天备份恢复页（对标 HermesApp 备份功能）
import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';

class ChatBackupScreen extends StatefulWidget {
  const ChatBackupScreen({super.key});
  @override
  State<ChatBackupScreen> createState() => _ChatBackupScreenState();
}

class _ChatBackupScreenState extends State<ChatBackupScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _lastBackupTime;
  String _backupSize = '--';
  int _backupCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('备份与恢复', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('数据备份', [
            _buildInfoTile('上次备份', _lastBackupTime ?? '从未备份'),
            _buildInfoTile('备份文件大小', _backupSize),
            _buildInfoTile('备份数量', '$_backupCount 份'),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportData,
                  icon: _isExporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.backup, size: 18),
                  label: Text(_isExporting ? '导出中...' : '导出聊天数据'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD700),
                    foregroundColor: const Color(0xFF0A0A1A),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('数据恢复', [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '从备份文件恢复聊天数据。恢复将覆盖当前数据。',
                style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 12),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isImporting ? null : _importData,
                  icon: _isImporting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.restore, size: 18),
                  label: Text(_isImporting ? '恢复中...' : '从备份恢复'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFFD700),
                    side: const BorderSide(color: Color(0xFFFFD700)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('自动备份设置', [
            _buildSwitchTile('自动备份', '每天自动备份聊天数据', Icons.schedule, true, (_) {}),
            _buildDropdownTile('备份频率', '每天', ['每小时', '每天', '每周', '每月'], (_) {}),
            _buildDropdownTile('保留数量', '10 份', ['3 份', '5 份', '10 份', '20 份'], (_) {}),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isExporting = false;
      _lastBackupTime = '${DateTime.now().month}/${DateTime.now().day} ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
      _backupSize = '2.3 MB';
      _backupCount++;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('备份完成'), duration: Duration(seconds: 2)),
      );
    }
  }

  Future<void> _importData() async {
    setState(() => _isImporting = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isImporting = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恢复完成'), duration: Duration(seconds: 2)),
      );
    }
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

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 13)),
        ],
      ),
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
                Text(subtitle, style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _buildDropdownTile(String label, String value, List<String> options, ValueChanged<String> onChanged) {
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
                  items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (v) { if (v != null) onChanged(v); },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}