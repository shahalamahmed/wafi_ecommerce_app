import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveUserId(String uid) =>
      _storage.write(key: _userIdKey, value: uid);

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  Future<void> clearAll() => _storage.deleteAll();
}