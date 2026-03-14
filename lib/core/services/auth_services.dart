import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// ignore: constant_identifier_names
enum UserRole { BUYER, SELLER, ADMIN }

// ignore: constant_identifier_names
enum SellerStatus { PENDING, APPROVED, REJECTED }

UserRole _parseRole(String? raw) {
  switch (raw) {
    case 'SELLER': return UserRole.SELLER;
    case 'ADMIN':  return UserRole.ADMIN;
    default:       return UserRole.BUYER;
  }
}

SellerStatus? _parseSellerStatus(String? raw) {
  switch (raw) {
    case 'APPROVED': return SellerStatus.APPROVED;
    case 'REJECTED': return SellerStatus.REJECTED;
    case 'PENDING':  return SellerStatus.PENDING;
    default:         return null;
  }
}

class AuthUser {
  final String id;
  final String email;
  final String? name;
  final UserRole role;
  final SellerStatus? sellerStatus;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    this.sellerStatus,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String?,
        role: _parseRole(json['role'] as String?),
        sellerStatus: _parseSellerStatus(json['sellerStatus'] as String?),
      );
}

class AuthResult {
  final AuthUser user;
  final String accessToken;
  final String refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}

class AuthService {
  static final AuthService _instance = AuthService._();
  AuthService._();
  factory AuthService() => _instance;

  final _storage = const FlutterSecureStorage();
  final String _baseUrl =
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';

  // ---------- Token storage ----------

  Future<void> _saveTokens(String access, String refresh) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<String?> getAccessToken() => _storage.read(key: 'access_token');
  Future<String?> getRefreshToken() => _storage.read(key: 'refresh_token');

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  // ---------- Auth calls ----------

  Future<AuthResult> register({
    required String email,
    required String password,
    required UserRole role,
    String? name,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'role': role.name,
      }),
    );
    if (res.statusCode != 201) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Registration failed');
    }
    return _parseAuthResult(res.body);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Login failed');
    }
    return _parseAuthResult(res.body);
  }

  Future<void> signOut() => clearTokens();

  // GET /auth/me — fetches fresh user data from backend (used by "Check Status")
  Future<AuthResult> refreshMe() async {
    final token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Failed to refresh status');
    }
    return _parseAuthResult(res.body);
  }

  // PATCH /auth/me — update display name
  Future<AuthUser> updateProfile({required String name}) async {
    final token = await getAccessToken();
    if (token == null) throw Exception('Not authenticated');
    final res = await http.patch(
      Uri.parse('$_baseUrl/auth/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (res.statusCode != 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Update failed');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return AuthUser.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<bool> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      );
      if (res.statusCode != 200) return false;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      await _saveTokens(
        data['accessToken'] as String,
        data['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- Helpers ----------

  AuthResult _parseAuthResult(String body) {
    final data = jsonDecode(body) as Map<String, dynamic>;
    final result = AuthResult(
      user: AuthUser.fromJson(data['user'] as Map<String, dynamic>),
      accessToken: data['tokens']['accessToken'] as String,
      refreshToken: data['tokens']['refreshToken'] as String,
    );
    _saveTokens(result.accessToken, result.refreshToken);
    return result;
  }
}
