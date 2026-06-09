import 'package:drp/screens/main_shell.dart';
import 'package:drp/screens/society_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/signup_screen.dart';
import 'services/supabase_client.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          if (session == null) return const SignUpScreen();

          // Fetch user purpose from DB, not a global variable
          return FutureBuilder<bool>(
            future: _isCommitteeMember(session.user.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snap.data == true ? SocietyScreen() : const MainShell();
            },
          );
        },
      ),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const MainShell(),
      },
    );
  }
}

Future<bool> _isCommitteeMember(String userId) async {
  try {
    final result = await supabase
        .from('societies')
        .select()
        .eq('id', userId);
    return result.isNotEmpty;
  } catch (_) {
    return false;
  }
}
