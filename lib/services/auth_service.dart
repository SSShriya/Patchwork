import 'session_manager.dart';
import 'supabase_client.dart';

class AuthService {
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required bool isSociety,
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


    if(isSociety) {

      await supabase.from('societies').insert({
        'id': user.id,
        'name': name,
      });

    } 

    await supabase.from('users').insert({
      'id': user.id,
      'name': name,
      'university': '',
      'course': '',
      'bio': '',
      'is_committee_member': isSociety,
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
