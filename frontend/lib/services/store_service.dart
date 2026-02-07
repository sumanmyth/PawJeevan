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
      if (petType != null && petType != 'all') {
        queryParams['pet_type'] = petType;
      }
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
      if (petType != null && petType != 'all') {
        queryParams['pet_type'] = petType;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (categoryId != null) queryParams['category'] = categoryId;
      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['category__in'] = categoryIds.join(',');
      }
      if (weightMin != null) queryParams['weight_min'] = weightMin;
      if (weightMax != null) queryParams['weight_max'] = weightMax;
      if (priceMin != null) queryParams['price_min'] = priceMin;
      if (priceMax != null) queryParams['price_max'] = priceMax;
      if (isFeatured != null) {
        queryParams['is_featured'] = isFeatured ? '1' : '0';
      }

      final response = await _api.get(
        ApiConstants.products,
        params: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> items =
            data is List ? data : (data['results'] ?? []);
        final products = items.map((j) => Product.fromJson(j)).toList();
        return {
          'count':
              data is Map ? data['count'] ?? products.length : products.length,
          'next': data is Map ? data['next'] : null,
          'previous': data is Map ? data['previous'] : null,
          'results': products,
        };
      }
      return {
        'count': 0,
        'next': null,
        'previous': null,
        'results': <Product>[]
      };
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
        final data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
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

  /// Fetch a product by numeric id via the products list endpoint.
  /// Some backends don't expose an ID-based detail route; this queries
  /// the list endpoint with `?id=` and returns the first matching product.
  Future<ProductDetail?> fetchProductById(int id) async {
    try {
      final response = await _api.get('${ApiConstants.products}?id=$id');
      if (response.statusCode == 200) {
        final data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final items = data as List<dynamic>;
        if (items.isNotEmpty) return ProductDetail.fromJson(items[0]);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching product by id: $e');
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
      final response = await _api.post('${ApiConstants.wishlist}toggle/',
          data: {'product_id': productId});
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
      final response = await _api
          .post('${ApiConstants.wishlist}toggle_pet/', data: {'pet_id': petId});
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
      final response =
          await _api.post('${ApiConstants.cart}add_item/', data: data);
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
  Future<bool> updateCartItem(
      {required int itemId, required int quantity}) async {
    try {
      final data = {'item_id': itemId, 'quantity': quantity};
      final response =
          await _api.post('${ApiConstants.cart}update_item/', data: data);
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
      final response =
          await _api.post('${ApiConstants.cart}remove_item/', data: data);
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
  Future<Map<String, dynamic>?> createOrder(
      {required Map<String, dynamic> payload}) async {
    try {
      final response = await _api.post(ApiConstants.orders, data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error creating order: $e');
      return null;
    }
  }

  /// Create a review for a product.
  /// Returns the created review map on success, otherwise null.
  Future<Map<String, dynamic>?> createReview({
    required int productId,
    required int rating,
    String? title,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{
        'product_id': productId,
        'rating': rating,
      };
      if (title != null) data['title'] = title;
      if (comment != null) data['comment'] = comment;

      final response = await _api.post(ApiConstants.reviews, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error creating review: $e');
      rethrow;
    }
  }

  /// Update an existing review (partial allowed). Returns updated review map on success.
  Future<Map<String, dynamic>?> updateReview({
    required int reviewId,
    int? rating,
    String? title,
    String? comment,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (rating != null) data['rating'] = rating;
      if (title != null) data['title'] = title;
      if (comment != null) data['comment'] = comment;

      final response =
          await _api.patch('${ApiConstants.reviews}$reviewId/', data: data);
      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response.data);
        }
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('Error updating review: $e');
      rethrow;
    }
  }

  /// Fetch all reviews for a given product
  Future<List<Map<String, dynamic>>> fetchReviewsForProduct(
      int productId) async {
    try {
      final response =
          await _api.get('${ApiConstants.reviews}?product=$productId');
      if (response.statusCode == 200) {
        final data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return List<Map<String, dynamic>>.from(data as List<dynamic>);
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('Error fetching product reviews: $e');
      rethrow;
    }
  }

  /// Toggle a review as helpful (server will toggle and return marked state)
  /// Returns a map with keys: 'helpful_count' (int) and 'marked' (bool) on success, otherwise null.
  Future<Map<String, dynamic>?> markReviewHelpful(int reviewId) async {
    try {
      final response =
          await _api.post('${ApiConstants.reviews}$reviewId/helpful/');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final count = data['helpful_count'] is int
            ? data['helpful_count'] as int
            : int.tryParse(data['helpful_count']?.toString() ?? '0');
        final marked = data['marked'] == true;
        return {'helpful_count': count, 'marked': marked};
      }
      return null;
    } catch (e) {
      debugPrint('Error marking review helpful: $e');
      rethrow;
    }
  }

  /// Fetch orders for current user
  Future<List<Map<String, dynamic>>> fetchOrders() async {
    try {
      final response = await _api.get(ApiConstants.orders);
      if (response.statusCode == 200) {
        final data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return List<Map<String, dynamic>>.from(data as List<dynamic>);
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('Error fetching orders: $e');
      rethrow;
    }
  }

  /// Check whether the current user has any delivered order containing the product
  Future<bool> isProductVerifiedPurchase(int productId) async {
    try {
      final orders = await fetchOrders();
      for (final order in orders) {
        // Consider delivered if status looks like 'delivered' or if delivered_at present
        final status = (order['status'] ?? '').toString().toLowerCase();
        final deliveredAt = order['delivered_at'];
        final bool isDelivered = status.contains('deliv') ||
            (deliveredAt != null && deliveredAt.toString().isNotEmpty);
        if (isDelivered) {
          final items = order['items'] is List
              ? order['items'] as List<dynamic>
              : <dynamic>[];
          for (final it in items) {
            try {
              if (it == null) continue;
              dynamic prod;
              if (it is Map) {
                if (it.containsKey('product')) {
                  prod = it['product'];
                } else if (it.containsKey('product_id'))
                  prod = it['product_id'];
                else
                  prod = null;
              } else {
                prod = null;
              }

              if (prod == null) continue;
              if (prod is Map) {
                final idVal = prod['id'] ?? prod['pk'] ?? prod['product_id'];
                final idInt = idVal is int
                    ? idVal
                    : int.tryParse(idVal?.toString() ?? '');
                if (idInt != null && idInt == productId) return true;
              } else if (prod is int) {
                if (prod == productId) return true;
              } else {
                final parsed = int.tryParse(prod.toString());
                if (parsed != null && parsed == productId) return true;
              }
            } catch (e) {
              // ignore item parsing errors
            }
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking verified purchase: $e');
      return false;
    }
  }

  /// Check whether the current user already reviewed this product
  Future<bool> hasUserReviewedProduct(int productId, int userId) async {
    try {
      final response =
          await _api.get('${ApiConstants.reviews}?product=$productId');
      if (response.statusCode == 200) {
        final data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        final items = List<Map<String, dynamic>>.from(data as List<dynamic>);
        for (final r in items) {
          try {
            if (r['user'] != null && r['user'] == userId) return true;
          } catch (e) {
            // ignore
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error fetching reviews for check: $e');
      rethrow;
    }
  }

  /// Fetch reviews for the current user (or optionally filter by user id)
  Future<List<Map<String, dynamic>>> fetchUserReviews({int? userId}) async {
    try {
      final params = userId != null ? {'user': userId} : null;
      final uri = userId != null
          ? '${ApiConstants.reviews}?user=$userId'
          : ApiConstants.reviews;
      final response = await _api.get(uri, params: params);
      if (response.statusCode == 200) {
        final data = response.data is List
            ? response.data
            : (response.data['results'] ?? []);
        return List<Map<String, dynamic>>.from(data as List<dynamic>);
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      debugPrint('Error fetching user reviews: $e');
      rethrow;
    }
  }

  /// Return a list of purchased products (from delivered orders) that the user
  /// can potentially review. If `userId` is provided, exclude products the
  /// user has already reviewed.
  Future<List<Map<String, dynamic>>> getEligibleProductsForReview(
      {int? userId}) async {
    try {
      final orders = await fetchOrders();
      final Map<int, Map<String, dynamic>> found = {};

      for (final order in orders) {
        final status = (order['status'] ?? '').toString().toLowerCase();
        final deliveredAt = order['delivered_at'];
        final bool isDelivered = status.contains('deliv') ||
            (deliveredAt != null && deliveredAt.toString().isNotEmpty);
        if (!isDelivered) continue;

        final items =
            order['items'] is List ? order['items'] as List : <dynamic>[];
        for (final it in items) {
          try {
            if (it == null) continue;
            dynamic prod;
            if (it is Map) {
              if (it.containsKey('product')) {
                prod = it['product'];
              } else if (it.containsKey('product_id'))
                prod = it['product_id'];
              else
                prod = null;
            } else {
              prod = null;
            }
            if (prod == null) continue;

            int? id;
            String label = '';
            String? thumb;

            if (prod is Map) {
              final idVal = prod['id'] ?? prod['pk'] ?? prod['product_id'];
              id = idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
              label = (prod['title'] ?? prod['name'] ?? prod['slug'] ?? '')
                  .toString();
              thumb =
                  (prod['thumbnail'] ?? prod['image'] ?? prod['photo'] ?? '')
                      ?.toString();
            } else if (prod is int) {
              id = prod;
            } else {
              id = int.tryParse(prod.toString());
            }

            if (id == null) continue;
            if (!found.containsKey(id)) {
              found[id] = {
                'id': id,
                'label': label.isNotEmpty ? label : 'Product #$id',
                'thumbnail': thumb
              };
            }
          } catch (e) {
            // ignore individual item parsing errors
          }
        }
      }

      var products = found.values.toList();

      // Exclude already-reviewed products if userId provided
      if (userId != null) {
        try {
          final reviewed = await fetchUserReviews(userId: userId);
          final Set<int> rids = {};
          for (final r in reviewed) {
            try {
              final p = r['product'];
              if (p == null) continue;
              if (p is Map) {
                final idVal = p['id'] ?? p['pk'] ?? p['product_id'];
                final parsed = idVal is int
                    ? idVal
                    : int.tryParse(idVal?.toString() ?? '');
                if (parsed != null) rids.add(parsed);
              } else if (p is int) {
                rids.add(p);
              } else {
                final parsed = int.tryParse(p.toString());
                if (parsed != null) rids.add(parsed);
              }
            } catch (e) {}
          }
          products =
              products.where((p) => !rids.contains(p['id'] as int)).toList();
        } catch (e) {
          // If we fail to fetch reviews, just return the purchased products (safer UX)
          debugPrint('Failed to filter reviewed products: $e');
        }
      }

      return List<Map<String, dynamic>>.from(products);
    } catch (e) {
      debugPrint('Error getting eligible products for review: $e');
      return <Map<String, dynamic>>[];
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
      if (description != null) {
        formData.fields.add(MapEntry('description', description));
      }
      if (healthStatus != null) {
        formData.fields.add(MapEntry('health_status', healthStatus));
      }
      if (vaccinationStatus != null) {
        formData.fields.add(MapEntry('vaccination_status', vaccinationStatus));
      }
      if (isNeutered != null) {
        formData.fields.add(MapEntry('is_neutered', isNeutered.toString()));
      }
      if (contactPhone != null) {
        formData.fields.add(MapEntry('contact_phone', contactPhone));
      }
      if (contactEmail != null) {
        formData.fields.add(MapEntry('contact_email', contactEmail));
      }
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
