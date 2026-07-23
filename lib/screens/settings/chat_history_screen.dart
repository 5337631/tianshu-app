// 聊天历史管理页（对标 HermesApp ChatHistorySettingsScreen）
import 'dart:ui';
import 'package:flutter/material.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});
  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all';

  final List<Map<String, dynamic>> _chatHistories = List.generate(20, (i) => {
    'id': 'chat_$i', 'title': '对话 ${i + 1}',
    'character': i % 3 == 0 ? '助手' : null,
    'messageCount': (i + 1) * 10,
    'lastTime': DateTime.now().subtract(Duration(hours: i * 3)),
    'workspace': i % 4 == 0 ? '工作区 ${i ~/ 4}' : null,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = _chatHistories.where((c) {
      if (_searchQuery.isNotEmpty && !c['title'].toString().contains(_searchQuery)) return false;
      if (_filter == 'character' && c['character'] == null) return false;
      if (_filter == 'workspace' && c['workspace'] == null) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('聊天历史', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Color(0x8AFFFFFF)),
            onPressed: () => _showClearDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜索对话...',
                hintStyle: const TextStyle(color: Color(0x8AFFFFFF)),
                prefixIcon: const Icon(Icons.search, color: Color(0x8AFFFFFF), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0x8AFFFFFF), size: 18),
                        onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _buildFilterChip('全部', _filter == 'all', () => setState(() => _filter = 'all')),
              const SizedBox(width: 8),
              _buildFilterChip('角色', _filter == 'character', () => setState(() => _filter = 'character')),
              const SizedBox(width: 8),
              _buildFilterChip('工作区', _filter == 'workspace', () => setState(() => _filter = 'workspace')),
              const Spacer(),
              Text('${filtered.length} 条', style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, color: const Color(0x8AFFFFFF).withOpacity(0.3), size: 48),
                        const SizedBox(height: 8),
                        Text('暂无对话', style: TextStyle(color: const Color(0x8AFFFFFF).withOpacity(0.5), fontSize: 14)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _buildChatItem(filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD700).withOpacity(0.2) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFFFFD700) : const Color(0x1AFFFFFF)),
        ),
        child: Text(label, style: TextStyle(color: selected ? const Color(0xFFFFD700) : const Color(0x8AFFFFFF), fontSize: 12)),
      ),
    );
  }

  Widget _buildChatItem(Map<String, dynamic> chat) {
    final time = chat['lastTime'] as DateTime;
    final timeStr = '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFFFD700).withOpacity(0.2),
          child: const Icon(Icons.chat, color: Color(0xFFFFD700), size: 18),
        ),
        title: Text(chat['title'], style: const TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: Row(
          children: [
            Text('${chat['messageCount']} 条消息', style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 11)),
            const SizedBox(width: 8),
            Text(timeStr, style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 11)),
            if (chat['character'] != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0x1A50E3C2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(chat['character'], style: const TextStyle(color: Color(0xFF50E3C2), fontSize: 10)),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0x8AFFFFFF), size: 18),
        dense: true, onTap: () {},
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A1A),
        title: const Text('清空聊天历史', style: TextStyle(color: Colors.white)),
        content: const Text('确定要删除所有聊天记录吗？此操作不可撤销。', style: TextStyle(color: Color(0x8AFFFFFF))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Color(0x8AFFFFFF)))),
          TextButton(onPressed: () { Navigator.pop(ctx); }, child: const Text('清空', style: TextStyle(color: Color(0xFFFF6B6B)))),
        ],
      ),
    );
  }
}