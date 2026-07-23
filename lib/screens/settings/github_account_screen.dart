// GitHub 账号集成页（对标 HermesApp GitHub 集成）
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class GitHubAccountScreen extends StatefulWidget {
  const GitHubAccountScreen({super.key});
  @override
  State<GitHubAccountScreen> createState() => _GitHubAccountScreenState();
}

class _GitHubAccountScreenState extends State<GitHubAccountScreen> {
  final _tokenController = TextEditingController();
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _username = '';
  String _email = '';
  int _publicRepos = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('GitHub 账号', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_isLoggedIn) ...[
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildSection('同步设置', [
              _buildSwitchTile('自动同步', '每次对话后自动同步', Icons.sync, true, (_) {}),
              _buildSwitchTile('备份到 Gist', '将聊天备份保存为 Gist', Icons.code, false, (_) {}),
            ]),
            const SizedBox(height: 16),
            _buildSection('数据', [
              _buildInfoTile('仓库', '$_publicRepos 个'),
              _buildInfoTile('同步状态', '上次同步: 刚刚'),
            ]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('退出登录'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6B6B),
                    side: const BorderSide(color: Color(0xFFFF6B6B)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          ] else ...[
            _buildSection('登录 GitHub', [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('输入 Personal Access Token', style: TextStyle(color: Color(0x8AFFFFFF), fontSize: 12)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _tokenController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: 'ghp_...',
                    hintStyle: const TextStyle(color: Color(0x8AFFFFFF)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _login,
                    icon: _isLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.login, size: 18),
                    label: Text(_isLoading ? '验证中...' : '登录'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD700),
                      foregroundColor: const Color(0xFF0A0A1A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Token 需要 repo 和 gist 权限。前往 GitHub Settings → Developer settings → Personal access tokens 创建。',
                  style: TextStyle(color: Color(0x8AFFFFFF), fontSize: 11),
                ),
              ),
            ]),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFFFD700).withOpacity(0.2),
            child: const Icon(Icons.person, color: Color(0xFFFFD700), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_username, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_email.isNotEmpty ? _email : '未设置邮箱', style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x1A50E3C2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('已连接', style: TextStyle(color: Color(0xFF50E3C2), fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/user'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isLoggedIn = true;
          _username = data['login'] ?? '';
          _email = data['email'] ?? '';
          _publicRepos = data['public_repos'] ?? 0;
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _logout() {
    setState(() {
      _isLoggedIn = false;
      _username = '';
      _email = '';
      _tokenController.clear();
    });
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

  Widget _buildSwitchTile(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFD700), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 11)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: const Color(0xFFFFD700)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
          Text(value, style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 13)),
        ],
      ),
    );
  }
}