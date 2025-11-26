import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/fact_provider.dart';
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
  
  // Load runtime config (e.g., GOOGLE_CLIENT_ID) from backend before app runs
  await ConfigService.init();

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
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF7C3AED),
        selectionColor: Color(0x337C3AED),
        selectionHandleColor: Color(0xFF7C3AED),
      ),
      scaffoldBackgroundColor: const Color(0xFFF7FAFC),
      appBarTheme: const AppBarTheme(centerTitle: true),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
        prefixIconColor: const Color(0xFF7C3AED),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF7C3AED)),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(8.0),
          shadowColor: const WidgetStatePropertyAll(Color.fromRGBO(124, 58, 237, 0.4)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
      ),
      // FIX: Changed CardTheme to CardThemeData
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Color(0xFF7C3AED),
        backgroundColor: Colors.white,
        elevation: 2.0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Defines the dark theme for the app
  ThemeData _darkTheme() {
    final base = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7C3AED),
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Color(0xFF7C3AED),
        selectionColor: Color(0x337C3AED),
        selectionHandleColor: Color(0xFF7C3AED),
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(centerTitle: true),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[800],
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[700]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color.fromRGBO(124, 58, 237, 0.95), width: 2),
        ),
        prefixIconColor: const Color(0xFF7C3AED),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: const WidgetStatePropertyAll(Color(0xFF7C3AED)),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(8.0),
          shadowColor: const WidgetStatePropertyAll(Color.fromRGBO(107, 70, 193, 0.4)),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 14, horizontal: 20)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED)),
      ),
      // FIX: Changed CardTheme to CardThemeData
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Color(0xFF7C3AED),
        backgroundColor: Color(0xFF1A1A1A),
        elevation: 2.0,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FactProvider()),
        ChangeNotifierProvider(create: (_) => StoreProvider()),
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..init()),
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