import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/memory_service.dart';
import '../services/memory_service.dart';
import '../services/predict_service.dart';
import '../services/background_thinking_service.dart';
import '../utils/method_channel_helper.dart';
import '../widgets/uiverse_effects.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'explore_screen_enhanced.dart';
import 'consciousness_screen.dart';
import 'new_screen.dart';
import 'terminal_screen.dart';

// 颜色常量
const Color deepSpaceBlue = Color(0xFF0A0A1A);
const Color starGold = Color(0xFFFFD700);
const Color glassWhite = Color(0x12FFFFFF); // rgba(255,255,255,0.04)
const Color glassBorder = Color(0x1AFFFFFF); // rgba(255,255,255,0.08)
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0x8AFFFFFF); // rgba(255,255,255,0.35)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PredictService _predictService = PredictService.instance;
  final BackgroundThinkingService _thinkingService = BackgroundThinkingService.instance;
  final MethodChannelHelper _channel = MethodChannelHelper();
  int _selectedIndex = 0;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _predictService.refresh();
    // 每 30 秒刷新首页（内心独白会随时间变化）
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: deepSpaceBlue,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFloatingButton(),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const ConsciousnessScreen();
      case 2:
        return const ExploreScreenEnhanced();
      default:
        return _buildHomeTab();
    }
  }

  /// 首页标签 - 打开就有用
  Widget _buildHomeTab() {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // 顶部问候 + 设置按钮
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getDateText(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // 设置按钮
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: glassWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: glassBorder),
                      ),
                      child: const Icon(Icons.settings, color: textSecondary, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 预判区域 - 毛玻璃容器
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildPredictSection(),
            ),
          ),

          // 内心独白 - 在预判下方
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildInnerMonologue(),
            ),
          ),

          // 快捷操作
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildQuickActions(),
            ),
          ),

          // 最近活动
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: _buildRecentActivity(),
            ),
          ),
        ],
      ),
    );
  }

  /// 预判区域 - 流光边框 + 悬浮效果
  Widget _buildPredictSection() {
    final predictions = _predictService.predictions;

    if (predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ShimmerBorder(
      borderRadius: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(17),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: starGold, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '智能预判',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...predictions.take(3).map((p) => _buildPredictItem(p)),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictItem(PredictResult prediction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => _predictService.executeAction(prediction),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x08FFFFFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // 图标
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: starGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getIconForType(prediction.type),
                      color: starGold,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 内容
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prediction.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          prediction.description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // 置信度
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: starGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(prediction.confidence * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: starGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 内心独白区域 - 天枢的自我思考
  Widget _buildInnerMonologue() {
    final thoughts = _thinkingService.innerMonologue;

    if (thoughts.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      borderRadius: 20,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Color(0xFF7C4DFF), size: 20),
                SizedBox(width: 8),
                Text(
                  '内心独白',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                Spacer(),
                Text(
                  '天枢在想什么',
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...thoughts.take(3).map((m) => _buildMonologueItem(m)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonologueItem(MonologueEntry entry) {
    // 类型对应的颜色
    Color typeColor;
    IconData typeIcon;
    switch (entry.type) {
      case 'observation':
        typeColor = const Color(0xFF00BCD4);
        typeIcon = Icons.visibility;
        break;
      case 'reflection':
        typeColor = const Color(0xFFFF9800);
        typeIcon = Icons.autorenew;
        break;
      case 'insight':
        typeColor = const Color(0xFF7C4DFF);
        typeIcon = Icons.lightbulb_outline;
        break;
      case 'pattern':
        typeColor = const Color(0xFF4CAF50);
        typeIcon = Icons.timeline;
        break;
      default:
        typeColor = textSecondary;
        typeIcon = Icons.chat_bubble_outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 类型色标
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: typeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          // 内容区
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 类型标签 + 时间
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 10, color: typeColor),
                          const SizedBox(width: 3),
                          Text(
                            entry.typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeAgo(entry.timestamp),
                      style: const TextStyle(
                        fontSize: 10,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // 独白内容
                Text(
                  entry.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    return '${diff.inDays}天前';
  }

  /// 快捷操作 - 极简图标
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '快捷操作',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildQuickActionItem(
              icon: Icons.chat_bubble,
              label: '对话',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.mic,
              label: '语音',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(startVoice: true),
                  ),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.search,
              label: '搜索',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(initialMessage: '帮我搜索'),
                  ),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.terminal,
              label: '终端',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TerminalScreen()),
                );
              },
            ),
            _buildQuickActionItem(
              icon: Icons.edit_note,
              label: '速记',
              onTap: () => _showQuickNoteDialog(),
            ),
          ],
        ),
      ],
    );
  }

  /// 速记对话框
  void _showQuickNoteDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E3A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: glassBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: starGold, size: 20),
            SizedBox(width: 8),
            Text('速记', style: TextStyle(color: textPrimary, fontSize: 18)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          style: const TextStyle(color: textPrimary),
          decoration: const InputDecoration(
            hintText: '写点什么...',
            hintStyle: TextStyle(color: textSecondary),
            border: OutlineInputBorder(borderSide: BorderSide(color: glassBorder)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: starGold),
            ),
            filled: true,
            fillColor: glassWhite,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消', style: TextStyle(color: textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                MemoryService.instance.append(
                  '速记/${DateTime.now().toIso8601String().split('T')[0]}',
                  '- $text (${DateTime.now().toString().substring(11, 19)})\n',
                );
              }
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已保存速记'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Text('保存', style: TextStyle(color: starGold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          LiquidGlassButton(
            padding: const EdgeInsets.all(14),
            borderRadius: 16,
            onTap: onTap,
            child: Icon(
              icon,
              color: textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 最近活动
  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '最近活动',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: Text(
                '暂无活动记录',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 底部导航 - 4 Tab
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: deepSpaceBlue,
        border: Border(
          top: BorderSide(color: glassBorder, width: 1),
        ),
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, '首页'),
                _buildNavItem(1, Icons.psychology_outlined, Icons.psychology, '意识'),
                _buildNavItem(2, Icons.explore_outlined, Icons.explore, '探索'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? starGold : textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? starGold : textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 浮动按钮 - 渐变发光效果
  Widget? _buildFloatingButton() {
    if (_selectedIndex != 0) return null;

    return GradientGlowButton(
      label: '',
      glowRadius: 20,
      gradientColors: const [Color(0xFF6366F1), Color(0xFFEC4899), Color(0xFFFACC15)],
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatScreen(startVoice: true)),
        );
      },
    );
  }

  IconData _getIconForType(PredictType type) {
    switch (type) {
      case PredictType.time:
        return Icons.schedule;
      case PredictType.scene:
        return Icons.location_on;
      case PredictType.interest:
        return Icons.favorite;
      case PredictType.task:
        return Icons.task_alt;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '夜深了';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 22) return '晚上好';
    return '夜深了';
  }

  String _getDateText() {
    final now = DateTime.now();
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return '${now.month}月${now.day}日 ${weekdays[now.weekday - 1]}';
  }
}
