import 'package:flutter/foundation.dart';
import 'session_manager.dart';
import 'supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isSociety,
  }) async {
    final redirectTo = kIsWeb ? Uri.base.origin : 'drp://login-callback';

    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: redirectTo,
        data: {
          'name': name,
          'is_society': isSociety,
          'can_message': !isSociety,
        },
        // all users can message, societies opt in to be open to messaging
      );

      final user = response.user;

      if (user == null) {
        throw Exception('Sign up failed. Please try again.');
      }

      // Supabase returns a fake user with no identities if the email
      // already exists — check for this specifically
      if (user.identities != null && user.identities!.isEmpty) {
        throw Exception('An account with this email already exists.');
      }

      if (response.session == null) {
        throw Exception(
          'Email address has not been verified. Please check your inbox.',
        );
      }
    } on AuthException catch (e) {
      // Re-map Supabase auth error messages to friendlier ones
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already exists') ||
          e.message.toLowerCase().contains('email address is already')) {
        throw Exception('An account with this email already exists.');
      }
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    final session = response.session;

    if (user == null || session == null) {
      throw AuthException('Login failed. Please check your credentials.');
    }

    await SessionManager.saveSession(userId: user.id);
  }
}
