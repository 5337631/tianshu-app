import 'dart:ui';
import 'package:flutter/material.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 自定义表情界面
class EmojiSettingsScreen extends StatefulWidget {
  const EmojiSettingsScreen({super.key});

  @override
  State<EmojiSettingsScreen> createState() => _EmojiSettingsScreenState();
}

class _EmojiSettingsScreenState extends State<EmojiSettingsScreen> {
  // 内置表情分类
  final Map<String, List<String>> _emojiCategories = {
    '常用': ['😊', '😂', '❤️', '👍', '🎉', '🔥', '✨', '💯', '🙏', '🤔', '😍', '🥳'],
    '动物': ['🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨', '🐯', '🦁', '🐮'],
    '食物': ['🍎', '🍕', '🍔', '🍣', '🍜', '🍰', '☕', '🍺', '🥤', '🍦', '🍩', '🍪'],
    '自然': ['🌸', '🌺', '🌻', '🌹', '🌲', '🌈', '⭐', '🌙', '☀️', '🌊', '🔥', '❄️'],
    '活动': ['⚽', '🏀', '🎮', '🎵', '🎨', '📚', '✈️', '🚗', '💻', '📱', '🎬', '📸'],
  };

  List<String> _customEmojis = ['🚀', '💡', '🎯', '⚡', '🔔', '📌'];
  String _selectedCategory = '常用';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('自定义表情', style: TextStyle(color: _text)),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: _gold),
            onPressed: _showAddEmojiDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // 分类选择器
          _buildCategoryTabs(),
          // 表情网格
          Expanded(
            child: _buildEmojiGrid(),
          ),
          // 我的收藏
          _buildCustomEmojisSection(),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _emojiCategories.keys.map((category) {
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? _gold.withOpacity(0.2) : _glass,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? _gold : _border),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? _gold : _text2,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiGrid() {
    final emojis = _emojiCategories[_selectedCategory] ?? [];
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _onEmojiTap(emojis[index]),
          onLongPress: () => _showEmojiOptions(emojis[index]),
          child: Container(
            decoration: BoxDecoration(
              color: _glass,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: Center(
              child: Text(emojis[index], style: const TextStyle(fontSize: 28)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomEmojisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _glass,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('我的收藏', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _customEmojis.map((emoji) {
              return GestureDetector(
                onTap: () => _onEmojiTap(emoji),
                onLongPress: () => _removeCustomEmoji(emoji),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _onEmojiTap(String emoji) {
    // 将表情复制到剪贴板
    // 实际使用时可以发送到聊天
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已选择 $emoji'), duration: const Duration(seconds: 1)),
    );
  }

  void _showEmojiOptions(String emoji) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            _buildOptionButton('添加到收藏', Icons.favorite, () {
              setState(() => _customEmojis.add(emoji));
              Navigator.pop(context);
            }),
            _buildOptionButton('复制', Icons.copy, () {
              Navigator.pop(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String label, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: _gold),
      title: Text(label, style: const TextStyle(color: _text)),
      onTap: onTap,
    );
  }

  void _showAddEmojiDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: const Text('添加表情', style: TextStyle(color: _text)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: _text, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: '粘贴表情',
            hintStyle: TextStyle(color: _text2),
            border: OutlineInputBorder(borderSide: BorderSide(color: _border)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: _text2))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() => _customEmojis.add(controller.text));
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }

  void _removeCustomEmoji(String emoji) {
    setState(() => _customEmojis.remove(emoji));
  }
}
