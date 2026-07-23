import 'package:flutter/material.dart';
import '../widgets/uiverse_effects.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// Uiverse 特效演示页面
class EffectsDemoScreen extends StatelessWidget {
  const EffectsDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            NeonText(text: 'Uiverse', color: _gold, fontSize: 20),
            const SizedBox(width: 8),
            const Text('特效演示', style: TextStyle(color: _text, fontSize: 20)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 霓虹灯效果
          _buildSection('霓虹灯效果', [
            Center(
              child: NeonText(text: '天枢 AI', color: const Color(0xFF00D2FF), fontSize: 32),
            ),
            const SizedBox(height: 8),
            Center(
              child: NeonText(text: 'TIANSHU', color: _gold, fontSize: 24),
            ),
          ]),

          const SizedBox(height: 24),

          // 渐变发光按钮
          _buildSection('渐变发光按钮', [
            Center(
              child: GradientGlowButton(
                label: '点击体验',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('按钮点击！')),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // 玻璃态卡片
          _buildSection('玻璃态卡片', [
            GlassCard(
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: _gold, size: 24),
                        SizedBox(width: 8),
                        Text('智能助手', style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      '我是天枢，你的全能AI助手。我可以帮你搜索信息、控制手机、执行代码...',
                      style: TextStyle(color: _text2, fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // 液态玻璃按钮
          _buildSection('液态玻璃按钮', [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                LiquidGlassButton(
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('对话', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () {},
                ),
                LiquidGlassButton(
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('语音', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () {},
                ),
                LiquidGlassButton(
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.terminal, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('终端', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ]),

          const SizedBox(height: 24),

          // 渐变边框卡片
          _buildSection('渐变边框卡片', [
            GradientBorderCard(
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    '流光溢彩',
                    style: TextStyle(color: _text, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // 脉冲动画
          _buildSection('脉冲动画', [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const PulseDot(color: Colors.green, size: 16),
                const SizedBox(width: 24),
                const PulseDot(color: _gold, size: 16),
                const SizedBox(width: 24),
                const PulseDot(color: Colors.red, size: 16),
              ],
            ),
          ]),

          const SizedBox(height: 24),

          // 流光边框
          _buildSection('流光边框', [
            ShimmerBorder(
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Shimmer Effect',
                    style: TextStyle(color: _text, fontSize: 16),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // 悬浮卡片
          _buildSection('悬浮卡片', [
            HoverCard(
              child: GlassCard(
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      '悬停查看效果',
                      style: TextStyle(color: _text, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ),
          ]),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _text2,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
