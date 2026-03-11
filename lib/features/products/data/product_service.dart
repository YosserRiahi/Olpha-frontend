import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/services/auth_services.dart';
import 'product_model.dart';

class ProductService {
  static final ProductService _instance = ProductService._();
  ProductService._();
  factory ProductService() => _instance;

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

  // ── Seller: list my products ────────────────────────────────────────────────
  Future<List<ProductModel>> listMyProducts() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products/me'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to load products');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Seller: create product ──────────────────────────────────────────────────
  Future<ProductModel> createProduct({
    required String name,
    String? description,
    required double price,
    int stock = 0,
    String? category,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/products'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
        'price': price,
        'stock': stock,
        if (category != null) 'category': category,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to create product');
    }
    return ProductModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Seller: update product ──────────────────────────────────────────────────
  Future<ProductModel> updateProduct(
      String id, Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/products/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(updates),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to update product');
    }
    return ProductModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Seller: delete product ──────────────────────────────────────────────────
  Future<void> deleteProduct(String id) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/products/$id'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to delete product');
    }
  }

  // ── Seller: toggle active ───────────────────────────────────────────────────
  Future<ProductModel> toggleProduct(String id) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/products/$id/toggle'),
      headers: await _authHeaders(),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to toggle product');
    }
    return ProductModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ── Public: list active products for a shop ─────────────────────────────────
  Future<List<ProductModel>> listProductsByShop(String shopId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products/shop/$shopId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to load products');
    }
    final list = jsonDecode(res.body) as List<dynamic>;
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Public: get single product ──────────────────────────────────────────────
  Future<ProductModel> getProduct(String id) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Product not found');
    }
    return ProductModel.fromJson(
        jsonDecode(res.body) as Map<String, dynamic>);
  }
}
