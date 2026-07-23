import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/method_channel_helper.dart';
import '../services/termux_service.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);
const Color _green = Color(0xFF50E3C2);
const Color _red = Color(0xFFFF6B6B);
const Color _cyan = Color(0xFF00BCD4);
const Color _yellow = Color(0xFFFFD740);

/// 终端输出行
class TerminalLine {
  final String text;
  final TerminalLineType type;
  final DateTime timestamp;

  TerminalLine({
    required this.text,
    this.type = TerminalLineType.output,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

enum TerminalLineType {
  input,    // 用户输入的命令
  output,   // 命令输出
  error,    // 错误输出
  info,     // 系统信息
  success,  // 成功提示
}

/// 终端界面
class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final MethodChannelHelper _channel = MethodChannelHelper();

  final List<TerminalLine> _lines = [];
  final List<String> _commandHistory = [];
  int _historyIndex = -1;
  String _currentDirectory = '~';
  bool _isExecuting = false;
  bool _useTermux = false; // 是否使用 Termux SSH

  @override
  void initState() {
    super.initState();
    // 检测 Termux 是否可用
    _useTermux = TermuxService.instance.isTermuxAvailable;
    _addLine('天枢终端 v1.0', TerminalLineType.info);
    _addLine('执行环境: ${_useTermux ? "Termux SSH" : "内置 Shell"}', TerminalLineType.info);
    _addLine('输入命令执行 Shell 操作，支持 ↑↓ 历史记录', TerminalLineType.info);
    _addLine('─' * 40, TerminalLineType.info);
    _updatePrompt();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addLine(String text, TerminalLineType type) {
    setState(() {
      _lines.add(TerminalLine(text: text, type: type));
    });
    _scrollToBottom();
  }

  void _updatePrompt() {
    _inputController.text = '$_currentDirectory \$ ';
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
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

  Future<void> _executeCommand(String fullInput) async {
    // 提取实际命令（去掉提示符）
    final prompt = '$_currentDirectory \$ ';
    String command = fullInput.startsWith(prompt)
        ? fullInput.substring(prompt.length)
        : fullInput;

    if (command.trim().isEmpty) return;

    // 添加到历史
    _commandHistory.add(command);
    _historyIndex = _commandHistory.length;

    // 显示输入的命令
    _addLine('$_currentDirectory \$ $command', TerminalLineType.input);

    // 处理特殊命令
    if (await _handleSpecialCommand(command)) return;

    // 执行 Shell 命令
    setState(() => _isExecuting = true);

    try {
      Map<String, dynamic> result;
      if (_useTermux) {
        // 使用 TermuxService 执行（自动路由 SSH 或 Shell）
        result = await TermuxService.instance.exec(command);
      } else {
        // 使用内置 Shell
        result = await _channel.execCommand(command);
      }

      final stdout = result['stdout']?.toString() ?? '';
      final stderr = result['stderr']?.toString() ?? '';
      final exitCode = result['exitCode'] ?? -1;
      final via = result['via'] ?? 'shell';

      if (stdout.isNotEmpty) {
        _addLine(stdout, TerminalLineType.output);
      }
      if (stderr.isNotEmpty) {
        _addLine(stderr, TerminalLineType.error);
      }
      if (exitCode != 0 && stdout.isEmpty && stderr.isEmpty) {
        _addLine('命令执行失败 (exit code: $exitCode)', TerminalLineType.error);
      }
    } catch (e) {
      _addLine('执行错误: $e', TerminalLineType.error);
    } finally {
      setState(() => _isExecuting = false);
    }

    _updatePrompt();
    _focusNode.requestFocus();
  }

  Future<bool> _handleSpecialCommand(String command) async {
    final parts = command.trim().split(' ');
    final cmd = parts[0].toLowerCase();

    switch (cmd) {
      case 'clear':
      case 'cls':
        setState(() => _lines.clear());
        _addLine('终端已清空', TerminalLineType.info);
        return true;

      case 'help':
        _addLine(_getHelpText(), TerminalLineType.info);
        return true;

      case 'history':
        _addLine(_getHistoryText(), TerminalLineType.info);
        return true;

      case 'cd':
        if (parts.length > 1) {
          await _changeDirectory(parts[1]);
        } else {
          _currentDirectory = '~';
          _addLine('已切换到主目录', TerminalLineType.success);
        }
        _updatePrompt();
        return true;

      case 'pwd':
        _addLine(_currentDirectory, TerminalLineType.output);
        return true;

      case 'exit':
        Navigator.pop(context);
        return true;
    }

    return false;
  }

  Future<void> _changeDirectory(String path) async {
    String targetPath;
    if (path == '~' || path == '/data/data/com.termux/files/home') {
      targetPath = '~';
    } else if (path == '..') {
      if (_currentDirectory == '~') {
        targetPath = '/';
      } else {
        final parts = _currentDirectory.split('/');
        parts.removeLast();
        targetPath = parts.join('/') ;
        if (targetPath.isEmpty) targetPath = '/';
      }
    } else if (path.startsWith('/')) {
      targetPath = path;
    } else {
      if (_currentDirectory == '~') {
        targetPath = '~/$_currentDirectory/$path'.replaceAll('//', '/');
      } else {
        targetPath = '$_currentDirectory/$path';
      }
    }

    // 验证目录是否存在
    final result = await _channel.execCommand('cd "$targetPath" && pwd');
    final newDir = result['stdout']?.toString().trim();
    if (newDir != null && newDir.isNotEmpty && (result['exitCode'] ?? -1) == 0) {
      _currentDirectory = newDir;
      _addLine('已切换到 $newDir', TerminalLineType.success);
    } else {
      _addLine('目录不存在: $path', TerminalLineType.error);
    }
  }

  String _getHelpText() {
    return '''
可用命令:
  clear / cls  - 清空终端
  help         - 显示帮助
  history      - 显示命令历史
  cd <dir>     - 切换目录
  pwd          - 显示当前目录
  exit         - 退出终端
  
执行环境:
  ${_useTermux ? "Termux SSH" : "内置 Shell"} (点击右上角切换)

快捷操作:
  ↑ / ↓        - 浏览命令历史
  长按命令      - 复制到剪贴板
  双击输出      - 全选复制''';
  }

  String _getHistoryText() {
    if (_commandHistory.isEmpty) return '暂无历史命令';
    final buffer = StringBuffer('命令历史 (${_commandHistory.length} 条):\n');
    for (int i = 0; i < _commandHistory.length; i++) {
      buffer.writeln('  ${i + 1}  ${_commandHistory[i]}');
    }
    return buffer.toString();
  }

  void _navigateHistory(int direction) {
    if (_commandHistory.isEmpty) return;

    _historyIndex += direction;
    if (_historyIndex < 0) _historyIndex = 0;
    if (_historyIndex >= _commandHistory.length) {
      _historyIndex = _commandHistory.length;
      _updatePrompt();
      return;
    }

    final prompt = '$_currentDirectory \$ ';
    _inputController.text = '$prompt${_commandHistory[_historyIndex]}';
    _inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: _inputController.text.length),
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已复制到剪贴板'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.terminal, color: _green, size: 20),
            const SizedBox(width: 8),
            const Text('终端', style: TextStyle(color: _text)),
          ],
        ),
        actions: [
          // Termux/Shell 切换
          if (TermuxService.instance.isTermuxAvailable)
            GestureDetector(
              onTap: () {
                setState(() => _useTermux = !_useTermux);
                _addLine('切换到 ${_useTermux ? "Termux SSH" : "内置 Shell"} 模式', TerminalLineType.info);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _useTermux ? _green.withOpacity(0.2) : _text2.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _useTermux ? _green : _text2,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _useTermux ? Icons.terminal : Icons.code,
                      color: _useTermux ? _green : _text2,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _useTermux ? 'Termux' : 'Shell',
                      style: TextStyle(
                        fontSize: 12,
                        color: _useTermux ? _green : _text2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // 清空按钮
          IconButton(
            icon: const Icon(Icons.delete_outline, color: _text2, size: 20),
            onPressed: () {
              setState(() => _lines.clear());
              _addLine('终端已清空', TerminalLineType.info);
            },
          ),
          // 复制全部
          IconButton(
            icon: const Icon(Icons.copy, color: _text2, size: 20),
            onPressed: () {
              final allOutput = _lines
                  .where((l) => l.type == TerminalLineType.output)
                  .map((l) => l.text)
                  .join('\n');
              _copyToClipboard(allOutput);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 终端输出区域
          Expanded(
            child: GestureDetector(
              onTap: () => _focusNode.requestFocus(),
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _lines.length,
                  itemBuilder: (context, index) => _buildLine(_lines[index]),
                ),
              ),
            ),
          ),

          // 输入区域
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLine(TerminalLine line) {
    Color textColor;
    switch (line.type) {
      case TerminalLineType.input:
        textColor = _green;
        break;
      case TerminalLineType.output:
        textColor = _text;
        break;
      case TerminalLineType.error:
        textColor = _red;
        break;
      case TerminalLineType.info:
        textColor = _cyan;
        break;
      case TerminalLineType.success:
        textColor = _gold;
        break;
    }

    return GestureDetector(
      onLongPress: () => _copyToClipboard(line.text),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: SelectableText(
          line.text,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: textColor,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // 执行按钮
            GestureDetector(
              onTap: _isExecuting ? null : () {
                _executeCommand(_inputController.text);
                _inputController.clear();
                _updatePrompt();
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _isExecuting ? _text2.withOpacity(0.2) : _green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isExecuting ? _text2 : _green,
                    width: 1,
                  ),
                ),
                child: _isExecuting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _text2,
                        ),
                      )
                    : Icon(Icons.play_arrow, color: _green, size: 20),
              ),
            ),
            const SizedBox(width: 8),

            // 输入框
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _glass,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _border),
                ),
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                        _navigateHistory(-1);
                      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                        _navigateHistory(1);
                      }
                    }
                  },
                  child: TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      color: _text,
                    ),
                    decoration: InputDecoration(
                      hintText: '输入命令...',
                      hintStyle: TextStyle(color: _text2),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onSubmitted: (value) {
                      _executeCommand(value);
                      _inputController.clear();
                      _updatePrompt();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
