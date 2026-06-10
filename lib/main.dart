import 'package:app_links/app_links.dart';
import 'package:drp/screens/main_shell.dart';
import 'package:drp/screens/profile_screen.dart';
import 'package:drp/screens/society_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/signup_screen.dart';
import 'services/supabase_client.dart';
import 'package:flutter/foundation.dart';

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
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _handleWebAuthCallback();
    } else {
      _handleIncomingLinks();
    }
  }

  Future<void> _handleWebAuthCallback() async {
    // Supabase Flutter web SDK automatically reads the token from
    // the URL fragment — we just need to wait for it to process
    final uri = Uri.base;

    if (uri.fragment.contains('access_token')) {
      try {
        await supabase.auth.getSessionFromUrl(uri);
      } catch (e) {
        debugPrint('Error getting session from URL: $e');
      }
    }
  }

  void _handleIncomingLinks() {
    _appLinks = AppLinks();

    // ── Handle link when app is launched fresh from the link ──────────
    _appLinks.getInitialLink().then((uri) async {
      if (uri != null && uri.scheme == 'drp') {
        try {
          await supabase.auth.getSessionFromUrl(uri);
        } catch (e) {
          debugPrint('❌ Error getting session from initial link: $e');
        }
      }
    });

    // ── Handle link when app is already open in background ────────────
    _appLinks.uriLinkStream.listen((uri) async {
      if (uri.scheme == 'drp') {
        try {
          await supabase.auth.getSessionFromUrl(uri);
        } catch (e) {
          debugPrint('❌ Error getting session from link: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      home: StreamBuilder<AuthState>(
        stream: supabase.auth.onAuthStateChange,
        builder: (context, snapshot) {
          // ── Still waiting for first event ───────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final session = snapshot.data?.session;
          final user =
              snapshot.data?.session?.user ?? supabase.auth.currentUser;

          // // ── User exists but email not verified ──────────────────────
          // if (user != null && user.emailConfirmedAt == null) {
          //   return VerifyEmailScreen(email: user.email ?? '');
          // }

          // ── No user at all → sign up/login screen ───────────────────
          if (user == null || session == null) return const SignUpScreen();

          // Only re-fetch if the user changed
          if (_lastUserId != user.id) {
            _lastUserId = user.id;
            _routeFuture = _getUserRouteInfo(user.id);
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

              if (info == null || !info.hasCompletedProfile) {
                return ProfileScreen(isSociety: info?.isSociety ?? false);
              }

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
          hasCompletedProfile:
              university != null && university.trim().isNotEmpty,
        );
      }
    } catch (_) {}
    if (attempt < 2) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  return const _UserRouteInfo(isSociety: false, hasCompletedProfile: false);
}
