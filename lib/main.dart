import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'screens/signup_screen.dart'; 

class AppState {
  static String? currentUserId;
}

class AuthGuardObserver extends NavigatorObserver {
  bool _isRedirecting = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkAuth(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) _checkAuth(newRoute);
  }

  void _checkAuth(Route<dynamic> route) {
    if (route.settings.name == '/signup' || _isRedirecting) return;

    if (AppState.currentUserId == null) {
      _isRedirecting = true;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final context = route.navigator?.context;
        if (context == null) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Authentication Required'),
              content: const Text('Please sign up or log in to access this screen.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );

        if (route.navigator != null) {
          route.navigator!.pushAndRemoveUntil(
            MaterialPageRoute(
              settings: const RouteSettings(name: '/signup'),
              builder: (context) => const SignUpScreen(),
            ),
            (route) => false,
          );
        }
        
        _isRedirecting = false;
      });
    }
  }
}

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final AuthGuardObserver authGuardObserver = AuthGuardObserver();

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
      navigatorObservers: [routeObserver, authGuardObserver], 
      home: const HomeScreen(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}