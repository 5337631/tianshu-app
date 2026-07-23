import 'dart:ui';
import 'package:flutter/material.dart';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// MNN 模型下载界面 - 本地推理模型
class MnnDownloadScreen extends StatefulWidget {
  const MnnDownloadScreen({super.key});

  @override
  State<MnnDownloadScreen> createState() => _MnnDownloadScreenState();
}

class _MnnDownloadScreenState extends State<MnnDownloadScreen> {
  // 可用模型列表
  final List<Map<String, dynamic>> _models = [
    {
      'name': 'Qwen2-1.5B',
      'size': '1.5B',
      'sizeOnDisk': '~1.2GB',
      'description': '轻量级中文模型，适合手机',
      'status': 'available',
      'downloaded': false,
    },
    {
      'name': 'Qwen2-7B',
      'size': '7B',
      'sizeOnDisk': '~5.5GB',
      'description': '平衡性能与质量',
      'status': 'available',
      'downloaded': false,
    },
    {
      'name': 'Llama3-8B',
      'size': '8B',
      'sizeOnDisk': '~6GB',
      'description': 'Meta 开源模型',
      'status': 'available',
      'downloaded': false,
    },
    {
      'name': 'Phi3-mini',
      'size': '3.8B',
      'sizeOnDisk': '~3GB',
      'description': '微软小模型，效率高',
      'status': 'available',
      'downloaded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('MNN 模型下载', style: TextStyle(color: _text)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          const Text('可用模型', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
          const SizedBox(height: 12),
          ..._models.map((model) => _buildModelCard(model)),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _glass, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.memory, color: _gold, size: 20),
              const SizedBox(width: 8),
              const Text('本地推理', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
            ]),
            const SizedBox(height: 8),
            const Text(
              '使用 MNN 框架在手机本地运行 AI 模型，无需联网。适合离线场景或注重隐私的用户。',
              style: TextStyle(fontSize: 12, color: _text2, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(Map<String, dynamic> model) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _glass,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(model['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text)),
                    const SizedBox(height: 4),
                    Text('${model['size']} · ${model['sizeOnDisk']}', style: const TextStyle(fontSize: 12, color: _gold)),
                  ],
                ),
              ),
              _buildDownloadButton(model),
            ],
          ),
          const SizedBox(height: 8),
          Text(model['description'], style: const TextStyle(fontSize: 12, color: _text2)),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(Map<String, dynamic> model) {
    if (model['downloaded']) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 4),
            Text('已下载', style: TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => _downloadModel(model),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _gold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _gold),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download, color: _gold, size: 16),
            SizedBox(width: 4),
            Text('下载', style: TextStyle(color: _gold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _downloadModel(Map<String, dynamic> model) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: Text('下载 ${model['name']}', style: const TextStyle(color: _text)),
        content: Text(
          '大小: ${model['sizeOnDisk']}\n\n确认下载此模型？',
          style: const TextStyle(color: _text2),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: _text2))),
          TextButton(
            onPressed: () {
              setState(() => model['downloaded'] = true);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${model['name']} 下载完成')),
              );
            },
            child: const Text('确认', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }
}
