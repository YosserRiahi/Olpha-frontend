import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageUploadService {
  static final _storage = const FlutterSecureStorage();

  static String get _baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:3000/api/v1';

  /// Uploads a single image file and returns the hosted URL.
  static Future<String> uploadImage(File file) async {
    final token = await _storage.read(key: 'access_token');

    final uri = Uri.parse('$_baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      throw Exception(decoded['error'] ?? 'Upload failed');
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return decoded['url'] as String;
  }
}
