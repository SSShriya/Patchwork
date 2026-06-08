import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'supabase_client.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();
  static const String _userIdKey = 'user_id';

  /// Save only the userId — Supabase handles token persistence itself
  static Future<void> saveSession({required String userId}) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // Check Supabase's live session
  static Future<bool> isLoggedIn() async {
    final session = supabase.auth.currentSession;

    if (session == null) {
      await clearSession();
      return false;
    }

    // Check if the token is expired
    final expiresAt = session.expiresAt; // Unix timestamp (int)
    if (expiresAt != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      if (DateTime.now().isAfter(expiry)) {
        await clearSession();
        return false;
      }
    }

    return true;
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
