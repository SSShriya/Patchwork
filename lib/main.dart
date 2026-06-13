import 'package:app_links/app_links.dart';
import 'package:drp/screens/main_shell.dart';
import 'package:drp/screens/profile_screen.dart';
import 'package:drp/widgets/society_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/signup_screen.dart';
import 'services/supabase_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  debugPrint('🟢 MAIN: Supabase initialized, running app');
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final AppLinks _appLinks;
  late final StreamSubscription<AuthState> _authSubscription;

  bool _isLoggedIn = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🟢 MAINAPP: initState — setting up auth listener');

    _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
      debugPrint(
        '🟢 AUTH LISTENER: event=${data.event}, userId=${data.session?.user?.id ?? 'null'}',
      );

      if (data.event == AuthChangeEvent.initialSession) {
        // ✅ Only setState here — this sets the initial home widget ONCE
        debugPrint(
          '🟢 AUTH LISTENER: initialSession — setting up initial state',
        );
        if (mounted) {
          setState(() {
            _isLoggedIn = data.session != null;
            _isInitialized = true;
          });
        }
      } else if (data.event == AuthChangeEvent.signedIn) {
        // ✅ No setState — just navigate imperatively
        debugPrint('🟢 AUTH LISTENER: signedIn — navigating to _AppRouter');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const _AppRouter()),
            (route) => false,
          );
          debugPrint('🟢 AUTH LISTENER: pushAndRemoveUntil(_AppRouter) done');
        });
      } else if (data.event == AuthChangeEvent.signedOut) {
        // ✅ No setState — just navigate imperatively
        debugPrint('🟢 AUTH LISTENER: signedOut — navigating to SignUpScreen');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const SignUpScreen()),
            (route) => false,
          );
          debugPrint('🟢 AUTH LISTENER: pushAndRemoveUntil(SignUpScreen) done');
        });
      }
    });

    if (kIsWeb) {
      _handleWebAuthCallback();
    } else {
      _handleIncomingLinks();
    }
  }

  @override
  void dispose() {
    debugPrint('🟢 MAINAPP: dispose — cancelling auth subscription');
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _handleWebAuthCallback() async {
    // Supabase Flutter web SDK automatically reads the token from
    // the URL fragment — we just need to wait for it to process
    final uri = Uri.base;
    debugPrint('🟢 MAINAPP: _handleWebAuthCallback uri=$uri');

    if (uri.fragment.contains('access_token')) {
      debugPrint(
        '🟢 MAINAPP: access_token found in fragment, calling getSessionFromUrl',
      );
      try {
        await supabase.auth.getSessionFromUrl(uri);
        debugPrint('🟢 MAINAPP: getSessionFromUrl completed');
      } catch (e) {
        debugPrint('🟢 MAINAPP: Error getting session from URL: $e');
      }
    }
  }

  void _handleIncomingLinks() {
    _appLinks = AppLinks();

    // ── Handle link when app is launched fresh from the link ──────────
    _appLinks.getInitialLink().then((uri) async {
      debugPrint('🟢 MAINAPP: getInitialLink uri=$uri');
      if (uri != null && uri.scheme == 'drp') {
        try {
          await supabase.auth.getSessionFromUrl(uri);
          debugPrint('🟢 MAINAPP: getSessionFromUrl (initial) completed');
        } catch (e) {
          debugPrint('❌ Error getting session from initial link: $e');
        }
      }
    });

    // ── Handle link when app is already open in background ────────────
    _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('🟢 MAINAPP: uriLinkStream uri=$uri');
      if (uri.scheme == 'drp') {
        try {
          await supabase.auth.getSessionFromUrl(uri);
          debugPrint('🟢 MAINAPP: getSessionFromUrl (stream) completed');
        } catch (e) {
          debugPrint('❌ Error getting session from link: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🟢 MAINAPP: build called, _isInitialized=$_isInitialized, _isLoggedIn=$_isLoggedIn',
    );
    return MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      // ✅ Simple home — just a loading spinner until auth state is known.
      // All navigation is handled imperatively via the auth listener above.
      home: _isInitialized
          ? (_isLoggedIn ? const _AppRouter() : const SignUpScreen())
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
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
  debugPrint('🟢 _getUserRouteInfo: fetching for userId=$userId');
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      final result = await supabase
          .from('users')
          .select('is_society, name, university')
          .eq('id', userId)
          .maybeSingle();

      debugPrint('🟢 _getUserRouteInfo: attempt=$attempt result=$result');

      if (result != null) {
        final university = result['university'] as String?;

        final info = _UserRouteInfo(
          isSociety: result['is_society'] == true,
          hasCompletedProfile:
              university != null && university.trim().isNotEmpty,
        );
        debugPrint(
          '🟢 _getUserRouteInfo: isSociety=${info.isSociety}, hasCompletedProfile=${info.hasCompletedProfile}',
        );
        return info;
      }
    } catch (e) {
      debugPrint('🟢 _getUserRouteInfo: attempt=$attempt error=$e');
    }
    if (attempt < 2) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  debugPrint('🟢 _getUserRouteInfo: all attempts failed, returning defaults');
  return const _UserRouteInfo(isSociety: false, hasCompletedProfile: false);
}

// New widget — extract the FutureBuilder logic out of StreamBuilder
class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  Future<_UserRouteInfo>? _routeFuture;

  @override
  void initState() {
    super.initState();
    final userId = supabase.auth.currentUser?.id;
    debugPrint('🟢 _APPROUTER: initState userId=$userId');
    if (userId != null) {
      _routeFuture = _getUserRouteInfo(userId);
    } else {
      debugPrint('🟢 _APPROUTER: no current user in initState');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🟢 _APPROUTER: build called');
    return FutureBuilder<_UserRouteInfo>(
      future: _routeFuture,
      builder: (context, snap) {
        debugPrint(
          '🟢 _APPROUTER: FutureBuilder state=${snap.connectionState}, hasData=${snap.hasData}, hasError=${snap.hasError}',
        );

        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final info = snap.data;
        debugPrint(
          '🟢 _APPROUTER: routing — isSociety=${info?.isSociety}, hasCompletedProfile=${info?.hasCompletedProfile}',
        );

        if (info == null || !info.hasCompletedProfile) {
          debugPrint(
            '🟢 _APPROUTER: going to ProfileScreen, isSociety=${info?.isSociety ?? false}',
          );
          return ProfileScreen(isSociety: info?.isSociety ?? false);
        }

        debugPrint(
          '🟢 _APPROUTER: going to ${info.isSociety ? 'SocietyNavBar' : 'MainShell'}',
        );
        return info.isSociety ? const SocietyNavBar() : const MainShell();
      },
    );
  }
}
