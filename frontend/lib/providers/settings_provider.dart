import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  // Keys
  static const _kPush = 'push_notifications';
  static const _kPromo = 'promo_notifications';
  static const _kNewProduct = 'new_product_notifications';
  static const _kDarkMode = 'dark_mode';
  static const _kLanguage = 'language';
  static const _kPaymentMethod = 'payment_method';

  // Defaults
  bool _pushNotifications = true;
  bool _promoNotifications = true;
  bool _newProductNotifications = true;
  bool _darkMode = false;
  String _language = 'English';
  String _paymentMethod = 'Card';

  bool get pushNotifications => _pushNotifications;
  bool get promoNotifications => _promoNotifications;
  bool get newProductNotifications => _newProductNotifications;
  bool get darkMode => _darkMode;
  String get language => _language;
  String get paymentMethod => _paymentMethod;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _pushNotifications = prefs.getBool(_kPush) ?? true;
    _promoNotifications = prefs.getBool(_kPromo) ?? true;
    _newProductNotifications = prefs.getBool(_kNewProduct) ?? true;
    _darkMode = prefs.getBool(_kDarkMode) ?? false;
    _language = prefs.getString(_kLanguage) ?? 'English';
    _paymentMethod = prefs.getString(_kPaymentMethod) ?? 'Card';
    notifyListeners();
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