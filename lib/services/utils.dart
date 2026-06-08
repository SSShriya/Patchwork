import 'session_manager.dart';

Future<String> loadUserId() async {
  final id = await SessionManager.getUserId(); 
  if (id == null) {
    await SessionManager.clearSession(); // Clear any partial session data
    throw Exception("User session not found. Please log in again.");
  }
  return id; 
}