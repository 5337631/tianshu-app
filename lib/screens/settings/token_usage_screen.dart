// Token 用量统计页（对标 HermesApp Token 用量）
import 'dart:ui';
import 'package:flutter/material.dart';

class TokenUsageScreen extends StatefulWidget {
  const TokenUsageScreen({super.key});
  @override
  State<TokenUsageScreen> createState() => _TokenUsageScreenState();
}

class _TokenUsageScreenState extends State<TokenUsageScreen> {
  String _period = 'today'; // today / week / month / all
  int _totalTokens = 0;
  int _inputTokens = 0;
  int _outputTokens = 0;
  double _estimatedCost = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('Token 用量', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 时间选择
          Row(children: [
            _buildPeriodChip('今天', _period == 'today', () => setState(() => _period = 'today')),
            const SizedBox(width: 8),
            _buildPeriodChip('本周', _period == 'week', () => setState(() => _period = 'week')),
            const SizedBox(width: 8),
            _buildPeriodChip('本月', _period == 'month', () => setState(() => _period = 'month')),
            const SizedBox(width: 8),
            _buildPeriodChip('全部', _period == 'all', () => setState(() => _period = 'all')),
          ]),
          const SizedBox(height: 20),
          // 总用量卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0x1AFFD700), Color(0x1AFFD700)]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x1AFFD700)),
            ),
            child: Column(
              children: [
                const Text('总 Token 用量', style: TextStyle(color: Color(0x8AFFFFFF), fontSize: 12)),
                const SizedBox(height: 8),
                Text('$_totalTokens', style: const TextStyle(color: Color(0xFFFFD700), fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('≈ \$${_estimatedCost.toStringAsFixed(4)}', style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 输入/输出对比
          Row(
            children: [
              Expanded(child: _buildStatCard('输入 Token', '$_inputTokens', '${_totalTokens > 0 ? (_inputTokens * 100 ~/ _totalTokens) : 0}%', const Color(0xFF50E3C2))),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('输出 Token', '$_outputTokens', '${_totalTokens > 0 ? (_outputTokens * 100 ~/ _totalTokens) : 0}%', const Color(0xFFFF6B6B))),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection('用量趋势', [
            SizedBox(
              height: 160,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart, color: const Color(0xFFFFD700).withOpacity(0.3), size: 48),
                    const SizedBox(height: 8),
                    Text('暂无数据', style: TextStyle(color: const Color(0x8AFFFFFF).withOpacity(0.5), fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('使用一段时间后查看用量趋势', style: TextStyle(color: const Color(0x8AFFFFFF).withOpacity(0.3), fontSize: 12)),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('模型用量', [
            Container(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, color: const Color(0x8AFFFFFF).withOpacity(0.3), size: 36),
                    const SizedBox(height: 8),
                    Text('暂无数据', style: TextStyle(color: const Color(0x8AFFFFFF).withOpacity(0.5), fontSize: 13)),
                  ],
                ),
              ),
            ),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD700).withOpacity(0.2) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? const Color(0xFFFFD700) : const Color(0x1AFFFFFF)),
        ),
        child: Text(label, style: TextStyle(color: selected ? const Color(0xFFFFD700) : const Color(0x8AFFFFFF), fontSize: 12)),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String percentage, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(percentage, style: TextStyle(color: color.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0x8AFFFFFF), letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0x12FFFFFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}