import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = const FlutterSecureStorage();
  static const _keyApi = 'OPENAI_API_KEY';

  static Future<void> saveApiKey(String key) =>
      _storage.write(key: _keyApi, value: key);

  static Future<String?> readApiKey() => _storage.read(key: _keyApi);

  static Future<void> deleteApiKey() => _storage.delete(key: _keyApi);
}