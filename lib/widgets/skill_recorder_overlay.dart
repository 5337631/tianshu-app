import 'package:flutter/material.dart';
import '../services/skill_recorder_service.dart';

const Color deepSpaceBlue = Color(0xFF0A0A1A);
const Color starGold = Color(0xFFFFD700);
const Color glassWhite = Color(0x12FFFFFF);
const Color glassBorder = Color(0x1AFFFFFF);
const Color textPrimary = Color(0xFFFFFFFF);
const Color textSecondary = Color(0x8AFFFFFF);

/// Skill Recorder 悬浮窗控件
class SkillRecorderOverlay extends StatefulWidget {
  final VoidCallback? onStartRecording;
  final VoidCallback? onStopRecording;
  final VoidCallback? onSaveSkill;
  final Function(String)? onRecordAction;

  const SkillRecorderOverlay({
    super.key,
    this.onStartRecording,
    this.onStopRecording,
    this.onSaveSkill,
    this.onRecordAction,
  });

  @override
  State<SkillRecorderOverlay> createState() => _SkillRecorderOverlayState();
}

class _SkillRecorderOverlayState extends State<SkillRecorderOverlay> {
  bool _isExpanded = false;
  bool _isRecording = false;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  void _updateStatus() {
    final status = SkillRecorderService.instance.getStatus();
    setState(() {
      _isRecording = status['isRecording'] ?? false;
      _frameCount = status['frameCount'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 100,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 展开的控制面板
          if (_isExpanded) _buildExpandedPanel(),
          const SizedBox(height: 8),
          // 主按钮
          _buildMainButton(),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isRecording
                ? [Colors.red, Colors.redAccent]
                : [starGold, Color(0xFFFFA500)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? Colors.red : starGold).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop : Icons.fiber_manual_record,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: deepSpaceBlue.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  _isRecording ? Icons.fiber_manual_record : Icons.videocam,
                  color: _isRecording ? Colors.red : starGold,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _isRecording ? '录制中' : 'Skill Recorder',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _isRecording ? Colors.red : textPrimary,
                  ),
                ),
              ],
            ),
            if (_isRecording) ...[
              const SizedBox(height: 8),
              // 帧计数
              Text(
                '已录制 $_frameCount 步',
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            // 控制按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildControlButton(
                  icon: _isRecording ? Icons.stop : Icons.play_arrow,
                  label: _isRecording ? '停止' : '开始',
                  color: _isRecording ? Colors.red : Colors.green,
                  onTap: () {
                    if (_isRecording) {
                      SkillRecorderService.instance.stopRecording();
                      widget.onStopRecording?.call();
                    } else {
                      SkillRecorderService.instance.startRecording(
                        skillName: '录制的技能',
                        skillDescription: '用户录制的操作步骤',
                      );
                      widget.onStartRecording?.call();
                    }
                    _updateStatus();
                  },
                ),
                _buildControlButton(
                  icon: Icons.save,
                  label: '保存',
                  color: starGold,
                  onTap: _isRecording ? null : () {
                    widget.onSaveSkill?.call();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(
              icon,
              color: onTap != null ? color : color.withOpacity(0.3),
              size: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: onTap != null ? textSecondary : textSecondary.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}
