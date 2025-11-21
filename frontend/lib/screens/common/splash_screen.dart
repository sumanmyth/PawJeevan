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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6B46C1),
              Color(0xFF9F7AEA),
              Color(0xFFB794F6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Background decorative paw prints
            const Positioned(
              right: -40,
              top: 100,
              child: Opacity(
                opacity: 0.08,
                child: Icon(
                  Icons.pets,
                  size: 200,
                  color: Colors.white,
                ),
              ),
            ),
            const Positioned(
              left: -30,
              bottom: 150,
              child: Opacity(
                opacity: 0.06,
                child: Icon(
                  Icons.pets,
                  size: 160,
                  color: Colors.white,
                ),
              ),
            ),
            const Positioned(
              right: 60,
              bottom: 80,
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.pets,
                  size: 120,
                  color: Colors.white,
                ),
              ),
            ),
            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with gradient background
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // App name with shadow
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      'PawJeevan',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your Pet Care Companion',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 60),
                  // Loading indicator
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}