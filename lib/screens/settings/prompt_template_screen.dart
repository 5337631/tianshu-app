import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 预设提示词模板
class PromptTemplate {
  final String name;
  final String description;
  final String content;
  final String category;

  const PromptTemplate({
    required this.name,
    required this.description,
    required this.content,
    this.category = '通用',
  });
}

/// 提示词管理界面
class PromptTemplateScreen extends StatefulWidget {
  const PromptTemplateScreen({super.key});

  @override
  State<PromptTemplateScreen> createState() => _PromptTemplateScreenState();
}

class _PromptTemplateScreenState extends State<PromptTemplateScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _currentPrompt = '';
  bool _isEditing = false;
  final _editController = TextEditingController();

  // 预设模板
  final List<PromptTemplate> _templates = const [
    PromptTemplate(
      name: '默认助手',
      description: '通用智能助手，友好且专业',
      content: '你是天枢，一个智能助手。请用简洁专业的语言回答问题，必要时使用工具完成任务。',
      category: '通用',
    ),
    PromptTemplate(
      name: '代码专家',
      description: '专注于编程和技术问题',
      content: '你是一个专业的编程助手。回答代码相关问题时，提供完整可运行的代码示例，并解释关键逻辑。',
      category: '专业',
    ),
    PromptTemplate(
      name: '创意写作',
      description: '帮助生成创意内容',
      content: '你是一个创意写作助手。帮助用户撰写文章、故事、文案等，注重文笔优美和创意表达。',
      category: '创意',
    ),
    PromptTemplate(
      name: '学习导师',
      description: '耐心解答学习问题',
      content: '你是一个耐心的学习导师。用通俗易懂的语言解释复杂概念，通过举例和类比帮助理解。',
      category: '教育',
    ),
    PromptTemplate(
      name: '翻译助手',
      description: '专业多语言翻译',
      content: '你是一个专业翻译。准确翻译各种语言，保持原文风格和语境，提供多种翻译选项。',
      category: '语言',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentPrompt();
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentPrompt() async {
    final saved = await _storage.read(key: 'system_prompt');
    setState(() {
      _currentPrompt = saved ?? _templates.first.content;
    });
  }

  Future<void> _savePrompt(String prompt) async {
    await _storage.write(key: 'system_prompt', value: prompt);
    setState(() {
      _currentPrompt = prompt;
      _isEditing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提示词已保存')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('提示词管理', style: TextStyle(color: _text)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: _gold),
            onPressed: () {
              if (_isEditing) {
                _savePrompt(_editController.text);
              } else {
                setState(() {
                  _isEditing = true;
                  _editController.text = _currentPrompt;
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 当前提示词
          _buildCurrentPromptSection(),
          const SizedBox(height: 20),
          // 预设模板
          _buildTemplatesSection(),
        ],
      ),
    );
  }

  Widget _buildCurrentPromptSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _glass,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note, color: _gold, size: 20),
                const SizedBox(width: 8),
                const Text('当前提示词', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _gold.withOpacity(0.3)),
                ),
                child: TextField(
                  controller: _editController,
                  maxLines: 8,
                  style: const TextStyle(color: _text, fontFamily: 'monospace', fontSize: 13),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentPrompt,
                  style: const TextStyle(color: _text2, fontSize: 13, height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesSection() {
    final categories = _templates.map((t) => t.category).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('预设模板', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
        const SizedBox(height: 12),
        for (final category in categories) ...[
          Text(category, style: const TextStyle(fontSize: 14, color: _text2)),
          const SizedBox(height: 8),
          for (final template in _templates.where((t) => t.category == category))
            _buildTemplateCard(template),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildTemplateCard(PromptTemplate template) {
    final isCurrent = _currentPrompt == template.content;
    return GestureDetector(
      onTap: () => _savePrompt(template.content),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrent ? _gold.withOpacity(0.1) : _glass,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrent ? _gold : _border,
            width: isCurrent ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(template.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text)),
                  const SizedBox(height: 4),
                  Text(template.description, style: const TextStyle(fontSize: 12, color: _text2)),
                ],
              ),
            ),
            if (isCurrent)
              Icon(Icons.check_circle, color: _gold, size: 20),
          ],
        ),
      ),
    );
  }
}
