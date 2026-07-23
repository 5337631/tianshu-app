import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// 配置管理服务
class ConfigService {
  static final ConfigService instance = ConfigService._internal();
  ConfigService._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  /// 获取配置项
  Future<String> get(String key, {String defaultValue = ''}) async {
    if (!_initialized) await init();
    return _prefs?.getString('config_$key') ?? defaultValue;
  }

  /// 设置配置项
  Future<void> set(String key, String value) async {
    if (!_initialized) await init();
    await _prefs?.setString('config_$key', value);
  }

  /// 获取布尔配置
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    if (!_initialized) await init();
    return _prefs?.getBool('config_$key') ?? defaultValue;
  }

  /// 设置布尔配置
  Future<void> setBool(String key, bool value) async {
    if (!_initialized) await init();
    await _prefs?.setBool('config_$key', value);
  }

  /// 获取整数配置
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    if (!_initialized) await init();
    return _prefs?.getInt('config_$key') ?? defaultValue;
  }

  /// 设置整数配置
  Future<void> setInt(String key, int value) async {
    if (!_initialized) await init();
    await _prefs?.setInt('config_$key', value);
  }

  /// 列出所有配置
  Future<Map<String, String>> listAll() async {
    if (!_initialized) await init();
    final result = <String, String>{};
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('config_')) {
        final configKey = key.substring(7); // 去掉 'config_' 前缀
        result[configKey] = _prefs?.getString(key) ?? '';
      }
    }
    return result;
  }

  /// 重置指定配置
  Future<void> reset(String key) async {
    if (!_initialized) await init();
    await _prefs?.remove('config_$key');
  }

  /// 重置所有配置
  Future<void> resetAll() async {
    if (!_initialized) await init();
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      if (key.startsWith('config_')) {
        await _prefs?.remove(key);
      }
    }
  }

  /// 保存用户偏好
  Future<void> savePreference(String key, String value) async {
    await set('pref_$key', value);
  }

  /// 读取用户偏好
  Future<String> getPreference(String key, {String defaultValue = ''}) async {
    return await get('pref_$key', defaultValue: defaultValue);
  }

  /// 保存 API Key（加密存储更安全，这里简化）
  Future<void> saveApiKey(String service, String key) async {
    await set('apikey_$service', key);
  }

  /// 读取 API Key
  Future<String> getApiKey(String service) async {
    return await get('apikey_$service');
  }
}
