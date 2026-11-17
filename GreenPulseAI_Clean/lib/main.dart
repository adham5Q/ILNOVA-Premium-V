import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'auth_service.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('.env load info: $e');
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));

    debugPrint('FIREBASE INIT OK');
  } catch (e) {
    debugPrint('FIREBASE INIT ERROR: $e');
  }

  runApp(const GreenPulseApp());
}

class GreenPulseApp extends StatelessWidget {
  const GreenPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GreenPulse AI',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F8F3),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16865C),
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthenticationAndNavigate();
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 500));

    Widget destination = const LoginScreen();

    try {
      final user = AuthService.instance.currentUser;
      final hasToken = await AuthService.instance.hasValidSecureToken();

      if (user != null || hasToken) {
        destination = const HomeScreen();
      }
    } catch (e) {
      debugPrint('Startup authentication check: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8F3),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFDCF3E5),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 76,
                color: Color(0xFF16865C),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'GreenPulse AI',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF145A3A),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A Smarter Way to Protect Our Planet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF52705E),
              ),
            ),
            const SizedBox(height: 36),
            const CircularProgressIndicator(
              color: Color(0xFF16865C),
            ),
          ],
        ),
      ),
    );
  }
}
