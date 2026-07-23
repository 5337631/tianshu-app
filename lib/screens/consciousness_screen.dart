import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/consciousness_service.dart';

const Color deepSpaceBlue = Color(0xFF0A0A1A);
const Color starGold = Color(0xFFFFD700);
const Color glassWhite = Color(0x12FFFFFF);
const Color glassBorder = Color(0x1AFFFFFF);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0x8AFFFFFF);

enum ConsciousnessState { empty, gathering, distilling, ready }

/// 意识页面 - 7维度 + Soul Archive 设计
class ConsciousnessScreen extends StatefulWidget {
  const ConsciousnessScreen({super.key});
  @override
  State<ConsciousnessScreen> createState() => _ConsciousnessScreenState();
}

class _ConsciousnessScreenState extends State<ConsciousnessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _distillController;
  late Animation<double> _distillAnimation;
  final ConsciousnessService _service = ConsciousnessService.instance;
  ConsciousnessState _state = ConsciousnessState.empty;
  double _maturity = 0.0;

  @override
  void initState() {
    super.initState();
    _distillController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _distillAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _distillController, curve: Curves.easeInOut),
    );
    _loadState();
  }

  @override
  void dispose() {
    _distillController.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    await _service.init();
    setState(() {
      _maturity = _service.calculateMaturity();
      if (_service.uploadedCategories.isNotEmpty) {
        _state = _service.profile != null
            ? ConsciousnessState.ready
            : ConsciousnessState.gathering;
      } else {
        _state = ConsciousnessState.empty;
      }
    });
  }

  Future<void> _startDistillation() async {
    if (_service.uploadedCategories.isEmpty) return;
    setState(() => _state = ConsciousnessState.distilling);
    _distillController.repeat();
    final success = await _service.distill();
    _distillController.stop();
    _distillController.reset();
    setState(() {
      _maturity = _service.calculateMaturity();
      _state = success ? ConsciousnessState.ready : ConsciousnessState.gathering;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? '蒸馏完成' : '蒸馏失败'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        _buildHeader(),
        Expanded(child: _buildBody()),
        _buildBottomActions(),
      ]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('意识', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary)),
              SizedBox(height: 4),
              Text('蒸馏你的数字意识', style: TextStyle(fontSize: 14, color: textSecondary)),
            ],
          ),
          _buildMaturityIndicator(),
        ],
      ),
    );
  }

  Widget _buildMaturityIndicator() {
    return SizedBox(
      width: 60, height: 60,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 60, height: 60, child: CircularProgressIndicator(
          value: _maturity / 100, strokeWidth: 4,
          backgroundColor: glassBorder,
          valueColor: AlwaysStoppedAnimation(starGold),
        )),
        Text('${_maturity.toInt()}%', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: starGold)),
      ]),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case ConsciousnessState.empty: return _buildEmptyState();
      case ConsciousnessState.gathering: return _buildGatheringState();
      case ConsciousnessState.distilling: return _buildDistillingState();
      case ConsciousnessState.ready: return _buildReadyState();
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: LinearGradient(colors: [starGold.withOpacity(0.3), starGold.withOpacity(0.1)]),
              border: Border.all(color: starGold.withOpacity(0.3), width: 2),
            ),
            child: Icon(Icons.psychology, size: 48, color: starGold.withOpacity(0.8)),
          ),
          const SizedBox(height: 24),
          const Text('创建你的数字意识', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 12),
          const Text('上传个人信息，AI 蒸馏出 7 维人格档案', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          _buildGlassButton(text: '开始上传', icon: Icons.upload, onTap: _showUploadDialog),
        ]),
      ),
    );
  }

  Widget _buildGatheringState() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildProgressCard(),
      const SizedBox(height: 16),
      _buildDimensionGrid(),
      const SizedBox(height: 16),
      _buildExtraCategories(),
    ]);
  }

  Widget _buildProgressCard() {
    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
          child: Column(children: [
            Row(children: [
              const Icon(Icons.info_outline, color: starGold, size: 20),
              const SizedBox(width: 8),
              Text('已收集 ${_service.uploadedCategories.length} 类信息', style: const TextStyle(color: textPrimary)),
            ]),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: _maturity / 100, backgroundColor: glassBorder, valueColor: AlwaysStoppedAnimation(starGold)),
            const SizedBox(height: 8),
            const Text('信息越完整，蒸馏出的意识越精准', style: TextStyle(fontSize: 12, color: textSecondary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildDimensionGrid() {
    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('7 维人格', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 12),
            ...ConsciousnessDimension.values.map((dim) {
              final isUploaded = _service.uploadedCategories.contains(dim.label);
              final entries = _service.profile?.dimensions[dim.label] ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  Container(width: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUploaded ? starGold.withOpacity(0.1) : glassWhite,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${dim.label} ${(dim.weight * 100).toInt()}%',
                      style: TextStyle(fontSize: 11, color: isUploaded ? starGold : textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: entries.isEmpty
                    ? const Text('未录入', style: TextStyle(fontSize: 12, color: textSecondary))
                    : Text(entries.first.value, style: const TextStyle(fontSize: 12, color: textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                  if (isUploaded) const Icon(Icons.check_circle, size: 16, color: Colors.green)
                  else Icon(Icons.add_circle_outline, size: 16, color: textSecondary),
                ]),
              );
            }),
          ]),
        ),
      ),
    );
  }

  Widget _buildExtraCategories() {
    final extras = [('人际关系', Icons.people), ('生活经历', Icons.history),
                    ('专业技能', Icons.workspace_premium), ('情感偏好', Icons.favorite_border)];
    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('补充信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 12),
            ...extras.map((e) {
              final isUploaded = _service.uploadedCategories.contains(e.$1);
              return Column(children: [
                ListTile(
                  leading: Icon(e.$2, size: 20, color: isUploaded ? Colors.green : starGold),
                  title: Text(e.$1, style: TextStyle(color: isUploaded ? Colors.green : textPrimary, fontSize: 14)),
                  trailing: isUploaded ? const Icon(Icons.check_circle, color: Colors.green) : const Icon(Icons.add, color: textSecondary),
                  onTap: isUploaded ? null : () => _showInputSheet(e.$1),
                  contentPadding: EdgeInsets.zero,
                ),
                if (e != extras.last) const Divider(color: glassBorder, height: 1),
              ]);
            }),
          ]),
        ),
      ),
    );
  }

  Widget _buildDistillingState() {
    return Center(
      child: AnimatedBuilder(animation: _distillAnimation, builder: (context, child) {
        return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 150, height: 150,
            child: Stack(alignment: Alignment.center, children: [
              Transform.rotate(angle: _distillAnimation.value * 3.14 * 2,
                child: Container(width: 150, height: 150,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    border: Border.all(color: starGold.withOpacity(0.3), width: 2)))),
              Transform.scale(scale: 0.8 + _distillAnimation.value * 0.4,
                child: Container(width: 80, height: 80,
                  decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [starGold.withOpacity(0.4), starGold.withOpacity(0.1)])),
                  child: const Icon(Icons.auto_awesome, color: starGold, size: 32))),
            ]),
          ),
          const SizedBox(height: 32),
          const Text('意识蒸馏中...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          const Text('AI 正在分析你的 7 维人格特征', style: TextStyle(fontSize: 14, color: textSecondary)),
        ]);
      }),
    );
  }

  Widget _buildReadyState() {
    return ListView(padding: const EdgeInsets.all(16), children: [
      _buildConsciousnessCard(),
      const SizedBox(height: 16),
      _buildDimensionGrid(),
      const SizedBox(height: 16),
      _buildExtraCategories(),
      const SizedBox(height: 16),
      _buildActionsCard(),
    ]);
  }

  Widget _buildConsciousnessCard() {
    final profile = _service.profile;
    return ClipRRect(borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: starGold.withOpacity(0.3), width: 1)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [starGold, Color(0xFFFFA500)]),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.psychology, color: deepSpaceBlue)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('数字意识', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                Text('已蒸馏', style: TextStyle(fontSize: 12, color: starGold)),
              ])),
              IconButton(icon: const Icon(Icons.refresh, color: textSecondary), onPressed: _startDistillation),
            ]),
            const SizedBox(height: 16),
            if (profile != null) ...[
              Text('共 ${profile.totalEntries} 条信息，${profile.conflictCount} 条冲突',
                style: const TextStyle(fontSize: 12, color: textSecondary)),
              const SizedBox(height: 8),
              Text('最后蒸馏: ${_formatDate(profile.lastDistilled)}',
                style: const TextStyle(fontSize: 12, color: textSecondary)),
            ],
          ]),
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('操作', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            const SizedBox(height: 12),
            _buildActionItem(Icons.chat, '灵魂对话', '用你的数字意识对话', _showSoulChat),
            _buildActionItem(Icons.description, '灵魂报告', '生成 HTML 人格画像', _showSoulReport),
            _buildActionItem(Icons.auto_awesome, '模式蒸馏', '从反思中提炼行为模式', _showDistillPatterns),
            _buildActionItem(Icons.refresh, '重新蒸馏', '更新意识档案', _startDistillation),
            _buildActionItem(Icons.delete, '重置', '清除所有数据', _showResetDialog),
          ]),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: starGold, size: 20),
      title: Text(title, style: const TextStyle(color: textPrimary, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(color: textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: textSecondary, size: 20),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(child: _buildGlassButton(text: '上传信息', icon: Icons.upload, onTap: _showUploadDialog)),
        const SizedBox(width: 12),
        Expanded(child: _buildGoldButton(text: '开始蒸馏', icon: Icons.auto_awesome,
          onTap: _state == ConsciousnessState.distilling || _service.uploadedCategories.isEmpty ? null : _startDistillation)),
      ]),
    );
  }

  Widget _buildGlassButton({required String text, required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: glassBorder)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 18, color: textSecondary), const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, color: textPrimary)),
      ]),
    ));
  }

  Widget _buildGoldButton({required String text, required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: onTap != null ? [starGold, const Color(0xFFFFA500)] : [Colors.grey, Colors.grey]),
        borderRadius: BorderRadius.circular(12)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 18, color: deepSpaceBlue), const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: deepSpaceBlue)),
      ]),
    ));
  }

  void _showUploadDialog() {
    showModalBottomSheet(context: context, backgroundColor: deepSpaceBlue, isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (context, scrollController) => _buildUploadSheet(scrollController)));
  }

  Widget _buildUploadSheet(ScrollController scrollController) {
    final categories = [
      ('身份', '姓名、年龄、职业、所在地', Icons.person),
      ('性格', 'MBTI、特质、价值观、决策风格', Icons.psychology),
      ('语言', '口头禅、句式、幽默风格', Icons.record_voice_over),
      ('知识', '关注话题、立场、方法论', Icons.school),
      ('记忆', '重要事件、情感触发', Icons.event),
      ('工作流', '工具、技术栈、硬规则', Icons.work),
      ('抱负', '目标、项目、想学技能', Icons.flag),
    ];

    return Column(children: [
      Padding(padding: const EdgeInsets.all(16),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('上传意识信息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          IconButton(icon: const Icon(Icons.close, color: textSecondary), onPressed: () => Navigator.pop(context)),
        ])),
      Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16),
        children: categories.map((cat) {
          final isUploaded = _service.uploadedCategories.contains(cat.$1);
          return GestureDetector(
            onTap: isUploaded ? null : () { Navigator.pop(context); _showInputSheet(cat.$1); },
            child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isUploaded ? Colors.green.withOpacity(0.5) : glassBorder)),
              child: Row(children: [
                Icon(cat.$3, color: isUploaded ? Colors.green : starGold, size: 24),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${cat.$1} (权重 ${(ConsciousnessDimension.values.firstWhere((d) => d.label == cat.$1, orElse: () => ConsciousnessDimension.identity).weight * 100).toInt()}%)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: isUploaded ? Colors.green : textPrimary)),
                  const SizedBox(height: 4),
                  Text(cat.$2, style: const TextStyle(fontSize: 12, color: textSecondary)),
                ])),
                if (isUploaded) const Icon(Icons.check_circle, color: Colors.green)
                else const Icon(Icons.chevron_right, color: textSecondary),
              ]),
            ),
          );
        }).toList())),
    ]);
  }

  void _showInputSheet(String category) {
    final controller = TextEditingController(text: _service.getRawInput(category) ?? '');
    showModalBottomSheet(context: context, backgroundColor: deepSpaceBlue, isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('输入$category', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Text('用户明示的信息置信度最高，推断的次之', style: TextStyle(fontSize: 12, color: textSecondary)),
          const SizedBox(height: 16),
          TextField(controller: controller, maxLines: 5, style: const TextStyle(color: textPrimary),
            decoration: InputDecoration(
              hintText: '例如：我是一个软件工程师，理性决策者，喜欢用数据说话...',
              hintStyle: const TextStyle(color: textSecondary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: glassBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: glassBorder)),
              filled: true, fillColor: glassWhite)),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              if (controller.text.isNotEmpty) {
                await _service.saveInput(category, controller.text);
                Navigator.pop(context);
                await _loadState();
              }
            },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [starGold, Color(0xFFFFA500)]),
                borderRadius: BorderRadius.circular(12)),
              child: const Text('保存', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: deepSpaceBlue))),
          ),
        ]),
      ),
    );
  }

  /// 灵魂对话 - 展示角色扮演 prompt
  void _showSoulChat() async {
    final prompt = await _service.getRolePlayPrompt();
    if (!mounted) return;

    showModalBottomSheet(context: context, backgroundColor: deepSpaceBlue, isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(initialChildSize: 0.8, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (context, scrollController) => Column(children: [
          Padding(padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('灵魂对话', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              IconButton(icon: const Icon(Icons.close, color: textSecondary), onPressed: () => Navigator.pop(context)),
            ])),
          Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: glassBorder)),
              child: SelectableText(prompt.isEmpty ? '请先上传信息并蒸馏' : prompt,
                style: const TextStyle(fontSize: 13, color: textPrimary, height: 1.6))),
            const SizedBox(height: 16),
            const Text('此 prompt 可用于任何 AI 的角色扮演', style: TextStyle(fontSize: 12, color: textSecondary)),
          ])),
        ]),
      ),
    );
  }

  /// 灵魂报告 - 展示人格画像
  void _showSoulReport() async {
    final reportData = _service.getReportData();
    if (!mounted) return;

    showModalBottomSheet(context: context, backgroundColor: deepSpaceBlue, isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95, expand: false,
        builder: (context, scrollController) => Column(children: [
          Padding(padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('灵魂报告', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              IconButton(icon: const Icon(Icons.close, color: textSecondary), onPressed: () => Navigator.pop(context)),
            ])),
          Expanded(child: reportData.isEmpty
            ? const Center(child: Text('请先蒸馏意识', style: TextStyle(color: textSecondary)))
            : ListView(controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
                // 总体数据
                _buildReportStats(reportData),
                const SizedBox(height: 16),
                // 7维雷达
                _buildReportDimensions(reportData),
                const SizedBox(height: 16),
                // 详细信息
                _buildReportDetails(),
              ])),
        ]),
      ),
    );
  }

  Widget _buildReportStats(Map<String, dynamic> data) {
    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: starGold.withOpacity(0.3))),
        child: Column(children: [
          const Text('总体概况', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildStatItem('${data['maturity']?.toInt() ?? 0}%', '成熟度'),
            _buildStatItem('${data['totalEntries'] ?? 0}', '信息条目'),
            _buildStatItem('${data['conflictCount'] ?? 0}', '待确认'),
          ]),
        ]),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: starGold)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: textSecondary)),
    ]);
  }

  Widget _buildReportDimensions(Map<String, dynamic> data) {
    final scores = data['dimensionScores'] as Map<String, double>? ?? {};
    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('7 维画像', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 16),
          ...ConsciousnessDimension.values.map((dim) {
            final score = scores[dim.label] ?? 0;
            return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${dim.label} (${(dim.weight * 100).toInt()}%)', style: const TextStyle(fontSize: 13, color: textPrimary)),
                Text('${score.toInt()} 分', style: const TextStyle(fontSize: 13, color: starGold)),
              ]),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: score / 100, backgroundColor: glassBorder, valueColor: AlwaysStoppedAnimation(starGold)),
            ]));
          }),
        ]),
      ),
    );
  }

  Widget _buildReportDetails() {
    final profile = _service.profile;
    if (profile == null) return const SizedBox.shrink();

    return ClipRRect(borderRadius: BorderRadius.circular(16),
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(16), border: Border.all(color: glassBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('详细信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 16),
          ...ConsciousnessDimension.values.map((dim) {
            final entries = profile.dimensions[dim.label] ?? [];
            if (entries.isEmpty) return const SizedBox.shrink();
            return Padding(padding: const EdgeInsets.only(bottom: 16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dim.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: starGold)),
              const SizedBox(height: 8),
              ...entries.take(5).map((e) => Padding(padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Icon(e.isConflict ? Icons.warning : Icons.check_circle,
                    size: 14, color: e.isConflict ? Colors.orange : Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.value, style: const TextStyle(fontSize: 13, color: textPrimary))),
                  Text('${(e.confidence * 100).toInt()}%', style: const TextStyle(fontSize: 11, color: textSecondary)),
                ]))),
            ]));
          }),
        ]),
      ),
    );
  }

  /// 模式蒸馏 - 从反思中提炼行为模式
  void _showDistillPatterns() async {
    showDialog(context: context, barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: starGold)));

    final result = await _service.distillPatterns();

    if (mounted) Navigator.pop(context); // 关闭 loading

    if (!mounted) return;

    showModalBottomSheet(context: context, backgroundColor: deepSpaceBlue, isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
        builder: (context, scrollController) => Column(children: [
          Padding(padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('行为模式', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              IconButton(icon: const Icon(Icons.close, color: textSecondary), onPressed: () => Navigator.pop(context)),
            ])),
          Expanded(child: ListView(controller: scrollController, padding: const EdgeInsets.symmetric(horizontal: 16), children: [
            Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: glassWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: glassBorder)),
              child: SelectableText(result.isEmpty ? '暂无数据，请先完成一些任务并进行反思' : result,
                style: const TextStyle(fontSize: 13, color: textPrimary, height: 1.6))),
          ])),
        ]),
      ),
    );
  }

  void _showResetDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: deepSpaceBlue,
      title: const Text('重置意识', style: TextStyle(color: textPrimary)),
      content: const Text('确定要清除所有意识数据吗？', style: TextStyle(color: textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: textSecondary))),
        TextButton(onPressed: () async {
          await _service.reset();
          Navigator.pop(context);
          await _loadState();
        }, child: const Text('确认', style: TextStyle(color: Colors.red))),
      ],
    ));
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
