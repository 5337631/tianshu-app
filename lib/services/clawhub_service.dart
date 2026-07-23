import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// ClawHub 技能市场服务
class ClawHubService {
  static final ClawHubService instance = ClawHubService._internal();
  ClawHubService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _baseUrl = 'https://clawhub.com/api';
  bool _initialized = false;
  String _apiKey = '';

  bool get isInitialized => _initialized;

  /// 初始化
  Future<void> init() async {
    if (_initialized) return;
    _apiKey = await _secureStorage.read(key: 'clawhub_api_key') ?? '';
    _initialized = true;
  }

  /// 配置 API Key
  Future<void> configure({required String apiKey}) async {
    _apiKey = apiKey;
    await _secureStorage.write(key: 'clawhub_api_key', value: apiKey);
  }

  /// 搜索技能
  Future<List<Map<String, dynamic>>> search(String query, {String? category}) async {
    try {
      final params = {'q': query};
      if (category != null) params['category'] = category;

      final uri = Uri.parse('$_baseUrl/skills/search').replace(queryParameters: params);
      final response = await _makeRequest('GET', uri.toString());

      if (response != null && response['skills'] != null) {
        return List<Map<String, dynamic>>.from(response['skills']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取技能详情
  Future<Map<String, dynamic>?> getSkill(String skillId) async {
    try {
      final response = await _makeRequest('GET', '$_baseUrl/skills/$skillId');
      return response;
    } catch (e) {
      return null;
    }
  }

  /// 安装技能
  Future<bool> installSkill(String skillId) async {
    try {
      final response = await _makeRequest('POST', '$_baseUrl/skills/$skillId/install');
      return response != null && response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 更新技能
  Future<bool> updateSkill(String skillId) async {
    try {
      final response = await _makeRequest('POST', '$_baseUrl/skills/$skillId/update');
      return response != null && response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 卸载技能
  Future<bool> uninstallSkill(String skillId) async {
    try {
      final response = await _makeRequest('DELETE', '$_baseUrl/skills/$skillId');
      return response != null && response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// 获取分类列表
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _makeRequest('GET', '$_baseUrl/categories');
      if (response != null && response['categories'] != null) {
        return List<Map<String, dynamic>>.from(response['categories']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 获取热门技能
  Future<List<Map<String, dynamic>>> getPopular({int limit = 10}) async {
    try {
      final response = await _makeRequest('GET', '$_baseUrl/skills/popular?limit=$limit');
      if (response != null && response['skills'] != null) {
        return List<Map<String, dynamic>>.from(response['skills']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 发起请求
  Future<Map<String, dynamic>?> _makeRequest(String method, String url, {Map<String, dynamic>? body}) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_apiKey';
      }

      http.Response response;
      switch (method) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers);
          break;
        case 'POST':
          response = await http.post(Uri.parse(url), headers: headers, body: body != null ? json.encode(body) : null);
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers);
          break;
        default:
          return null;
      }

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
