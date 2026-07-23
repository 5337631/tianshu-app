import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/memory_service.dart';
import '../widgets/uiverse_effects.dart';
import 'graph_visualizer.dart';

const Color bgDeep = Color(0xFF0A0A1A);
const Color bgMid = Color(0xFF12122A);
const Color bgSurface = Color(0xFF1A1A3E);
const Color accentCyan = Color(0xFF00E5FF);
const Color accentPurple = Color(0xFFB388FF);
const Color accentGold = Color(0xFFFFD700);
const Color glassBg = Color(0x12FFFFFF);
const Color glassBorder = Color(0x1AFFFFFF);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0x8AFFFFFF);
const Color textTertiary = Color(0x4DFFFFFF);

/// 增强版探索页面 - 对标HermesApp
class ExploreScreenEnhanced extends StatefulWidget {
  const ExploreScreenEnhanced({super.key});

  @override
  State<ExploreScreenEnhanced> createState() => _ExploreScreenEnhancedState();
}

class _ExploreScreenEnhancedState extends State<ExploreScreenEnhanced> {
  final TextEditingController _searchController = TextEditingController();
  final GraphVisualizerController _graphController = GraphVisualizerController();
  List<MemoryEntry> _searchResults = [];
  bool _isSearching = false;
  GraphData? _graphData;
  String? _selectedNodeId;
  String? _selectedCategory;
  int _selectedTab = 0; // 0=图谱, 1=列表, 2=时间线
  final List<_StarParticle> _stars = [];

