// 工具权限管理页（对标 HermesApp 工具权限设置）
import 'dart:ui';
import 'package:flutter/material.dart';

class ToolPermissionScreen extends StatefulWidget {
  const ToolPermissionScreen({super.key});
  @override
  State<ToolPermissionScreen> createState() => _ToolPermissionScreenState();
}

class _ToolPermissionScreenState extends State<ToolPermissionScreen> {
  final List<Map<String, dynamic>> _tools = [
    {'name': '终端', 'icon': Icons.terminal, 'desc': '执行 Shell 命令', 'enabled': true, 'dangerous': true},
    {'name': '文件管理', 'icon': Icons.folder, 'desc': '读写文件系统', 'enabled': true, 'dangerous': false},
    {'name': '网络访问', 'icon': Icons.language, 'desc': 'HTTP 请求与网页浏览', 'enabled': true, 'dangerous': false},
    {'name': '屏幕截图', 'icon': Icons.screenshot, 'desc': '截取屏幕内容', 'enabled': false, 'dangerous': true},
    {'name': '位置服务', 'icon': Icons.location_on, 'desc': '获取设备位置', 'enabled': false, 'dangerous': true},
    {'name': '通知管理', 'icon': Icons.notifications, 'desc': '读取和发送通知', 'enabled': false, 'dangerous': false},
    {'name': '短信/电话', 'icon': Icons.phone, 'desc': '发送短信和拨打电话', 'enabled': false, 'dangerous': true},
    {'name': '日历', 'icon': Icons.calendar_today, 'desc': '读取和创建日历事件', 'enabled': false, 'dangerous': false},
    {'name': '联系人', 'icon': Icons.contacts, 'desc': '读取联系人信息', 'enabled': false, 'dangerous': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('工具权限', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x1AFFD700),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0x1AFFD700)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFFFD700), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '控制每个工具对设备的访问权限。关闭后 AI 将无法使用该工具。',
                      style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tools.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0x1AFFFFFF), height: 1, indent: 52),
              itemBuilder: (ctx, i) {
                final tool = _tools[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: tool['enabled']
                              ? const Color(0xFFFFD700).withOpacity(0.2)
                              : const Color(0x1AFFFFFF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(tool['icon'] as IconData, color: tool['enabled'] ? const Color(0xFFFFD700) : const Color(0x8AFFFFFF), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(tool['name'], style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: tool['enabled'] ? FontWeight.w500 : FontWeight.normal)),
                                if (tool['dangerous'] as bool) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1AFF6B6B),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('高危', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 9)),
                                  ),
                                ],
                              ],
                            ),
                            Text(tool['desc'], style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 11)),
                          ],
                        ),
                      ),
                      Switch(
                        value: tool['enabled'] as bool,
                        onChanged: (v) {
                          setState(() => tool['enabled'] = v);
                          if (v && tool['dangerous'] as bool) {
                            _showWarningDialog(tool['name']);
                          }
                        },
                        activeColor: const Color(0xFFFFD700),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showWarningDialog(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A1A),
        title: const Text('权限警告', style: TextStyle(color: Colors.white)),
        content: Text('启用 $name 权限后，AI 将能够执行敏感操作。请确保你信任当前使用的 AI 服务。', style: const TextStyle(color: Color(0x8AFFFFFF))),
        actions: [
          TextButton(onPressed: () { setState(() { _tools.firstWhere((t) => t['name'] == name)['enabled'] = false; }); Navigator.pop(ctx); }, child: const Text('取消', style: TextStyle(color: Color(0x8AFFFFFF)))),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('确认启用', style: TextStyle(color: Color(0xFFFFD700)))),
        ],
      ),
    );
  }
}