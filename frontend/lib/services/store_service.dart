import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../models/pet/adoption_listing_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import '../utils/file_utils.dart';
import '../models/store/product_model.dart';
import '../models/store/product_detail_model.dart';

class StoreService {
  final ApiService _api = ApiService();

  /// Fetch all adoption listings
  Future<List<AdoptionListing>> fetchAdoptions({
    String? petType,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (petType != null && petType != 'all') queryParams['pet_type'] = petType;
      if (status != null) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      debugPrint('Fetching adoptions with params: $queryParams');
      
      final response = await _api.get(
        ApiConstants.adoptions,
        params: queryParams,
      );

      debugPrint('Adoption response status: ${response.statusCode}');
      debugPrint('Adoption response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['results'] ?? []);
        debugPrint('Found ${data.length} adoptions');
        return data.map((json) => AdoptionListing.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching adoptions: $e');
      rethrow;
    }
  }

  /// Fetch products (paginated). Returns a map with keys: count, next, previous, results(List<Product>)
  Future<Map<String, dynamic>> fetchProducts({
    String? petType,
    String? search,
    int page = 1,
    int? categoryId,
    List<int>? categoryIds,
    double? weightMin,
    double? weightMax,
    double? priceMin,
    double? priceMax,
    bool? isFeatured,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (petType != null && petType != 'all') queryParams['pet_type'] = petType;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category'] = categoryId;
      if (categoryIds != null && categoryIds.isNotEmpty) queryParams['category__in'] = categoryIds.join(',');
      if (weightMin != null) queryParams['weight_min'] = weightMin;
      if (weightMax != null) queryParams['weight_max'] = weightMax;
      if (priceMin != null) queryParams['price_min'] = priceMin;
      if (priceMax != null) queryParams['price_max'] = priceMax;
      if (isFeatured != null) queryParams['is_featured'] = isFeatured ? '1' : '0';

      final response = await _api.get(
        ApiConstants.products,
        params: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items = data is List ? data : (data['results'] ?? []);
        final products = items.map((j) => Product.fromJson(j)).toList();
        return {
          'count': data is Map ? data['count'] ?? products.length : products.length,
          'next': data is Map ? data['next'] : null,
          'previous': data is Map ? data['previous'] : null,
          'results': products,
        };
      }
      return {'count': 0, 'next': null, 'previous': null, 'results': <Product>[]};
    } catch (e) {
      debugPrint('Error fetching products: $e');
      rethrow;
    }
  }

  /// Fetch store categories
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final response = await _api.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        final data = response.data is List ? response.data : (response.data['results'] ?? []);
        return List<Map<String, dynamic>>.from(data as List<dynamic>);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Fetch product detail by slug
  Future<ProductDetail?> fetchProductDetail(String slug) async {
    try {
      final response = await _api.get('${ApiConstants.products}$slug/');
      if (response.statusCode == 200) {
        return ProductDetail.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product detail: $e');
      return null;
    }
  }

  /// Fetch current user's wishlist (products + adoptions)
  Future<Map<String, dynamic>?> fetchWishlist() async {
    try {
      final response = await _api.get(ApiConstants.wishlist);
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching wishlist: $e');
      return null;
    }
  }

  /// Toggle product in wishlist
  Future<Map<String, dynamic>?> toggleWishlistProduct(int productId) async {
    try {
      final response = await _api.post('${ApiConstants.wishlist}toggle/', data: {'product_id': productId});
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      debugPrint('Error toggling wishlist product: $e');
      rethrow;
    }
  }

  /// Toggle adoption (pet) in wishlist
  Future<Map<String, dynamic>?> toggleWishlistPet(int petId) async {
    try {
      final response = await _api.post('${ApiConstants.wishlist}toggle_pet/', data: {'pet_id': petId});
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      debugPrint('Error toggling wishlist pet: $e');
      rethrow;
    }
  }

  /// Add product to cart (requires auth)
  Future<bool> addToCart({required int productId, int quantity = 1}) async {
    try {
      final data = {'product_id': productId, 'quantity': quantity};
      final response = await _api.post('${ApiConstants.cart}add_item/', data: data);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  /// Fetch current user's cart
  Future<Map<String, dynamic>?> fetchCart() async {
    try {
      final response = await _api.get(ApiConstants.cart);
      if (response.statusCode == 200) return response.data;
      return null;
    } catch (e) {
      debugPrint('Error fetching cart: $e');
      rethrow;
    }
  }

  /// Update a cart item quantity
  Future<bool> updateCartItem({required int itemId, required int quantity}) async {
    try {
      final data = {'item_id': itemId, 'quantity': quantity};
      final response = await _api.post('${ApiConstants.cart}update_item/', data: data);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating cart item: $e');
      rethrow;
    }
  }

  /// Remove an item from the cart
  Future<bool> removeFromCart({required int itemId}) async {
    try {
      final data = {'item_id': itemId};
      final response = await _api.post('${ApiConstants.cart}remove_item/', data: data);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error removing cart item: $e');
      rethrow;
    }
  }

  /// Clear the cart
  Future<bool> clearCart() async {
    try {
      final response = await _api.post('${ApiConstants.cart}clear/');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  /// Create an order / checkout
  /// Returns the created order data (Map) on success, otherwise null
  Future<Map<String, dynamic>?> createOrder({required Map<String, dynamic> payload}) async {
    try {
      final response = await _api.post(ApiConstants.orders, data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) return Map<String, dynamic>.from(response.data);
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  /// Fetch orders for current user
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final response = await _api.get(ApiConstants.orders);
      if (response.statusCode == 200) {
        final data = response.data is List ? response.data : (response.data['results'] ?? []);
        return List<Map<String, dynamic>>.from(data as List<dynamic>);
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      rethrow;
    }
  }

  /// Fetch single adoption listing by ID
  Future<AdoptionListing?> fetchAdoptionById(int id) async {
    try {
      final response = await _api.get('${ApiConstants.adoptions}$id/');
      if (response.statusCode == 200) {
        return AdoptionListing.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching adoption: $e');
      return null;
    }
  }

  /// Create a new adoption listing
  Future<AdoptionListing?> createAdoption({
    required String title,
    required String petName,
    required String petType,
    required String breed,
    required int age,
    required String gender,
    required String description,
    required String healthStatus,
    required String vaccinationStatus,
    required bool isNeutered,
    required String contactPhone,
    required String contactEmail,
    required String location,
    XFile? photo,
  }) async {
    try {
      final formData = FormData();
      formData.fields.addAll([
        MapEntry('title', title),
        MapEntry('pet_name', petName),
        MapEntry('pet_type', petType),
        MapEntry('breed', breed),
        MapEntry('age', age.toString()),
        MapEntry('gender', gender),
        MapEntry('description', description),
        MapEntry('health_status', healthStatus),
        MapEntry('vaccination_status', vaccinationStatus),
        MapEntry('is_neutered', isNeutered.toString()),
        MapEntry('contact_phone', contactPhone),
        MapEntry('contact_email', contactEmail),
        MapEntry('location', location),
      ]);

      if (photo != null) {
        final mp = await multipartFileFromXFile(photo);
        formData.files.add(MapEntry('photo', mp));
      }

      final response = await _api.post(
        ApiConstants.adoptions,
        data: formData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AdoptionListing.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error creating adoption: $e');
      rethrow;
    }
  }

  /// Update an existing adoption listing
  Future<AdoptionListing?> updateAdoption({
    required int id,
    String? title,
    String? petName,
    String? petType,
    String? breed,
    int? age,
    String? gender,
    String? description,
    String? healthStatus,
    String? vaccinationStatus,
    bool? isNeutered,
    String? contactPhone,
    String? contactEmail,
    String? location,
    String? status,
    XFile? photo,
  }) async {
    try {
      final formData = FormData();
      
      if (title != null) formData.fields.add(MapEntry('title', title));
      if (petName != null) formData.fields.add(MapEntry('pet_name', petName));
      if (petType != null) formData.fields.add(MapEntry('pet_type', petType));
      if (breed != null) formData.fields.add(MapEntry('breed', breed));
      if (age != null) formData.fields.add(MapEntry('age', age.toString()));
      if (gender != null) formData.fields.add(MapEntry('gender', gender));
      if (description != null) formData.fields.add(MapEntry('description', description));
      if (healthStatus != null) formData.fields.add(MapEntry('health_status', healthStatus));
      if (vaccinationStatus != null) formData.fields.add(MapEntry('vaccination_status', vaccinationStatus));
      if (isNeutered != null) formData.fields.add(MapEntry('is_neutered', isNeutered.toString()));
      if (contactPhone != null) formData.fields.add(MapEntry('contact_phone', contactPhone));
      if (contactEmail != null) formData.fields.add(MapEntry('contact_email', contactEmail));
      if (location != null) formData.fields.add(MapEntry('location', location));
      if (status != null) formData.fields.add(MapEntry('status', status));

      if (photo != null) {
        final mp = await multipartFileFromXFile(photo);
        formData.files.add(MapEntry('photo', mp));
      }

      final response = await _api.patch(
        '${ApiConstants.adoptions}$id/',
        data: formData,
      );

      if (response.statusCode == 200) {
        return AdoptionListing.fromJson(response.data);
      }
      return null;
    } catch (e) {
      debugPrint('Error updating adoption: $e');
      rethrow;
    }
  }

  /// Delete an adoption listing
  Future<bool> deleteAdoption(int id) async {
    try {
      final response = await _api.delete('${ApiConstants.adoptions}$id/');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('Error deleting adoption: $e');
      return false;
    }
  }
}
