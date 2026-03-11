import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/services/auth_services.dart';
import 'shop_model.dart';

class ShopService {
  static final ShopService _instance = ShopService._();
  ShopService._();
  factory ShopService() => _instance;

  final _authService = AuthService();
  final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Public: browse approved shops ──────────────────────────────────────────
  Future<List<ShopModel>> listShops({String? category, String? search}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (search != null) params['search'] = search;

    final uri = Uri.parse('$_baseUrl/shops').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});

    if (res.statusCode != 200) throw Exception('Failed to load shops');
    final list = jsonDecode(res.body) as List<dynamic>;
    return list.map((e) => ShopModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ── Public: get single shop ─────────────────────────────────────────────────
  Future<ShopModel> getShop(String id) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/shops/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Shop not found');
    }
    return ShopModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Seller: create my shop ──────────────────────────────────────────────────
  Future<ShopModel> createShop({
    required String name,
    String? description,
    String? location,
    String? category,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/shops'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
        if (location != null) 'location': location,
        if (category != null) 'category': category,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create shop');
    }
    return ShopModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Seller: get my shop ─────────────────────────────────────────────────────
  Future<ShopModel> getMyShop() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/shops/me'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'No shop found');
    }
    return ShopModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Seller: update my shop ──────────────────────────────────────────────────
  Future<ShopModel> updateMyShop(Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/shops/me'),
      headers: await _authHeaders(),
      body: jsonEncode(updates),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update shop');
    }
    return ShopModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
