import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      // Add a minimum splash screen duration
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (isLoggedIn) {
        // Try to initialize authentication
        await authProvider.initialize();
        
        // If initialization failed, clear the logged in state
        if (!authProvider.isAuthenticated) {
          await prefs.setBool('isLoggedIn', false);
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => authProvider.isAuthenticated
              ? const MainScreen()
              : const LoginScreen(),
        ),
      );
    } catch (e) {
      print('Error during authentication check: $e');
      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(  // ← Added const
      backgroundColor: Colors.purple,
      body: Center(
        child: Column(  // ← Already has const from parent
          mainAxisAlignment: MainAxisAlignment.center,
          children: [  // ← Already has const from parent
            Icon(
              Icons.pets,
              size: 120,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'PawJeevan',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your Pet Care Companion',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 48),
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}