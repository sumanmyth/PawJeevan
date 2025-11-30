import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store/product_model.dart';
import '../models/pet/adoption_listing_model.dart';
import '../models/store/category_model.dart';
import '../services/store_service.dart';

class StoreProvider extends ChangeNotifier {
  final StoreService _storeService = StoreService();

  List<Product> _products = [];
  List<Product> _wishlistProducts = [];
  List<AdoptionListing> _adoptions = [];
  bool _isLoading = false;
  String? _error;
  String _selectedPetType = 'all';
  String _selectedLocationFilter = 'all'; // values: all, my_location, my_city, my_country
  String _searchQuery = '';
  Set<int> _favoritePetIds = {};
  Set<int> _favoriteProductIds = {};
  List<Category> _storeCategories = [];
  Set<int> _selectedStoreCategoryIds = {};
  // Product-specific filters
  String _selectedProductPetType = 'all';
  double _productWeightMin = 0.0;
  double _productWeightMax = 200.0;
  double _productPriceMin = 0.0;
  double _productPriceMax = 10000.0;

  List<Product> get products => _products;
  List<Product> get wishlistProducts => _wishlistProducts;
  List<AdoptionListing> get adoptions => _adoptions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedPetType => _selectedPetType;
  String get selectedLocationFilter => _selectedLocationFilter;
  String get searchQuery => _searchQuery;
  Set<int> get favoritePetIds => _favoritePetIds;
  Set<int> get favoriteProductIds => _favoriteProductIds;
  List<Category> get storeCategories => _storeCategories;
  Set<int> get selectedStoreCategoryIds => _selectedStoreCategoryIds;
  String get selectedProductPetType => _selectedProductPetType;
  double get productWeightMin => _productWeightMin;
  double get productWeightMax => _productWeightMax;
  double get productPriceMin => _productPriceMin;
  double get productPriceMax => _productPriceMax;
  List<Product> _featuredProducts = [];
  List<Product> get featuredProducts => _featuredProducts;
  
  List<AdoptionListing> get favoritePets {
    return _adoptions.where((pet) => _favoritePetIds.contains(pet.id)).toList();
  }

  StoreProvider() {
    _loadFavoritePets();
    _loadFavoriteProducts();
    // Kick off a background sync from server to reconcile any server-side wishlist state.
    _syncFavoritesFromServer();
    // Load categories for the store filters
    loadCategories().catchError((_) {});
  }

  /// Attempt to fetch the user's wishlist from server and merge into local favorites.
  Future<void> _syncFavoritesFromServer() async {
    try {
      final data = await _storeService.fetchWishlist();
      if (data != null) {
        // Expecting server response like: { 'products': [ {id:..}, ... ], 'adoptions': [...] }
        final serverProducts = <int>{};
        final serverPets = <int>{};

        try {
          final prodList = data['products'] as List<dynamic>? ?? [];
          for (final p in prodList) {
            if (p is Map && p['id'] != null) serverProducts.add(p['id'] as int);
          }
        } catch (_) {}

        try {
          final petList = data['adoptions'] as List<dynamic>? ?? [];
          for (final p in petList) {
            if (p is Map && p['id'] != null) serverPets.add(p['id'] as int);
          }
        } catch (_) {}

        // Replace local sets with server's authoritative sets to avoid divergence.
        _favoriteProductIds = serverProducts;
        _favoritePetIds = serverPets;
        // Also store the product objects returned by the wishlist endpoint so
        // UI can render favorites even if the global product list doesn't contain them.
        try {
          final prodList = data['products'] as List<dynamic>? ?? [];
          final List<Product> items = prodList.map((j) => Product.fromJson(j as Map<String, dynamic>)).toList();
          _wishlistProducts = items;
        } catch (_) {
          _wishlistProducts = [];
        }
        await _saveFavoriteProducts();
        await _saveFavoritePets();
        notifyListeners();
      }
    } catch (e) {
      // Ignore sync errors for now; keep local state.
      debugPrint('Error syncing favorites from server: $e');
    }
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

  Future<void> _saveFavoriteProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = _favoriteProductIds.map((id) => id.toString()).toList();
    await prefs.setStringList('favorite_product_ids', favoriteIds);
  }

