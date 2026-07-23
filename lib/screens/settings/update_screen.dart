import 'dart:ui';
import 'package:flutter/material.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 检查更新界面
class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isChecking = false;
  String _status = '';
  bool _hasUpdate = false;

  @override
  void initState() {
    super.initState();
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    setState(() {
      _isChecking = true;
      _status = '正在检查更新...';
    });

    try {
      // 模拟检查更新
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _hasUpdate = false;
        _status = '已是最新版本';
      });
    } catch (e) {
      setState(() {
        _status = '检查失败: $e';
      });
    } finally {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('检查更新', style: TextStyle(color: _text)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 版本图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Text('天枢', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _bg)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('天枢 AI 助手', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: _text)),
            const SizedBox(height: 8),
            const Text('v1.0.0+1', style: TextStyle(fontSize: 14, color: _text2)),
            const SizedBox(height: 32),
            // 状态
            if (_isChecking)
              const CircularProgressIndicator(color: _gold)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _hasUpdate ? _gold.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _hasUpdate ? _gold : Colors.green),
                ),
                child: Text(_status, style: TextStyle(color: _hasUpdate ? _gold : Colors.green, fontSize: 14)),
              ),
            const SizedBox(height: 24),
            // 检查按钮
            GestureDetector(
              onTap: _isChecking ? null : _checkUpdate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _gold),
                ),
                child: const Text('重新检查', style: TextStyle(color: _gold, fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