  // 分类列表
  final List<Map<String, dynamic>> _categories = [
    {'name': '全部', 'icon': Icons.all_inclusive, 'color': accentCyan},
    {'name': 'conversations', 'icon': Icons.chat, 'color': Colors.green},
    {'name': 'knowledge', 'icon': Icons.book, 'color': Colors.blue},
    {'name': 'user', 'icon': Icons.person, 'color': Colors.orange},
    {'name': 'notes', 'icon': Icons.note, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllMemories();
    _initStars();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _initStars() {
    final rng = Random(42);
    for (int i = 0; i < 40; i++) {
      _stars.add(_StarParticle(
        x: rng.nextDouble(), y: rng.nextDouble(),
        size: 0.5 + rng.nextDouble() * 1.5,
        opacity: 0.2 + rng.nextDouble() * 0.5,
        twinkleSpeed: 0.5 + rng.nextDouble() * 2.0,
        twinklePhase: rng.nextDouble() * 2 * pi,
      ));
    }
  }

  Future<void> _loadAllMemories() async {
    final results = await MemoryService.instance.search('', limit: 50);
    if (results.isNotEmpty && mounted) {
      setState(() {
        _searchResults = results;
        _graphData = _buildEnhancedGraph(results);
      });
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) { _loadAllMemories(); return; }
    setState(() => _isSearching = true);
    final results = await MemoryService.instance.search(query, limit: 20);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _graphData = results.isNotEmpty ? _buildEnhancedGraph(results) : null;
        _selectedNodeId = null;
      });
    }
  }

  void _filterByCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedNodeId = null;
    });
    // 重新加载并过滤
    _loadAllMemories();
  }

  void _onNodeClick(GraphNode node) {
    setState(() => _selectedNodeId = _selectedNodeId == node.id ? null : node.id);
    _graphController.firePulse(node.id);
  }

  /// 构建增强版图谱（节点大小基于关联度）
  GraphData _buildEnhancedGraph(List<MemoryEntry> entries) {
    if (entries.isEmpty) return GraphData(nodes: [], edges: []);
    
    const nodeColors = [
      Color(0xFF6C5CE7), Color(0xFF00B894), Color(0xFFFD79A8),
      Color(0xFF0984E3), Color(0xFFFDCB6E), Color(0xFFE17055),
      Color(0xFF00CEC9), Color(0xFFA29BFE),
    ];

    final nodeMap = <String, GraphNode>{};
    int edgeId = 0;
    final categories = <String>{};
    
    for (final entry in entries) {
      final parts = entry.path.split('/');
      if (parts.length >= 2) categories.add(parts[0]);
      categories.add(entry.path);
    }

    int ci = 0;
    for (final cat in categories) {
      // 计算节点重要性（基于关联度）
      final relevance = entries
          .where((e) => e.path.startsWith(cat))
          .fold(0.0, (sum, e) => sum + e.relevance);
      
      nodeMap[cat] = GraphNode(
        id: cat,
        label: cat,
        color: nodeColors[ci % nodeColors.length],
      );
      ci++;
    }

    final edges = <GraphEdge>[];
    for (final entry in entries) {
      final parts = entry.path.split('/');
      if (parts.length >= 2) {
        edges.add(GraphEdge(
          id: edgeId++,
          sourceId: parts[0],
          targetId: entry.path,
          weight: entry.relevance,
          isCrossFolderLink: parts.length > 2,
        ));
      }
    }
    
    return GraphData(nodes: nodeMap.values.toList(), edges: edges);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [bgDeep, bgMid, bgSurface, bgMid],
          stops: [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: SafeArea(child: Column(children: [
        _buildHeader(),
        _buildSearchBar(),
        _buildCategoryFilter(),
        _buildTabBar(),
        Expanded(child: _buildContent()),
      ])),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [accentCyan, accentPurple]),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [BoxShadow(color: accentCyan.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('记忆图谱', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: 0.5)),
          SizedBox(height: 2),
          Text('探索你的记忆网络', style: TextStyle(fontSize: 12, color: textTertiary)),
        ]),
        const Spacer(),
        if (_graphData != null)
          _buildStatBadge('${_graphData!.nodes.length}', '节点'),
      ]),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: glassBg, borderRadius: BorderRadius.circular(8), border: Border.all(color: glassBorder, width: 0.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: accentCyan)),
            const SizedBox(width: 3),
            Text(label, style: const TextStyle(fontSize: 10, color: textTertiary)),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderRadius: 16,
        child: TextField(
          controller: _searchController,
          onChanged: _search,
          style: const TextStyle(color: textPrimary, fontSize: 15),
          decoration: InputDecoration(
            hintText: '搜索记忆，图谱实时联动...',
            hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.search_rounded, color: textTertiary, size: 22),
            ),
            suffixIcon: _isSearching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentCyan)),
                  )
                : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, color: textTertiary, size: 18),
                        onPressed: () { _searchController.clear(); _loadAllMemories(); },
                      )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['name'] || 
              (_selectedCategory == null && cat['name'] == '全部');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: LiquidGlassButton(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              borderRadius: 20,
              onTap: () => _filterByCategory(cat['name'] == '全部' ? null : cat['name']),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat['icon'] as IconData, size: 14, color: isSelected ? accentCyan : textSecondary),
                  const SizedBox(width: 6),
                  Text(cat['name'], style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? accentCyan : textSecondary,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTab(0, Icons.hub, '图谱'),
          _buildTab(1, Icons.list, '列表'),
          _buildTab(2, Icons.timeline, '时间线'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? accentCyan : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? accentCyan : textSecondary),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                fontSize: 13,
                color: isSelected ? accentCyan : textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_searchResults.isEmpty) {
      return _buildStarryEmptyState();
    }

    switch (_selectedTab) {
      case 0:
        return _buildGraphView();
      case 1:
        return _buildListView();
      case 2:
        return _buildTimelineView();
      default:
        return _buildGraphView();
    }
  }

  Widget _buildGraphView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [bgDeep.withOpacity(0.5), bgSurface.withOpacity(0.3)],
            ),
            border: Border.all(color: glassBorder, width: 1),
          ),
          child: Stack(children: [
            if (_graphData != null)
              GraphVisualizer(
                graph: _graphData!,
                selectedNodeId: _selectedNodeId,
                onNodeClick: _onNodeClick,
                controller: _graphController,
              ),
            Positioned(left: 12, bottom: 12, child: _buildGlassChip(
              '${_graphData?.nodes.length ?? 0} 节点 · ${_graphData?.edges.length ?? 0} 连接',
              Icons.hub_outlined, accentCyan,
            )),
            if (_selectedNodeId != null)
              Positioned(
                right: 12, bottom: 12,
                child: _buildNodeDetailPanel(),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _buildNodeDetailPanel() {
    final node = _graphData?.nodes.firstWhere(
      (n) => n.id == _selectedNodeId,
      orElse: () => GraphNode(id: '', label: ''),
    );
    
    if (node == null || node.id.isEmpty) return const SizedBox.shrink();

    // 查找相关记忆
    final relatedMemories = _searchResults
        .where((m) => m.path.contains(node.id))
        .take(3)
        .toList();

    return GlassCard(
      borderRadius: 12,
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: node.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(node.label, style: const TextStyle(
                    color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (relatedMemories.isNotEmpty) ...[
              const Text('相关记忆', style: TextStyle(color: textTertiary, fontSize: 10)),
              const SizedBox(height: 4),
              ...relatedMemories.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  m.content.length > 50 ? '${m.content.substring(0, 50)}...' : m.content,
                  style: const TextStyle(color: textSecondary, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSmallButton(Icons.delete_outline, Colors.red, () {
                  // 删除记忆
                }),
                const SizedBox(width: 8),
                _buildSmallButton(Icons.edit_outlined, accentCyan, () {
                  // 编辑记忆
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, size: 14, color: color),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final memory = _searchResults[index];
        return _buildMemoryListTile(memory);
      },
    );
  }

  Widget _buildMemoryListTile(MemoryEntry memory) {
    final parts = memory.path.split('/');
    final category = parts.length >= 2 ? parts[0] : 'unknown';
    
    return GlassCard(
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_getCategoryIcon(category), color: _getCategoryColor(category), size: 20),
        ),
        title: Text(
          parts.last.replaceAll('.md', ''),
          style: const TextStyle(color: textPrimary, fontSize: 14),
        ),
        subtitle: Text(
          memory.content.length > 60 ? '${memory.content.substring(0, 60)}...' : memory.content,
          style: const TextStyle(color: textSecondary, fontSize: 12),
          maxLines: 2,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: accentCyan.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${(memory.relevance * 100).toInt()}%',
            style: const TextStyle(color: accentCyan, fontSize: 10),
          ),
        ),
        onTap: () {
          // 查看记忆详情
        },
      ),
    );
  }

  Widget _buildTimelineView() {
    // 按路径分组
    final grouped = <String, List<MemoryEntry>>{};
    for (final memory in _searchResults) {
      final parts = memory.path.split('/');
      final category = parts.length >= 2 ? parts[0] : 'other';
      grouped.putIfAbsent(category, () => []).add(memory);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final memories = grouped[category]!;
        return _buildTimelineSection(category, memories);
      },
    );
  }

  Widget _buildTimelineSection(String category, List<MemoryEntry> memories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 12, height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getCategoryColor(category),
              ),
            ),
            const SizedBox(width: 8),
            Text(category, style: TextStyle(
              color: _getCategoryColor(category),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            )),
            const SizedBox(width: 8),
            Text('(${memories.length})', style: const TextStyle(color: textTertiary, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        ...memories.map((m) => _buildTimelineItem(m)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTimelineItem(MemoryEntry memory) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 2, height: 40,
            color: glassBorder,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  memory.content.length > 80 ? '${memory.content.substring(0, 80)}...' : memory.content,
                  style: const TextStyle(color: textSecondary, fontSize: 12),
                  maxLines: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'conversations': return Colors.green;
      case 'knowledge': return Colors.blue;
      case 'user': return Colors.orange;
      case 'notes': return Colors.purple;
      default: return accentCyan;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'conversations': return Icons.chat;
      case 'knowledge': return Icons.book;
      case 'user': return Icons.person;
      case 'notes': return Icons.note;
      default: return Icons.folder;
    }
  }

  Widget _buildGlassChip(String text, IconData icon, Color accent, {Color? bgColor, Color? borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor ?? Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor ?? glassBorder, width: 0.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: accent),
            const SizedBox(width: 5),
            Text(text, style: TextStyle(fontSize: 11, color: accent.withOpacity(0.8), fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }

  Widget _buildStarryEmptyState() {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        ...List.generate(_stars.length, (i) {
          final star = _stars[i];
          final now = DateTime.now().millisecondsSinceEpoch / 1000;
          final twinkle = 0.5 + 0.5 * sin(star.twinklePhase + star.twinkleSpeed * now);
          return Positioned(
            left: star.x * constraints.maxWidth,
            top: star.y * constraints.maxHeight,
            child: Container(
              width: star.size, height: star.size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(star.opacity * twinkle),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white.withOpacity(star.opacity * twinkle * 0.3), blurRadius: star.size * 2)],
              ),
            ),
          );
        }),
        Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 100, height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0x0000E5FF), Color(0x2600E5FF), Color(0x26B388FF), Color(0x00B388FF),
              ]),
            ),
            child: const Center(child: Icon(Icons.auto_awesome, size: 40, color: accentCyan)),
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(colors: [accentCyan, accentPurple]).createShader(bounds),
            child: const Text('记忆图谱', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
          ),
          const SizedBox(height: 12),
          const Text('搜索记忆，自动生成知识图谱', style: TextStyle(fontSize: 14, color: textTertiary)),
        ])),
      ]);
    });
  }
}

class _StarParticle {
  final double x, y, size, opacity, twinkleSpeed, twinklePhase;
  _StarParticle({required this.x, required this.y, required this.size, required this.opacity, required this.twinkleSpeed, required this.twinklePhase});
}
