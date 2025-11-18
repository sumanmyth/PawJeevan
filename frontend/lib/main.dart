import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/store_provider.dart';
import 'providers/pet_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/community_provider.dart';
import 'providers/notification_provider.dart';

// Services & Screens
import 'services/api_service.dart';
import 'screens/common/splash_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load any saved authentication token from storage before the app runs
  await ApiService().loadToken();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Defines the light theme for the app
  ThemeData _lightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B46C1),
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      appBarTheme: const AppBarTheme(centerTitle: true),
      // FIX: Changed CardTheme to CardThemeData
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Color(0xFFE9D8FD),
        backgroundColor: Colors.white,
        elevation: 2.0,
      ),
    );
  }

  // Defines the dark theme for the app
  ThemeData _darkTheme() {
    final base = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B46C1),
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(centerTitle: true),
      // FIX: Changed CardTheme to CardThemeData
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Color(0xFF2C2C2C),
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 2.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..loadNotifications()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (_, settings, __) {
          return MaterialApp(
            title: 'PawJeevan',
            debugShowCheckedModeBanner: false,
            theme: _lightTheme(),
            darkTheme: _darkTheme(),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}