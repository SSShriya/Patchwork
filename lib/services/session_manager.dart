import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();

  // Keys
  static const String _userIdKey = 'user_id';
  static const String _authTokenKey = 'auth_token';

  // Save session after login
  static Future<void> saveSession({
    required String userId,
    required String authToken,
  }) async {
    await _storage.write(key: _userIdKey, value: userId);
    await _storage.write(key: _authTokenKey, value: authToken);
  }

  // Obtain user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Read auth token
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _authTokenKey);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: _authTokenKey);
    return token != null && token.isNotEmpty;
  }

  // Clear session on logout
  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}