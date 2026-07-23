import 'dart:async';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/method_channel_helper.dart';

/// Termux SSH 连接池管理
/// 自动路由 Termux SSH 或内置 Shell
class TermuxService {
  static final TermuxService instance = TermuxService._internal();
  TermuxService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final MethodChannelHelper _channel = MethodChannelHelper();

  bool _initialized = false;
  bool _termuxAvailable = false;
  bool _sshConnected = false;

  // SSH 连接配置
  String _sshHost = '127.0.0.1';
  int _sshPort = 8022;
  String _sshUsername = '';
  String _sshPassword = '';

  // 连接池
  final List<_SshConnection> _connectionPool = [];
  static const int _maxPoolSize = 3;
  static const int _connectionTimeoutSeconds = 30;
  static const int _idleTimeoutSeconds = 300;

  bool get isInitialized => _initialized;
  bool get isTermuxAvailable => _termuxAvailable;
  bool get isSshConnected => _sshConnected;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;

    // 检测 Termux 是否安装
    _termuxAvailable = await _channel.isTermuxInstalled();

    if (_termuxAvailable) {
      // 加载 SSH 配置
      _sshHost = await _secureStorage.read(key: 'termux_ssh_host') ?? '127.0.0.1';
      _sshPort = int.tryParse(await _secureStorage.read(key: 'termux_ssh_port') ?? '8022') ?? 8022;
      _sshUsername = await _secureStorage.read(key: 'termux_ssh_username') ?? '';
      _sshPassword = await _secureStorage.read(key: 'termux_ssh_password') ?? '';

      // 尝试建立 SSH 连接
      await _connectSsh();
    }

    _initialized = true;
  }

  /// 配置 SSH 连接
  Future<void> configure({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    _sshHost = host;
    _sshPort = port;
    _sshUsername = username;
    _sshPassword = password;

    await _secureStorage.write(key: 'termux_ssh_host', value: host);
    await _secureStorage.write(key: 'termux_ssh_port', value: port.toString());
    await _secureStorage.write(key: 'termux_ssh_username', value: username);
    await _secureStorage.write(key: 'termux_ssh_password', value: password);

    // 重新连接
    await _disconnectAll();
    await _connectSsh();
  }

  /// 建立 SSH 连接
  Future<bool> _connectSsh() async {
    if (!_termuxAvailable) return false;
    if (_sshUsername.isEmpty || _sshPassword.isEmpty) return false;

    try {
      // 通过 Termux API 建立 SSH 连接
      final result = await _channel.termuxExec(
        'ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$_connectionTimeoutSeconds '
        '-p $_sshPort $_sshUsername@$_sshHost "echo connected"'
      );

      _sshConnected = result.contains('connected');
      return _sshConnected;
    } catch (e) {
      _sshConnected = false;
      return false;
    }
  }

  /// 执行命令 - 自动路由
  Future<Map<String, dynamic>> exec(String command) async {
    // 优先使用 SSH
    if (_sshConnected) {
      return await _execViaSsh(command);
    }

    // 回退到内置 Shell
    return await _execViaShell(command);
  }

  /// 通过 SSH 执行命令
  Future<Map<String, dynamic>> _execViaSsh(String command) async {
    try {
      final result = await _channel.termuxExec(
        'ssh -o StrictHostKeyChecking=no -p $_sshPort $_sshUsername@$_sshHost "$command"'
      );

      return {
        'exitCode': 0,
        'stdout': result,
        'stderr': '',
        'via': 'ssh',
      };
    } catch (e) {
      // SSH 失败，回退到 Shell
      _sshConnected = false;
      return await _execViaShell(command);
    }
  }

  /// 通过内置 Shell 执行命令
  Future<Map<String, dynamic>> _execViaShell(String command) async {
    final result = await _channel.execCommand(command);
    return {
      ...result,
      'via': 'shell',
    };
  }

  /// 获取连接状态
  Map<String, dynamic> getStatus() {
    return {
      'termuxInstalled': _termuxAvailable,
      'sshConnected': _sshConnected,
      'host': _sshHost,
      'port': _sshPort,
      'poolSize': _connectionPool.length,
    };
  }

  /// 断开所有连接
  Future<void> _disconnectAll() async {
    for (final conn in _connectionPool) {
      await conn.close();
    }
    _connectionPool.clear();
    _sshConnected = false;
  }

  /// 刷新连接
  Future<void> refresh() async {
    await _disconnectAll();
    if (_termuxAvailable) {
      await _connectSsh();
    }
  }
}

/// SSH 连接封装
class _SshConnection {
  final String host;
  final int port;
  final String username;
  DateTime lastActive;

  _SshConnection({
    required this.host,
    required this.port,
    required this.username,
  }) : lastActive = DateTime.now();

  bool get isIdle {
    return DateTime.now().difference(lastActive).inSeconds > TermuxService._idleTimeoutSeconds;
  }

  Future<void> close() async {
    // 关闭连接
  }

  void touch() {
    lastActive = DateTime.now();
  }
}
