import 'session_manager.dart';
import 'supabase_client.dart';

class AuthService {
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isCommitteeMember,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;
    final session = response.session;

    if (user == null || session == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'university': '',
      'course': '',
      'bio': '',
    });

    await supabase.from('user_purpose').insert({
      'user_id': user.id,
      'is_committee_member': isCommitteeMember,
    });

    await SessionManager.saveSession(userId: user.id);
  }

  Future<void> signIn({required String email, required String password}) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    final session = response.session;

    if (user == null || session == null) {
      throw Exception('Login failed. Please check your credentials.');
    }

    await SessionManager.saveSession(userId: user.id);
  }
}
