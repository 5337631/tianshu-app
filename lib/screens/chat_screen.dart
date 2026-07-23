import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/ai_service.dart';
import '../services/memory_service.dart';
import '../utils/method_channel_helper.dart';

const Color deepSpaceBlue = Color(0xFF0A0A1A);
const Color starGold = Color(0xFFFFD700);
const Color glassWhite = Color(0x12FFFFFF);
const Color glassBorder = Color(0x1AFFFFFF);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0x8AFFFFFF);
const Color codeBg = Color(0x1AFFFFFF);

class ChatScreen extends StatefulWidget {
  final String? initialMessage;
  final bool startVoice;
  const ChatScreen({super.key, this.initialMessage, this.startVoice = false});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;
  bool _isListening = false;
  final MethodChannelHelper _channel = MethodChannelHelper();

  @override
  void initState() {
    super.initState();
    if (widget.startVoice) {
      // 自动触发语音输入
      Future.delayed(Duration.zero, _startVoiceInput);
    } else if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _controller.text = widget.initialMessage!;
      Future.delayed(Duration.zero, _sendMessage);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
    });

    _controller.clear();
    _scrollToBottom();

    // 创建 AI 流式消息占位
    final aiMsg = ChatMessage(
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: true,
    );
    setState(() => _messages.add(aiMsg));

    String fullContent = '';
    try {
      await for (final chunk in AiService.instance.sendMessageStream(text)) {
        fullContent += chunk;
        final index = _messages.length - 1;
        if (index >= 0) {
          setState(() {
            _messages[index] = ChatMessage(
              content: fullContent,
              isUser: false,
              timestamp: aiMsg.timestamp,
              isStreaming: true,
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      fullContent = 'AI 调用失败: $e';
    }

    if (_messages.isNotEmpty) {
      final index = _messages.length - 1;
      setState(() {
        _messages[index] = ChatMessage(
          content: fullContent,
          isUser: false,
          timestamp: aiMsg.timestamp,
          isStreaming: false,
        );
        _isProcessing = false;
      });
    }

    _scrollToBottom();
    await _saveConversation(text, fullContent);
  }

  Future<void> _saveConversation(String userMessage, String aiResponse) async {
    final memory = MemoryService.instance;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final time = DateTime.now().toIso8601String().split('T')[1].split('.')[0];

    final content = '''
## [$time]

**用户**: $userMessage

**AI**: $aiResponse

''';

    await memory.append('conversations/$today', content);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startVoiceInput() async {
    setState(() => _isListening = true);
    final result = await _channel.execCommand(
      'am broadcast -a com.tianshu.SPEECH_RECOGNITION'
    );
    final text = result['stdout']?.toString().trim() ?? '';
    if (text.isNotEmpty) {
      _controller.text = text;
      _sendMessage();
    }
    setState(() => _isListening = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepSpaceBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('对话', style: TextStyle(color: textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: textSecondary),
            onPressed: () {
              setState(() => _messages.clear());
              AiService.instance.clearHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, size: 64, color: starGold.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text('天枢', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          const Text('输入消息开始对话', style: TextStyle(fontSize: 14, color: textSecondary)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickChip('今天天气怎么样'),
              _buildQuickChip('帮我截个屏'),
              _buildQuickChip('打开微信'),
              _buildQuickChip('读取通知'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: glassWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: glassBorder),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, color: textSecondary)),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          if (!isUser)
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 4),
              child: Text('天枢', style: TextStyle(fontSize: 12, color: starGold)),
            ),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser ? starGold.withOpacity(0.2) : glassWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: glassBorder),
            ),
            child: isUser
                ? Text(message.content, style: const TextStyle(fontSize: 14, color: textPrimary))
                : _buildMarkdownContent(message),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.isStreaming)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: SizedBox(
                    width: 12, height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: starGold),
                  ),
                ),
              Text(
                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 10, color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(ChatMessage message) {
    if (message.content.isEmpty && message.isStreaming) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: starGold)),
          SizedBox(width: 8),
          Text('思考中...', style: TextStyle(fontSize: 12, color: textSecondary)),
        ],
      );
    }
    return MarkdownBody(
      data: message.content,
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(fontSize: 14, color: textPrimary),
        h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: starGold),
        h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: starGold),
        h3: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: starGold),
        code: const TextStyle(fontSize: 12, color: Color(0xFF50E3C2), backgroundColor: codeBg),
        codeblockDecoration: BoxDecoration(
          color: codeBg,
          borderRadius: BorderRadius.circular(8),
        ),
        blockquoteDecoration: BoxDecoration(
          color: starGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: starGold, width: 3)),
        ),
        listBullet: const TextStyle(color: starGold),
        strong: const TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
        em: const TextStyle(fontStyle: FontStyle.italic, color: textSecondary),
        a: const TextStyle(color: starGold, decoration: TextDecoration.underline),
      ),
      onTapLink: (text, href, title) {
        if (href != null) {
          _channel.execCommand('am start -a android.intent.action.VIEW -d "$href"');
        }
      },
    );
  }

  /// Uiverse 风格渐变发光发送按钮
  /// indigo → pink → yellow 渐变外发光 + 深灰底
  Widget _buildNeonSendButton() {
    return SizedBox(
      width: 44, height: 44,
      child: Stack(
        children: [
          // 外层发光光晕
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFFACC15)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isProcessing
                        ? Colors.grey.withOpacity(0.3)
                        : const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          // 按钮主体
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _isProcessing ? Colors.grey.shade700 : const Color(0xFF111827),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _isProcessing
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF9CA3AF),
                      ),
                    )
                  : const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: deepSpaceBlue,
        border: Border(top: BorderSide(color: glassBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            GestureDetector(
              onLongPress: _isListening ? null : _startVoiceInput,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: _isListening ? starGold.withOpacity(0.3) : glassWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isListening ? starGold : glassBorder),
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: _isListening ? starGold : textSecondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: glassWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: glassBorder),
                ),
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(color: textPrimary),
                  decoration: const InputDecoration(
                    hintText: '输入消息...',
                    hintStyle: TextStyle(color: textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _isProcessing ? null : _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Uiverse 风格渐变发光发送按钮
            GestureDetector(
              onTap: _isProcessing ? null : _sendMessage,
              child: _buildNeonSendButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isStreaming;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isStreaming = false,
  });
}
