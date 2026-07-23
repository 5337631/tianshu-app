import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/memory_service.dart';

// ═══════════════════════════════════════════
//  Controller - 从外部控制图谱
// ═══════════════════════════════════════════

class GraphVisualizerController {
  void Function(String nodeId)? _firePulse;
  void attach(void Function(String nodeId) firePulse) {
    _firePulse = firePulse;
  }
  void detach() {
    _firePulse = null;
  }
  void firePulse(String nodeId) {
    _firePulse?.call(nodeId);
  }
}

// ═══════════════════════════════════════════
//  数据模型
// ═══════════════════════════════════════════

class GraphNode {
  final String id;
  final String label;
  final Color color;
  GraphNode({required this.id, required this.label, this.color = Colors.grey});
}

class GraphEdge {
  final int id;
  final String sourceId;
  final String targetId;
  final String? label;
  final double weight;
  final bool isCrossFolderLink;
  GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    this.label,
    this.weight = 1.0,
    this.isCrossFolderLink = false,
  });
}

class GraphData {
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  GraphData({required this.nodes, required this.edges});
}

// ═══════════════════════════════════════════
//  流动粒子模型
// ═══════════════════════════════════════════

class _FlowParticle {
  double progress;
  double speed;
  double size;
  Color color;
  double opacity;
  _FlowParticle({
    required this.progress,
    this.speed = 0.005,
    this.size = 3.0,
    this.color = Colors.cyanAccent,
    this.opacity = 0.8,
  });
}

// ═══════════════════════════════════════════
//  神经脉冲模型
// ═══════════════════════════════════════════

class _NeuralPulse {
  final String sourceNodeId;
  final String targetNodeId;
  double progress;
  final Color color;
  _NeuralPulse({
    required this.sourceNodeId,
    required this.targetNodeId,
    this.progress = 0.0,
    this.color = Colors.amber,
  });
}

// ═══════════════════════════════════════════
//  图谱可视化组件
// ═══════════════════════════════════════════

class GraphVisualizer extends StatefulWidget {
  final GraphData graph;
  final String? selectedNodeId;
  final void Function(GraphNode node)? onNodeClick;
  final void Function(GraphEdge edge)? onEdgeClick;
  final GraphVisualizerController? controller;

  const GraphVisualizer({
    super.key,
    required this.graph,
    this.selectedNodeId,
    this.onNodeClick,
    this.onEdgeClick,
    this.controller,
  });

  @override
  State<GraphVisualizer> createState() => _GraphVisualizerState();
}

