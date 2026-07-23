import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════
//  天枢 Uiverse 风格特效组件库
//  灵感来自 uiverse.io 的 CSS 特效
// ═══════════════════════════════════════════════════════════════

/// 渐变发光按钮
class GradientGlowButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final List<Color> gradientColors;
  final double glowRadius;

  const GradientGlowButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradientColors = const [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFFACC15)],
    this.glowRadius = 12,
  });

  @override
  State<GradientGlowButton> createState() => _GradientGlowButtonState();
}

class _GradientGlowButtonState extends State<GradientGlowButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors[0].withOpacity(0.4 * _glowAnimation.value),
                  blurRadius: widget.glowRadius * _glowAnimation.value,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: widget.gradientColors[1].withOpacity(0.3 * _glowAnimation.value),
                  blurRadius: widget.glowRadius * 1.5 * _glowAnimation.value,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 玻璃态卡片
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? backgroundColor;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 20,
    this.backgroundColor,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0x12FFFFFF),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 液态玻璃按钮 (HermesApp风格)
class LiquidGlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const LiquidGlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 渐变边框卡片
class GradientBorderCard extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double borderWidth;
  final double borderRadius;

  const GradientBorderCard({
    super.key,
    required this.child,
    this.gradientColors = const [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFFACC15)],
    this.borderWidth = 2,
    this.borderRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(borderWidth),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A1A),
          borderRadius: BorderRadius.circular(borderRadius - borderWidth),
        ),
        child: child,
      ),
    );
  }
}

/// 霓虹灯文字
class NeonText extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;

  const NeonText({
    super.key,
    required this.text,
    this.color = const Color(0xFF00D2FF),
    this.fontSize = 24,
    this.fontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        shadows: [
          Shadow(color: color, blurRadius: 10),
          Shadow(color: color, blurRadius: 20),
          Shadow(color: color, blurRadius: 40),
        ],
      ),
    );
  }
}

/// 悬浮动画卡片
class HoverCard extends StatefulWidget {
  final Widget child;
  final double liftHeight;
  final Duration duration;

  const HoverCard({
    super.key,
    required this.child,
    this.liftHeight = 8,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        transform: Matrix4.translationValues(0, _isHovered ? -widget.liftHeight : 0, 0),
        child: AnimatedContainer(
          duration: widget.duration,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isHovered ? 0.4 : 0.2),
                blurRadius: _isHovered ? 30 : 20,
                offset: Offset(0, _isHovered ? 16 : 8),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// 脉冲动画圆点
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  final Duration duration;

  const PulseDot({
    super.key,
    this.color = Colors.green,
    this.size = 12,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(1 - _controller.value),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.6 * (1 - _controller.value)),
                blurRadius: widget.size * _controller.value,
                spreadRadius: widget.size * 0.5 * _controller.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 流光效果边框
class ShimmerBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final Duration duration;

  const ShimmerBorder({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.duration = const Duration(milliseconds: 3000),
  });

  @override
  State<ShimmerBorder> createState() => _ShimmerBorderState();
}

class _ShimmerBorderState extends State<ShimmerBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: SweepGradient(
              colors: const [
                Color(0xFF6366F1),
                Color(0xFFEC4899),
                Color(0xFFFACC15),
                Color(0xFF50E3C2),
                Color(0xFF6366F1),
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value - 0.15,
                _controller.value,
                _controller.value + 0.15,
                _controller.value + 0.3,
              ].map((s) => s.clamp(0.0, 1.0)).toList(),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A1A),
              borderRadius: BorderRadius.circular(widget.borderRadius - 3),
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}
