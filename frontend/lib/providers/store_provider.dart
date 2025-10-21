import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class StoreProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get(ApiConstants.products);
      if (response.statusCode == 200) {
        final List<dynamic> results = response.data['results'] ?? [];
        _products = results.map((json) => Product.fromJson(json)).toList();
        _error = null;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}