class _GraphVisualizerState extends State<GraphVisualizer>
    with SingleTickerProviderStateMixin {
  Map<String, Offset> _nodePositions = {};
  Offset _panOffset = Offset.zero;
  double _scale = 1.0;
  double _breathPhase = 0.0;
  late AnimationController _breathController;

  final List<_FlowParticle> _particles = [];
  final List<_NeuralPulse> _pulses = [];

  Timer? _simTimer;
  Timer? _particleTimer;
  Timer? _pulseAnimTimer;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _breathController.addListener(() {
      setState(() {
        _breathPhase = sin(_breathController.value * 2 * pi);
      });
    });
    _initLayout();
    _startParticleSystem();
    _startPulseAnimation();

    // 注册 controller
    widget.controller?.attach(firePulse);
  }

  @override
  void didUpdateWidget(GraphVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.graph != widget.graph) {
      _initLayout();
    }
    // 重新注册 controller
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(firePulse);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _breathController.dispose();
    _simTimer?.cancel();
    _particleTimer?.cancel();
    _pulseAnimTimer?.cancel();
    super.dispose();
  }

  void firePulse(String nodeId) {
    final edges = widget.graph.edges.where((e) =>
        e.sourceId == nodeId || e.targetId == nodeId);
    for (final edge in edges) {
      final otherId = edge.sourceId == nodeId ? edge.targetId : edge.sourceId;
      _pulses.add(_NeuralPulse(
        sourceNodeId: nodeId,
        targetNodeId: otherId,
        progress: 0.0,
        color: edge.isCrossFolderLink ? Colors.purpleAccent : Colors.amber,
      ));
    }
  }

  void _startParticleSystem() {
    _particleTimer?.cancel();
    _particleTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || widget.graph.edges.isEmpty) return;
      final edge = widget.graph.edges[Random().nextInt(widget.graph.edges.length)];
      final colors = edge.isCrossFolderLink
          ? [Colors.purpleAccent, Colors.pinkAccent]
          : [Colors.cyanAccent, Colors.lightGreenAccent, Colors.amberAccent];
      _particles.add(_FlowParticle(
        progress: 0.0,
        speed: 0.003 + Random().nextDouble() * 0.008,
        size: 2.0 + Random().nextDouble() * 3.0,
        color: colors[Random().nextInt(colors.length)],
        opacity: 0.9,
      ));
      while (_particles.length > 120) _particles.removeAt(0);
    });
  }

  void _startPulseAnimation() {
    _pulseAnimTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() {
        for (final p in _particles) {
          p.progress += p.speed;
          p.opacity = 0.3 + 0.7 * (1 - (p.progress - 0.5).abs() * 2).clamp(0.0, 1.0);
        }
        _particles.removeWhere((p) => p.progress >= 1.0);
        for (final p in _pulses) p.progress += 0.04;
        _pulses.removeWhere((p) => p.progress >= 1.0);
      });
    });
  }

  void _initLayout() {
    final w = 400.0;
    final h = 600.0;
    final center = Offset(w / 2, h / 2);
    final positions = <String, Offset>{};
    final rng = Random(42);
    final adjacency = <String, List<String>>{};
    for (final node in widget.graph.nodes) adjacency[node.id] = [];
    for (final edge in widget.graph.edges) {
      if (edge.isCrossFolderLink) continue;
      adjacency[edge.sourceId]?.add(edge.targetId);
      adjacency[edge.targetId]?.add(edge.sourceId);
    }

    final visited = <String>{};
    final clusterByNode = <String, int>{};
    final clusterSizes = <int, int>{};
    int clusterId = 0;
    for (final node in widget.graph.nodes) {
      if (!visited.add(node.id)) continue;
      clusterId++;
      int size = 0;
      final queue = <String>[node.id];
      while (queue.isNotEmpty) {
        final current = queue.removeAt(0);
        clusterByNode[current] = clusterId;
        size++;
        for (final neighbor in (adjacency[current] ?? [])) {
          if (visited.add(neighbor)) queue.add(neighbor);
        }
      }
      clusterSizes[clusterId] = size;
    }

    final clusterCount = max(clusterSizes.length, 1);
    final clusterRingRadius = min(w, h) * 0.34;
    final clusterCenters = <int, Offset>{};
    for (final entry in clusterSizes.entries) {
      final angle = 2 * pi * (entry.key - 1) / clusterCount;
      clusterCenters[entry.key] = clusterCount == 1
          ? center
          : center + Offset(cos(angle), sin(angle)) * clusterRingRadius;
    }

    final neighborsByNode = <String, List<String>>{};
    for (final node in widget.graph.nodes) neighborsByNode[node.id] = [];
    for (final edge in widget.graph.edges) {
      neighborsByNode[edge.sourceId]?.add(edge.targetId);
      neighborsByNode[edge.targetId]?.add(edge.sourceId);
    }

    for (final node in widget.graph.nodes) {
      final cid = clusterByNode[node.id];
      final clusterCenter = clusterCenters[cid] ?? center;
      final clusterSize = (clusterSizes[cid] ?? 1).clamp(1, 999);
      final neighborPositions = (neighborsByNode[node.id] ?? [])
          .map((nid) => _nodePositions[nid])
          .whereType<Offset>()
          .toList();
      final basePos = neighborPositions.isNotEmpty
          ? neighborPositions.fold(Offset.zero, (a, b) => a + b) / neighborPositions.length.toDouble()
          : clusterCenter;
      final scatterRadius = neighborPositions.isNotEmpty
          ? (42 + neighborPositions.length * 5).clamp(0, 120).toDouble()
          : (70 + clusterSize * 4).clamp(0, 200).toDouble();
      final randomAngle = rng.nextDouble() * 2 * pi;
      final randomRadius = rng.nextDouble() * scatterRadius;
      final jitter = Offset(cos(randomAngle), sin(randomAngle)) * randomRadius;
      positions[node.id] = basePos + jitter;
    }
    _nodePositions = positions;
    _runSimulation();
  }

  void _runSimulation() {
    _simTimer?.cancel();
    final positions = Map<String, Offset>.from(_nodePositions);
    final nodes = widget.graph.nodes;
    final edges = widget.graph.edges;
    if (nodes.isEmpty) return;
    final iterations = nodes.length > 100 ? 150 : 300;
    const repulsionStrength = 380000.0;
    const attractionStrength = 0.07;
    const idealEdgeLength = 560.0;
    const minSeparation = 380.0;
    const gravityStrength = 0.005;
    int step = 0;

    _simTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (step >= iterations) { timer.cancel(); return; }
      final forces = <String, Offset>{};
      for (final node in nodes) forces[node.id] = Offset.zero;

      for (int i = 0; i < nodes.length; i++) {
        for (int j = i + 1; j < nodes.length; j++) {
          final n1 = nodes[i], n2 = nodes[j];
          final p1 = positions[n1.id], p2 = positions[n2.id];
          if (p1 == null || p2 == null) continue;
          final dx = p1.dx - p2.dx, dy = p1.dy - p2.dy;
          final distSq = dx * dx + dy * dy;
          if (distSq < 1) continue;
          final dist = sqrt(distSq);
          final force = repulsionStrength / distSq;
          final invDist = 1.0 / dist;
          forces[n1.id] = forces[n1.id]! + Offset(dx * invDist * force, dy * invDist * force);
          forces[n2.id] = forces[n2.id]! - Offset(dx * invDist * force, dy * invDist * force);
          if (dist < minSeparation) {
            final sepForce = pow((minSeparation - dist) / minSeparation, 2.25).toDouble() * 1200;
            forces[n1.id] = forces[n1.id]! + Offset(dx * invDist * sepForce, dy * invDist * sepForce);
            forces[n2.id] = forces[n2.id]! - Offset(dx * invDist * sepForce, dy * invDist * sepForce);
          }
        }
      }

      for (final edge in edges) {
        final sPos = positions[edge.sourceId], tPos = positions[edge.targetId];
        if (sPos == null || tPos == null) continue;
        final dx = tPos.dx - sPos.dx, dy = tPos.dy - sPos.dy;
        final dist = sqrt(dx * dx + dy * dy).clamp(1, double.infinity);
        final edgeIdealLen = edge.isCrossFolderLink ? idealEdgeLength * 1.35 : idealEdgeLength * 0.72;
        final springForce = (attractionStrength * (1.0 + edge.weight * 0.35) * (edge.isCrossFolderLink ? 0.45 : 1.95)) * edgeIdealLen * ((dist - edgeIdealLen) / edgeIdealLen);
        final invDist = 1.0 / dist;
        forces[edge.sourceId] = forces[edge.sourceId]! + Offset(dx * invDist * springForce, dy * invDist * springForce);
        forces[edge.targetId] = forces[edge.targetId]! - Offset(dx * invDist * springForce, dy * invDist * springForce);
      }

      const center = Offset(400, 600);
      for (final node in nodes) {
        final pos = positions[node.id];
        if (pos == null) continue;
        forces[node.id] = forces[node.id]! + (center - pos) * gravityStrength;
      }

      final temperature = idealEdgeLength * 0.42 * (1 - step / iterations.toDouble());
      for (final node in nodes) {
        final force = forces[node.id]!;
        final forceLen = sqrt(force.dx * force.dx + force.dy * force.dy);
        if (forceLen < 0.1) continue;
        positions[node.id] = positions[node.id]! + force / forceLen * min(forceLen, temperature);
      }

      step++;
      if (step % 2 == 0 || step >= iterations) {
        setState(() => _nodePositions = Map.from(positions));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onScaleStart: (_) {},
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_scale * details.scale).clamp(0.15, 2.2);
              _panOffset += details.focalPointDelta;
            });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _GraphPainter(
                graph: widget.graph,
                nodePositions: _nodePositions,
                panOffset: _panOffset,
                scale: _scale,
                breathPhase: _breathPhase,
                selectedNodeId: widget.selectedNodeId,
                particles: _particles,
                pulses: _pulses,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════
//  自定义 Painter
// ═══════════════════════════════════════════

class _GraphPainter extends CustomPainter {
  final GraphData graph;
  final Map<String, Offset> nodePositions;
  final Offset panOffset;
  final double scale;
  final double breathPhase;
  final String? selectedNodeId;
  final List<_FlowParticle> particles;
  final List<_NeuralPulse> pulses;

  _GraphPainter({
    required this.graph,
    required this.nodePositions,
    required this.panOffset,
    required this.scale,
    required this.breathPhase,
    this.selectedNodeId,
    this.particles = const [],
    this.pulses = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale);
    _drawGrid(canvas, size);
    for (final edge in graph.edges) _drawEdge(canvas, edge);
    for (final pulse in pulses) _drawPulse(canvas, pulse);
    for (final particle in particles) _drawParticle(canvas, particle);
    for (final node in graph.nodes) _drawNode(canvas, node);
    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = const Color(0x08FFFFFF)..strokeWidth = 0.5;
    const spacing = 60.0;
    for (double x = 0; x < size.width * 3; x += spacing) canvas.drawLine(Offset(x, 0), Offset(x, size.height * 3), gridPaint);
    for (double y = 0; y < size.height * 3; y += spacing) canvas.drawLine(Offset(0, y), Offset(size.width * 3, y), gridPaint);
  }

  void _drawEdge(Canvas canvas, GraphEdge edge) {
    final sPos = nodePositions[edge.sourceId], tPos = nodePositions[edge.targetId];
    if (sPos == null || tPos == null) return;
    final isSelected = selectedNodeId != null && (edge.sourceId == selectedNodeId || edge.targetId == selectedNodeId);
    final sNode = graph.nodes.where((n) => n.id == edge.sourceId).firstOrNull;
    final tNode = graph.nodes.where((n) => n.id == edge.targetId).firstOrNull;
    final sColor = sNode?.color ?? const Color(0xFF6B7280);
    final tColor = tNode?.color ?? const Color(0xFF6B7280);

    if (edge.isCrossFolderLink) {
      final sw = (edge.weight * 2.6 * scale).clamp(0.5, 6.0);
      final p = Paint()..color = isSelected ? Colors.pinkAccent : const Color(0xFF9CA3AF)..strokeWidth = sw..style = PaintingStyle.stroke;
      _drawDashedLine(canvas, sPos, tPos, p, 10, 10);
      if (isSelected) {
        final gp = Paint()..color = Colors.pinkAccent.withOpacity(0.3)..strokeWidth = sw + 6..style = PaintingStyle.stroke..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);
        _drawDashedLine(canvas, sPos, tPos, gp, 10, 10);
      }
    } else {
      final sw = (edge.weight * 5.8 * scale).clamp(0.5, 14.0);
      final gradient = LinearGradient(colors: isSelected ? [Colors.amberAccent, Colors.orangeAccent] : [sColor.withOpacity(0.6), tColor.withOpacity(0.6)]);
      final gp = Paint()..shader = gradient.createShader(Rect.fromPoints(sPos, tPos))..strokeWidth = sw..style = PaintingStyle.stroke;
      canvas.drawLine(sPos, tPos, gp);
      if (isSelected) {
        final glow = Paint()..color = Colors.amber.withOpacity(0.25)..strokeWidth = sw + 8..style = PaintingStyle.stroke..maskFilter = MaskFilter.blur(BlurStyle.normal, 12);
        canvas.drawLine(sPos, tPos, glow);
      }
    }
  }

  void _drawDashedLine(Canvas c, Offset s, Offset e, Paint p, double dl, double gl) {
    final dx = e.dx - s.dx, dy = e.dy - s.dy, tl = sqrt(dx * dx + dy * dy);
    if (tl < 0.1) return;
    final ux = dx / tl, uy = dy / tl;
    double d = 0;
    while (d < tl) {
      final de = min(d + dl, tl);
      c.drawLine(Offset(s.dx + ux * d, s.dy + uy * d), Offset(s.dx + ux * de, s.dy + uy * de), p);
      d = de + gl;
    }
  }

  void _drawPulse(Canvas c, _NeuralPulse p) {
    final sPos = nodePositions[p.sourceNodeId], tPos = nodePositions[p.targetNodeId];
    if (sPos == null || tPos == null) return;
    final pos = Offset(sPos.dx + (tPos.dx - sPos.dx) * p.progress, sPos.dy + (tPos.dy - sPos.dy) * p.progress);
    final pr = 8 + 12 * (1 - p.progress);
    final pp = Paint()..color = p.color.withOpacity((1 - p.progress) * 0.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, 15);
    c.drawCircle(pos, pr, pp);
    final cp = Paint()..color = p.color.withOpacity((1 - p.progress) * 0.9);
    c.drawCircle(pos, 3, cp);
  }

  void _drawParticle(Canvas c, _FlowParticle p) {
    if (graph.edges.isEmpty) return;
    final edge = graph.edges[(p.hashCode % graph.edges.length).clamp(0, graph.edges.length - 1)];
    final sPos = nodePositions[edge.sourceId], tPos = nodePositions[edge.targetId];
    if (sPos == null || tPos == null) return;
    final pos = Offset(sPos.dx + (tPos.dx - sPos.dx) * p.progress, sPos.dy + (tPos.dy - sPos.dy) * p.progress);
    final gp = Paint()..color = p.color.withOpacity(p.opacity * 0.3)..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);
    c.drawCircle(pos, p.size * 2, gp);
    final cp = Paint()..color = p.color.withOpacity(p.opacity);
    c.drawCircle(pos, p.size, cp);
  }

  void _drawNode(Canvas c, GraphNode node) {
    final pos = nodePositions[node.id];
    if (pos == null) return;
    final isSelected = node.id == selectedNodeId;
    final bs = 1.0 + 0.03 * breathPhase;
    final es = scale * bs;
    final tp = TextPainter(text: TextSpan(text: node.label, style: TextStyle(fontSize: 11.5 * es, color: node.color.computeLuminance() >= 0.5 ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB))), textDirection: TextDirection.ltr)..layout(maxWidth: 280 * es);
    final px = 14 * es, py = 4 * es, bw = tp.width + px * 2, bh = tp.height + py * 2, r = min(bh * 0.48, 20 * es);
    final rect = Rect.fromCenter(center: pos, width: bw, height: bh);

    if (isSelected) {
      final gp = Paint()..color = Colors.amber.withOpacity(0.3 + 0.2 * breathPhase)..maskFilter = MaskFilter.blur(BlurStyle.normal, 20 * es);
      c.drawRRect(RRect.fromRectAndRadius(rect.inflate(12 * es), Radius.circular(r + 6)), gp);
    }
    final sp = Paint()..color = const Color(0xFF1F2530).withOpacity(0.5)..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * es);
    c.drawRRect(RRect.fromRectAndRadius(rect.translate(0, 2 * es), Radius.circular(r)), sp);
    final fp = Paint()..color = isSelected ? Color.lerp(node.color, Colors.amber, 0.15)! : node.color..style = PaintingStyle.fill;
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), fp);
    final bp = Paint()..color = isSelected ? Color.lerp(const Color(0xFF9CA3AF), Colors.amber, 0.5 + 0.3 * breathPhase)! : const Color(0xFF9CA3AF)..style = PaintingStyle.stroke..strokeWidth = isSelected ? (2.0 + 0.5 * breathPhase) * es : 1.0 * es;
    c.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(r)), bp);
    tp.paint(c, Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════
//  从 MemoryEntry 构建 GraphData
// ═══════════════════════════════════════════

GraphData buildGraphFromMemoryEntries(List<MemoryEntry> entries) {
  if (entries.isEmpty) return GraphData(nodes: [], edges: []);
  const nodeColors = [Color(0xFF6C5CE7), Color(0xFF00B894), Color(0xFFFD79A8), Color(0xFF0984E3), Color(0xFFFDCB6E), Color(0xFFE17055), Color(0xFF00CEC9), Color(0xFFA29BFE)];

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
    nodeMap[cat] = GraphNode(id: cat, label: cat, color: nodeColors[ci % nodeColors.length]);
    ci++;
  }
  final edges = <GraphEdge>[];
  for (final entry in entries) {
    final parts = entry.path.split('/');
    if (parts.length >= 2) {
      edges.add(GraphEdge(id: edgeId++, sourceId: parts[0], targetId: entry.path, weight: entry.relevance, isCrossFolderLink: parts.length > 2));
    }
  }
  return GraphData(nodes: nodeMap.values.toList(), edges: edges);
}
