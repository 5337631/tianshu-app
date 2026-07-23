import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/memory_service.dart';
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

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  final GraphVisualizerController _graphController = GraphVisualizerController();
  List<MemoryEntry> _searchResults = [];
  bool _isSearching = false;
  GraphData? _graphData;
  String? _selectedNodeId;
  final List<_StarParticle> _stars = [];

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
        _graphData = buildGraphFromMemoryEntries(results);
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
        _graphData = results.isNotEmpty ? buildGraphFromMemoryEntries(results) : null;
        _selectedNodeId = null;
      });
    }
  }

  void _onNodeClick(GraphNode node) {
    setState(() => _selectedNodeId = _selectedNodeId == node.id ? null : node.id);
    _graphController.firePulse(node.id);
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
        const SizedBox(height: 8),
        Expanded(child: _graphData != null ? _buildGraphView() : _buildStarryEmptyState()),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(color: glassBg, borderRadius: BorderRadius.circular(15)),
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                style: const TextStyle(color: textPrimary, fontSize: 15),
                decoration: InputDecoration(
                  hintText: '搜索记忆，图谱实时联动...',
                  hintStyle: const TextStyle(color: textTertiary, fontSize: 14),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.search_rounded, color: textTertiary, size: 22),
                  ),
                  suffixIcon: _isSearching
                      ? Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: accentCyan)),
                        )
                      : _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: textTertiary, size: 18),
                              onPressed: () { _searchController.clear(); _loadAllMemories(); },
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
            boxShadow: [BoxShadow(color: accentPurple.withOpacity(0.05), blurRadius: 30, spreadRadius: 5)],
          ),
          child: Stack(children: [
            GraphVisualizer(graph: _graphData!, selectedNodeId: _selectedNodeId, onNodeClick: _onNodeClick, controller: _graphController),
            Positioned(left: 12, bottom: 12, child: _buildGlassChip('${_graphData!.nodes.length} 节点 · ${_graphData!.edges.length} 连接', Icons.hub_outlined, accentCyan)),
            if (_selectedNodeId != null)
              Positioned(
                right: 12, bottom: 12,
                child: _buildGlassChip(
                  _selectedNodeId!.length > 18 ? '${_selectedNodeId!.substring(0, 18)}...' : _selectedNodeId!,
                  Icons.auto_awesome, accentGold,
                  bgColor: accentGold.withOpacity(0.08), borderColor: accentGold.withOpacity(0.25),
                ),
              ),
          ]),
        ),
      ),
    );
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const SweepGradient(colors: [
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
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: accentCyan.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentCyan.withOpacity(0.2)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.touch_app, size: 14, color: accentCyan.withOpacity(0.7)),
              const SizedBox(width: 6),
              Text('点击节点触发神经脉冲', style: TextStyle(fontSize: 12, color: accentCyan.withOpacity(0.7))),
            ]),
          ),
        ])),
      ]);
    });
  }
}

class _StarParticle {
  final double x, y, size, opacity, twinkleSpeed, twinklePhase;
  _StarParticle({required this.x, required this.y, required this.size, required this.opacity, required this.twinkleSpeed, required this.twinklePhase});
}
