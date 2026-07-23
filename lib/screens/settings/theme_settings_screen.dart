import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

const Color _bg = Color(0xFF0A0A1A);
const Color _gold = Color(0xFFFFD700);
const Color _glass = Color(0x12FFFFFF);
const Color _border = Color(0x1AFFFFFF);
const Color _text = Color(0xFFFFFFFF);
const Color _text2 = Color(0x8AFFFFFF);

/// 主题设置界面 - 完整对齐HermesApp
class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  SharedPreferences? _prefs;

  // 主题模式
  bool _useSystemTheme = true;
  String _themeMode = 'dark';

  // 主色调
  Color _primaryColor = const Color(0xFFFFD700);

  // 背景
  String? _backgroundPath;
  double _backgroundBlur = 10;
  double _backgroundDim = 0.3;

  // 字体
  double _fontSize = 14;
  String _fontFamily = '默认';

  // 液态玻璃效果
  bool _enableLiquidGlass = true;
  double _glassBlur = 20;
  double _glassOpacity = 0.04;

  // 聊天气泡
  bool _bubbleRound = true;
  double _bubbleRadius = 16;
  bool _showAvatars = true;
  bool _showTimestamps = false;

  // 显示选项
  bool _showThinking = true;
  bool _showTokenCount = false;
  bool _compactMode = false;
  bool _autoScroll = true;

  // 预设颜色
  final List<Color> _presetColors = [
    const Color(0xFFFFD700), // 星辉金
    const Color(0xFF50E3C2), // 翡翠绿
    const Color(0xFFFF6B6B), // 珊瑚红
    const Color(0xFF6C63FF), // 星空紫
    const Color(0xFFFF9F43), // 橙黄
    const Color(0xFF00D2FF), // 天蓝
    const Color(0xFF2ECC71), // 草绿
    const Color(0xFFE74C3C), // 红色
    const Color(0xFF9B59B6), // 紫色
    const Color(0xFF3498DB), // 蓝色
  ];

  // 预设背景
  final List<Map<String, dynamic>> _presetBackgrounds = [
    {'name': '深空', 'color': const Color(0xFF0A0A1A)},
    {'name': '午夜蓝', 'color': const Color(0xFF1A1A2E)},
    {'name': '深紫', 'color': const Color(0xFF16213E)},
    {'name': '墨绿', 'color': const Color(0xFF0D1F0D)},
    {'name': '暗红', 'color': const Color(0xFF1A0A0A)},
  ];

  // 字体选项
  final List<String> _fontOptions = ['默认', 'Roboto', 'Noto Sans', '思源黑体'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _useSystemTheme = _prefs?.getBool('theme_use_system') ?? true;
      _themeMode = _prefs?.getString('theme_mode') ?? 'dark';
      _primaryColor = Color(_prefs?.getInt('theme_primary_color') ?? 0xFFFFD700);
      _backgroundPath = _prefs?.getString('theme_background_path');
      _backgroundBlur = _prefs?.getDouble('theme_bg_blur') ?? 10;
      _backgroundDim = _prefs?.getDouble('theme_bg_dim') ?? 0.3;
      _fontSize = _prefs?.getDouble('theme_font_size') ?? 14;
      _fontFamily = _prefs?.getString('theme_font_family') ?? '默认';
      _enableLiquidGlass = _prefs?.getBool('theme_liquid_glass') ?? true;
      _glassBlur = _prefs?.getDouble('theme_glass_blur') ?? 20;
      _glassOpacity = _prefs?.getDouble('theme_glass_opacity') ?? 0.04;
      _bubbleRound = _prefs?.getBool('theme_bubble_round') ?? true;
      _bubbleRadius = _prefs?.getDouble('theme_bubble_radius') ?? 16;
      _showAvatars = _prefs?.getBool('theme_show_avatars') ?? true;
      _showTimestamps = _prefs?.getBool('theme_show_timestamps') ?? false;
      _showThinking = _prefs?.getBool('theme_show_thinking') ?? true;
      _showTokenCount = _prefs?.getBool('theme_show_token_count') ?? false;
      _compactMode = _prefs?.getBool('theme_compact_mode') ?? false;
      _autoScroll = _prefs?.getBool('theme_auto_scroll') ?? true;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    if (_prefs == null) return;
    if (value is bool) await _prefs!.setBool(key, value);
    if (value is double) await _prefs!.setDouble(key, value);
    if (value is int) await _prefs!.setInt(key, value);
    if (value is String) await _prefs!.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('主题设置', style: TextStyle(color: _text)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('主题模式', [
            _buildSwitchTile('跟随系统', '自动切换亮色/暗色', Icons.brightness_auto, _useSystemTheme, (v) {
              setState(() => _useSystemTheme = v);
              _saveSetting('theme_use_system', v);
            }),
            if (!_useSystemTheme) _buildThemeModeSelector(),
          ]),
          const SizedBox(height: 12),
          _buildSection('主色调', [
            _buildColorPicker(),
          ]),
          const SizedBox(height: 12),
          _buildSection('背景', [
            _buildBackgroundPicker(),
            _buildSliderTile('模糊度', _backgroundBlur, 0, 30, (v) {
              setState(() => _backgroundBlur = v);
              _saveSetting('theme_bg_blur', v);
            }),
            _buildSliderTile('暗化程度', _backgroundDim, 0, 1, (v) {
              setState(() => _backgroundDim = v);
              _saveSetting('theme_bg_dim', v);
            }),
          ]),
          const SizedBox(height: 12),
          _buildSection('液态玻璃效果', [
            _buildSwitchTile('启用效果', 'HermesApp风格毛玻璃', Icons.water_drop, _enableLiquidGlass, (v) {
              setState(() => _enableLiquidGlass = v);
              _saveSetting('theme_liquid_glass', v);
            }),
            if (_enableLiquidGlass) ...[
              _buildSliderTile('模糊强度', _glassBlur, 5, 50, (v) {
                setState(() => _glassBlur = v);
                _saveSetting('theme_glass_blur', v);
              }),
              _buildSliderTile('透明度', _glassOpacity, 0.01, 0.2, (v) {
                setState(() => _glassOpacity = v);
                _saveSetting('theme_glass_opacity', v);
              }),
            ],
          ]),
          const SizedBox(height: 12),
          _buildSection('字体', [
            _buildSliderTile('字号', _fontSize, 10, 24, (v) {
              setState(() => _fontSize = v);
              _saveSetting('theme_font_size', v);
            }),
            _buildFontSelector(),
          ]),
          const SizedBox(height: 12),
          _buildSection('聊天气泡', [
            _buildSwitchTile('圆角气泡', '', Icons.rounded_corner, _bubbleRound, (v) {
              setState(() => _bubbleRound = v);
              _saveSetting('theme_bubble_round', v);
            }),
            if (_bubbleRound)
              _buildSliderTile('圆角大小', _bubbleRadius, 4, 32, (v) {
                setState(() => _bubbleRadius = v);
                _saveSetting('theme_bubble_radius', v);
              }),
            _buildSwitchTile('显示头像', '', Icons.account_circle, _showAvatars, (v) {
              setState(() => _showAvatars = v);
              _saveSetting('theme_show_avatars', v);
            }),
            _buildSwitchTile('显示时间戳', '', Icons.access_time, _showTimestamps, (v) {
              setState(() => _showTimestamps = v);
              _saveSetting('theme_show_timestamps', v);
            }),
          ]),
          const SizedBox(height: 12),
          _buildSection('显示选项', [
            _buildSwitchTile('思考过程', '显示AI内心独白', Icons.psychology, _showThinking, (v) {
              setState(() => _showThinking = v);
              _saveSetting('theme_show_thinking', v);
            }),
            _buildSwitchTile('Token计数', '显示消息Token用量', Icons.bar_chart, _showTokenCount, (v) {
              setState(() => _showTokenCount = v);
              _saveSetting('theme_show_token_count', v);
            }),
            _buildSwitchTile('紧凑模式', '减少间距', Icons.space_bar, _compactMode, (v) {
              setState(() => _compactMode = v);
              _saveSetting('theme_compact_mode', v);
            }),
            _buildSwitchTile('自动滚动', '新消息自动滚动到底部', Icons.vertical_align_bottom, _autoScroll, (v) {
              setState(() => _autoScroll = v);
              _saveSetting('theme_auto_scroll', v);
            }),
          ]),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(color: _glass, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _text2, letterSpacing: 1)),
            ),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      secondary: Icon(icon, color: _gold, size: 22),
      title: Text(title, style: const TextStyle(color: _text, fontSize: 14)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: const TextStyle(color: _text2, fontSize: 11)) : null,
      value: value,
      onChanged: onChanged,
      activeColor: _gold,
      dense: true,
    );
  }

  Widget _buildSliderTile(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: const TextStyle(color: _text, fontSize: 13))),
          Expanded(
            child: Slider(value: value, min: min, max: max, activeColor: _gold, onChanged: onChanged),
          ),
          SizedBox(
            width: 40,
            child: Text(
              value == value.roundToDouble() ? '${value.toInt()}' : value.toStringAsFixed(2),
              style: const TextStyle(color: _gold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _buildModeChip('亮色', Icons.light_mode, _themeMode == 'light', () {
            setState(() => _themeMode = 'light');
            _saveSetting('theme_mode', 'light');
          }),
          const SizedBox(width: 8),
          _buildModeChip('暗色', Icons.dark_mode, _themeMode == 'dark', () {
            setState(() => _themeMode = 'dark');
            _saveSetting('theme_mode', 'dark');
          }),
          const SizedBox(width: 8),
          _buildModeChip('AMOLED', Icons.phone_android, _themeMode == 'amoled', () {
            setState(() => _themeMode = 'amoled');
            _saveSetting('theme_mode', 'amoled');
          }),
        ],
      ),
    );
  }

  Widget _buildModeChip(String label, IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _gold.withOpacity(0.2) : _glass,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _gold : _border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? _gold : _text2, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: selected ? _gold : _text2, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _presetColors.map((c) {
          final isSelected = _primaryColor.value == c.value;
          return GestureDetector(
            onTap: () {
              setState(() => _primaryColor = c);
              _saveSetting('theme_primary_color', c.value);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 3),
                boxShadow: isSelected ? [BoxShadow(color: c.withOpacity(0.5), blurRadius: 12)] : null,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 24) : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBackgroundPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              const Text('预设背景', style: TextStyle(color: _text, fontSize: 14)),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickCustomBackground,
                icon: const Icon(Icons.add_photo_alternate, size: 16),
                label: const Text('自定义'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: _presetBackgrounds.map((bg) {
              final color = bg['color'] as Color;
              final isSelected = _backgroundPath == bg['name'];
              return GestureDetector(
                onTap: () {
                  setState(() => _backgroundPath = bg['name']);
                  _saveSetting('theme_background_path', bg['name']);
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? _gold : _border, width: 2),
                  ),
                  child: Center(
                    child: Text(bg['name'], style: const TextStyle(color: _text2, fontSize: 10)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (_backgroundPath != null && !_presetBackgrounds.any((b) => b['name'] == _backgroundPath))
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.image, color: _gold, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_backgroundPath!, style: const TextStyle(color: _text2, fontSize: 12))),
                TextButton(
                  onPressed: () {
                    setState(() => _backgroundPath = null);
                    _saveSetting('theme_background_path', '');
                  },
                  child: const Text('清除', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFontSelector() {
    return ListTile(
      leading: const Icon(Icons.font_download, color: _gold, size: 22),
      title: const Text('字体', style: TextStyle(color: _text, fontSize: 14)),
      subtitle: Text(_fontFamily, style: const TextStyle(color: _text2, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: _text2, size: 18),
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
            title: const Text('选择字体', style: TextStyle(color: _text)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: _fontOptions.map((font) {
                return RadioListTile<String>(
                  title: Text(font, style: const TextStyle(color: _text)),
                  value: font,
                  groupValue: _fontFamily,
                  activeColor: _gold,
                  onChanged: (v) {
                    setState(() => _fontFamily = v!);
                    _saveSetting('theme_font_family', v);
                    Navigator.pop(ctx);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
      dense: true,
    );
  }

  Future<void> _pickCustomBackground() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _backgroundPath = image.path);
        _saveSetting('theme_background_path', image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }
}
