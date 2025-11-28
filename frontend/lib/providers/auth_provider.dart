import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/social_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final refreshToken = prefs.getString('refresh_token');
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      if (token != null && refreshToken != null && isLoggedIn) {
        // Restore the tokens
        await _api.saveToken(token, refreshToken: refreshToken);
        
        try {
          // Try to get user profile
          _user = await _auth.getProfile();
          // Save user ID for future use
          await prefs.setInt('user_id', _user!.id);
          _error = null;
        } catch (e) {
          print('Failed to get profile: $e');
          await _clearAuthState();
        }
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      print('Auth initialization error: $e');
      await _clearAuthState();
    } finally {
      notifyListeners();
    }
  }

  Future<void> _clearAuthState() async {
    _user = null;
    _error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('user_id');
    await _api.clearTokens();
  }

  String _friendlyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('invalid') && s.contains('credential')) return 'Invalid credentials';
    if (s.contains('unauthorized') || s.contains('401')) return 'Invalid credentials';
    if (s.contains('network') || s.contains('socket') || s.contains('timeout')) return 'Network error';
    if (s.contains('not found') || s.contains('404')) return 'Not found';
    return 'Something went wrong';
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _auth.login(email: email, password: password);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('user_id', _user!.id);

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      await _clearAuthState();
      _error = _friendlyError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // 1. Sign out from Google (This now handles disconnect internally)
      try {
        final social = SocialAuthService();
        await social.signOut(); 
      } catch (e) {
        print('Social sign-out error: $e');
      }

      // 2. Clear local app state
      await _clearAuthState();
    } catch (e) {
      print('Logout error: $e');
    } finally {
      notifyListeners();
    }
  }

  Future<bool> loginWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final social = SocialAuthService();
      final idToken = await social.signInWithGoogle();

      _user = await _auth.socialLoginGoogle(idToken: idToken);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setInt('user_id', _user!.id);

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Google login error: $e');
      await _clearAuthState();
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<dynamic> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _auth.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      // If tokens were returned and saved by the service, try to fetch profile
      if (result.containsKey('tokens') && result['tokens'] != null) {
        try {
          _user = await _auth.getProfile();
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('user_id', _user!.id);
        } catch (e) {
          // ignore profile fetch errors here
        }
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('Registration error: $e');
      await _clearAuthState();
      // Surface backend validation message directly for registration failures
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? location,
  }) async {
    try {
      final updated = await _auth.updateProfile(
        username: username,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        bio: bio,
        location: location,
      );
      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAvatar({
    String? imagePath,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    try {
      final updated = await _auth.updateAvatar(
        imagePath: imagePath,
        imageBytes: imageBytes,
        fileName: fileName,
      );
      _user = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  void updateLocalUser(User updated) {
    _user = updated;
    notifyListeners();
  }

  /// Clear any stored error message and notify listeners.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}