import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    try {
      await ApiService().loadToken();
      if (ApiService().hasToken) {
        final me = await _auth.getProfile();
        _user = me;
        _error = null;
      } else {
        _user = null;
      }
    } catch (_) {
      _user = null;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Login saves token internally
      await _auth.login(email: email, password: password);
      // Immediately refresh full profile (ensures avatar URL present)
      final me = await _auth.getProfile();
      _user = me;

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
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
      // Register saves token internally
      await _auth.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      // Immediately refresh profile
      final me = await _auth.getProfile();
      _user = me;

      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? location,
  }) async {
    try {
      final updated = await _auth.updateProfile(
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
      _error = e.toString();
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
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } finally {
      _user = null;
      _error = null;
      notifyListeners();
    }
  }

  void updateLocalUser(User updated) {
    _user = updated;
    notifyListeners();
  }
}