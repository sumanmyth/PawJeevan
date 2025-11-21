import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store/product_model.dart';
import '../models/pet/adoption_listing_model.dart';
import '../services/api_service.dart';
import '../services/store_service.dart';
import '../utils/constants.dart';

class StoreProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StoreService _storeService = StoreService();

  List<Product> _products = [];
  List<AdoptionListing> _adoptions = [];
  bool _isLoading = false;
  String? _error;
  String _selectedPetType = 'all';
  String _searchQuery = '';
  Set<int> _favoritePetIds = {};

  List<Product> get products => _products;
  List<AdoptionListing> get adoptions => _adoptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedPetType => _selectedPetType;
  String get searchQuery => _searchQuery;
  Set<int> get favoritePetIds => _favoritePetIds;
  
  List<AdoptionListing> get favoritePets {
    return _adoptions.where((pet) => _favoritePetIds.contains(pet.id)).toList();
  }

  StoreProvider() {
    _loadFavoritePets();
  }

  Future<void> _loadFavoritePets() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_pet_ids') ?? [];
    _favoritePetIds = favoriteIds.map((id) => int.parse(id)).toSet();
    notifyListeners();
  }

  Future<void> _saveFavoritePets() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = _favoritePetIds.map((id) => id.toString()).toList();
    await prefs.setStringList('favorite_pet_ids', favoriteIds);
  }

  bool isPetFavorite(int petId) {
    return _favoritePetIds.contains(petId);
  }

  Future<void> togglePetFavorite(int petId) async {
    if (_favoritePetIds.contains(petId)) {
      _favoritePetIds.remove(petId);
    } else {
      _favoritePetIds.add(petId);
    }
    await _saveFavoritePets();
    notifyListeners();
  }

  void setSelectedPetType(String petType, {bool skipReload = false}) {
    _selectedPetType = petType;
    notifyListeners();
    if (!skipReload) {
      loadAdoptions();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> searchAdoptions() async {
    await loadAdoptions();
  }

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

  Future<void> loadAdoptions({bool showAllStatuses = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('StoreProvider: Loading adoptions...');
      _adoptions = await _storeService.fetchAdoptions(
        petType: _selectedPetType == 'all' ? null : _selectedPetType,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        status: showAllStatuses ? 'all' : 'available',
      );
      print('StoreProvider: Loaded ${_adoptions.length} adoptions');
      _error = null;
    } catch (e) {
      print('StoreProvider: Error loading adoptions: $e');
      _error = e.toString();
      _adoptions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createAdoption(AdoptionListing listing, dynamic photo) async {
    try {
      final result = await _storeService.createAdoption(
        title: listing.title,
        petName: listing.petName,
        petType: listing.petType,
        breed: listing.breed,
        age: listing.age,
        gender: listing.gender,
        description: listing.description,
        healthStatus: listing.healthStatus,
        vaccinationStatus: listing.vaccinationStatus,
        isNeutered: listing.isNeutered,
        contactPhone: listing.contactPhone,
        contactEmail: listing.contactEmail,
        location: listing.location,
        photo: photo,
      );
      
      if (result != null) {
        // Don't auto-reload here, let the caller decide with appropriate filter
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAdoption(AdoptionListing listing, dynamic photo) async {
    try {
      final result = await _storeService.updateAdoption(
        id: listing.id,
        title: listing.title,
        petName: listing.petName,
        petType: listing.petType,
        breed: listing.breed,
        age: listing.age,
        gender: listing.gender,
        description: listing.description,
        healthStatus: listing.healthStatus,
        vaccinationStatus: listing.vaccinationStatus,
        isNeutered: listing.isNeutered,
        contactPhone: listing.contactPhone,
        contactEmail: listing.contactEmail,
        location: listing.location,
        status: listing.status,
        photo: photo,
      );
      
      if (result != null) {
        // Don't auto-reload here, let the caller decide with appropriate filter
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateAdoptionStatus(int id, String status) async {
    try {
      final result = await _storeService.updateAdoption(
        id: id,
        status: status,
      );
      // Check if update was successful
      if (result == null) {
        _error = 'Failed to update adoption status';
        notifyListeners();
        return false;
      }
      // Don't auto-reload here, let the caller decide with appropriate filter
      return true;
    } catch (e) {
      print('Error updating adoption status: $e');
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAdoption(int id) async {
    try {
      await _storeService.deleteAdoption(id);
      await loadAdoptions();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}