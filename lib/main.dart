import 'package:drp/screens/main_shell.dart';
import 'package:drp/screens/profile_screen.dart';
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

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Future<_UserRouteInfo>? _routeFuture;
  String? _lastUserId;

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

          // Only re-fetch if the user actually changed
          if (_lastUserId != session.user.id) {
            _lastUserId = session.user.id;
            _routeFuture = _getUserRouteInfo(session.user.id);
          }

          return FutureBuilder<_UserRouteInfo>(
            future: _routeFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final info = snap.data;

              // Profile incomplete → always go to profile setup first
              if (info == null || !info.hasCompletedProfile) {
                return const ProfileScreen();
              }

              // Profile complete → route by account type
              return info.isSociety ? const SocietyScreen() : const MainShell();
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

// Holds everything the StreamBuilder needs to make a routing decision
class _UserRouteInfo {
  final bool isSociety;
  final bool hasCompletedProfile;

  const _UserRouteInfo({
    required this.isSociety,
    required this.hasCompletedProfile,
  });
}

Future<_UserRouteInfo> _getUserRouteInfo(String userId) async {
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      final result = await supabase
          .from('users')
          .select('is_society, name, university')
          .eq('id', userId)
          .maybeSingle();

      if (result != null) {
        final university = result['university'] as String?;
        return _UserRouteInfo(
          isSociety: result['is_society'] == true,
          // University can only be set from ProfileScreen — safe completion check
          hasCompletedProfile:
              university != null && university.trim().isNotEmpty,
        );
      }
    } catch (_) {}
    if (attempt < 2) await Future.delayed(const Duration(milliseconds: 500));
  }

  return const _UserRouteInfo(isSociety: false, hasCompletedProfile: false);
}