  Future<void> _loadFavoriteProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_product_ids') ?? [];
    _favoriteProductIds = favoriteIds.map((id) => int.parse(id)).toSet();
    notifyListeners();
  }

  bool isPetFavorite(int petId) {
    return _favoritePetIds.contains(petId);
  }

  bool isProductFavorite(int productId) {
    return _favoriteProductIds.contains(productId);
  }

  Future<void> togglePetFavorite(int petId) async {
    final wasFavorite = _favoritePetIds.contains(petId);
    // Optimistic update
    if (wasFavorite) {
      _favoritePetIds.remove(petId);
    } else {
      _favoritePetIds.add(petId);
    }
    await _saveFavoritePets();
    notifyListeners();

    try {
      await _storeService.toggleWishlistPet(petId);
    } catch (e) {
      // Rollback on error
      if (wasFavorite) {
        _favoritePetIds.add(petId);
      } else {
        _favoritePetIds.remove(petId);
      }
      await _saveFavoritePets();
      _error = 'Failed to update wishlist: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> toggleProductFavorite(int productId) async {
    final wasFavorite = _favoriteProductIds.contains(productId);
    // Optimistic update
    if (wasFavorite) {
      _favoriteProductIds.remove(productId);
    } else {
      _favoriteProductIds.add(productId);
    }
    await _saveFavoriteProducts();
    notifyListeners();

    try {
      await _storeService.toggleWishlistProduct(productId);
    } catch (e) {
      // Rollback on error
      if (wasFavorite) {
        _favoriteProductIds.add(productId);
      } else {
        _favoriteProductIds.remove(productId);
      }
      await _saveFavoriteProducts();
      _error = 'Failed to update wishlist: ${e.toString()}';
      notifyListeners();
    }
  }

  void setSelectedPetType(String petType, {bool skipReload = false}) {
    _selectedPetType = petType;
    notifyListeners();
    if (!skipReload) {
      loadAdoptions();
    }
  }

  /// Set location filter and notify. Valid values: 'all', 'my_location', 'my_city', 'my_country'
  void setLocationFilter(String filter) {
    _selectedLocationFilter = filter;
    notifyListeners();
  }

  /// Return adoptions filtered by the current location filter using the provided userLocation string.
  /// `userLocation` is expected to be a single string (e.g. "City, Country") or null.
  List<AdoptionListing> filteredAdoptionsForLocation(String? userLocation) {
    if (_selectedLocationFilter == 'all' || userLocation == null || userLocation.trim().isEmpty) {
      return _adoptions;
    }

    final userLoc = userLocation.trim();
    String? userCity;
    String? userCountry;
    final parts = userLoc.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) userCity = parts.first;
    if (parts.length > 1) userCountry = parts.last;

    switch (_selectedLocationFilter) {
      // Treat 'my_location' same as 'my_city' (user indicated they are the same)
      case 'my_location':
      case 'my_city':
        if (userCity == null) return _adoptions;
        return _adoptions.where((a) => a.location.split(',').first.trim() == userCity).toList();
      case 'my_country':
        if (userCountry == null) return _adoptions;
        return _adoptions.where((a) => a.location.split(',').last.trim() == userCountry).toList();
      default:
        return _adoptions;
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
      final categoryIds = _selectedStoreCategoryIds.isEmpty ? null : _selectedStoreCategoryIds.toList();
      final result = await _storeService.fetchProducts(
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        categoryIds: categoryIds,
        petType: _selectedProductPetType == 'all' ? null : _selectedProductPetType,
        weightMin: _productWeightMin,
        weightMax: _productWeightMax,
        priceMin: _productPriceMin,
        priceMax: _productPriceMax,
      );

      final List<Product> products = List<Product>.from(result['results'] ?? []);
      // Randomize shop product order so the Shop view appears fresh each load
      products.shuffle();
      _products = products;
      _error = null;
      // Also load featured products for the current category/filter selection
      await loadFeaturedProducts();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load featured products. When [ignoreFilters] is true, do not apply
  /// category/petType filters so callers (e.g. Home tab) get a global set.
  Future<void> loadFeaturedProducts({bool ignoreFilters = false}) async {
    try {
      final categoryIds = (!ignoreFilters && _selectedStoreCategoryIds.isNotEmpty)
          ? _selectedStoreCategoryIds.toList()
          : null;
      final petType = (!ignoreFilters && _selectedProductPetType != 'all')
          ? _selectedProductPetType
          : null;

      final result = await _storeService.fetchProducts(
        page: 1,
        categoryIds: categoryIds,
        petType: petType,
        isFeatured: true,
      );

      final List<Product> items = List<Product>.from(result['results'] ?? []);
      // Randomize featured products order each time they're loaded
      items.shuffle();
      _featuredProducts = items;
      // Notify listeners so UI (e.g. Home tab) updates when featured products arrive
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading featured products: $e');
      _featuredProducts = [];
      notifyListeners();
    }
  }

  Future<void> loadCategories() async {
    try {
      final raw = await _storeService.fetchCategories();
      _storeCategories = raw.map((j) => Category.fromJson(j)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  void setSelectedStoreCategoryIds(Set<int> ids, {bool skipLoad = false}) {
    _selectedStoreCategoryIds = ids;
    notifyListeners();
    if (!skipLoad) loadProducts();
  }

  /// Set product-specific pet type filter
  void setSelectedProductPetType(String petType, {bool skipLoad = false}) {
    _selectedProductPetType = petType;
    notifyListeners();
    if (!skipLoad) loadProducts();
  }

  /// Set product weight range (kilograms)
  void setProductWeightRange(double minKg, double maxKg, {bool skipLoad = false}) {
    _productWeightMin = minKg;
    _productWeightMax = maxKg;
    notifyListeners();
    if (!skipLoad) loadProducts();
  }

  /// Set product price range
  void setProductPriceRange(double minPrice, double maxPrice, {bool skipLoad = false}) {
    _productPriceMin = minPrice;
    _productPriceMax = maxPrice;
    notifyListeners();
    if (!skipLoad) loadProducts();
  }

  /// Set multiple product filters at once
  void setProductFilters({String? petType, double? weightMin, double? weightMax, double? priceMin, double? priceMax, bool skipLoad = false}) {
    if (petType != null) _selectedProductPetType = petType;
    if (weightMin != null) _productWeightMin = weightMin;
    if (weightMax != null) _productWeightMax = weightMax;
    if (priceMin != null) _productPriceMin = priceMin;
    if (priceMax != null) _productPriceMax = priceMax;
    notifyListeners();
    if (!skipLoad) loadProducts();
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
        // When showAllStatuses is false (Discover), don't send a status param so
        // backend default (available + pending) applies. When true, request 'all'.
        status: showAllStatuses ? 'all' : null,
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