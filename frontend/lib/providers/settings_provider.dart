import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class SettingsProvider extends ChangeNotifier {
  // Keys
  static const _kPush = 'push_notifications';
  static const _kPromo = 'promo_notifications';
  static const _kNewProduct = 'new_product_notifications';
  static const _kDarkMode = 'dark_mode';
  static const _kLanguage = 'language';
  static const _kPaymentMethod = 'payment_method';
  static const _kProfileLocked = 'profile_locked';

  final UserService _userService = UserService();

  // Defaults
  bool _pushNotifications = true;
  bool _promoNotifications = true;
  bool _newProductNotifications = true;
  bool _darkMode = false;
  bool _profileLocked = false;
  String _language = 'English';
  // store payment method as an internal code; default to COD for now
  String _paymentMethod = 'COD';

  bool get pushNotifications => _pushNotifications;
  bool get promoNotifications => _promoNotifications;
  bool get newProductNotifications => _newProductNotifications;
  bool get darkMode => _darkMode;
  bool get profileLocked => _profileLocked;
  String get language => _language;
  String get paymentMethod => _paymentMethod;

  /// Human-friendly label for the currently selected payment method
  String get paymentMethodLabel {
    switch (_paymentMethod) {
      case 'COD':
        return 'Cash on delivery';
      default:
        return _paymentMethod;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool(_kPush) ?? true;
    _promoNotifications = prefs.getBool(_kPromo) ?? true;
    _newProductNotifications = prefs.getBool(_kNewProduct) ?? true;
    _darkMode = prefs.getBool(_kDarkMode) ?? false;
    _profileLocked = prefs.getBool(_kProfileLocked) ?? false;
    _language = prefs.getString(_kLanguage) ?? 'English';
    _paymentMethod = prefs.getString(_kPaymentMethod) ?? 'COD';
    notifyListeners();
  }

  /// Update profile locked state from user profile data
  void syncProfileLocked(bool value) {
    if (_profileLocked != value) {
      _profileLocked = value;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool(_kProfileLocked, value);
      });
      notifyListeners();
    }
  }

  Future<void> setPushNotifications(bool value) async {
    _pushNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPush, value);
    notifyListeners();
  }

  Future<void> setPromoNotifications(bool value) async {
    _promoNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPromo, value);
    notifyListeners();
  }

  Future<void> setNewProductNotifications(bool value) async {
    _newProductNotifications = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNewProduct, value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkMode, value);
    notifyListeners();
  }

  Future<void> setProfileLocked(bool value) async {
    try {
      // Update on backend
      await _userService.updateProfile({'is_profile_locked': value});
      
      // Update locally
      _profileLocked = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kProfileLocked, value);
      notifyListeners();
    } catch (e) {
      // Revert on error
      notifyListeners();
      rethrow;
    }
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, value);
    notifyListeners();
  }

  Future<void> setPaymentMethod(String value) async {
    _paymentMethod = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPaymentMethod, value);
    notifyListeners();
  }
}