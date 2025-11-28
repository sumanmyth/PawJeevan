import '../../utils/constants.dart';

class ProductImage {
  final int id;
  final String image;
  final bool isPrimary;
  final String? altText;

  ProductImage({required this.id, required this.image, required this.isPrimary, this.altText});

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'],
      image: json['image'] ?? '',
      isPrimary: json['is_primary'] ?? false,
      altText: json['alt_text'],
    );
  }
}

class ProductDetail {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? discountPrice;
  final double finalPrice;
  final String? primaryImage;
  final List<ProductImage> images;
  final int stock;
  final String? sku;
  final String? categoryName;
  final String? brandName;
  final String? categoryLogo;
  final String? brandLogo;
  final double? averageRating;
  final String? createdAt;
  final String? petType;
  final double? weight;
  final String? dimensions;

  ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.discountPrice,
    required this.finalPrice,
    this.primaryImage,
    required this.images,
    required this.stock,
    this.sku,
    this.categoryName,
    this.brandName,
    this.categoryLogo,
    this.brandLogo,
    this.averageRating,
    this.createdAt,
    this.petType,
    this.weight,
    this.dimensions,
  });

  factory ProductDetail.fromJson(Map<String, dynamic> json) {
    final imgs = <ProductImage>[];
    if (json['images'] is List) {
      for (final i in json['images']) {
        imgs.add(ProductImage.fromJson(i));
      }
    }

    final price = double.parse(json['price'].toString());
    final discount = json['discount_price'] != null ? double.parse(json['discount_price'].toString()) : null;
    final finalP = discount ?? price;

    return ProductDetail(
      id: json['id'],
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      price: price,
      discountPrice: discount,
      finalPrice: finalP,
      primaryImage: json['primary_image'],
      images: imgs,
      stock: json['stock'] ?? 0,
      sku: json['sku']?.toString(),
      categoryName: json['category_name'],
      brandName: json['brand_name'],
      categoryLogo: _extractLogo(json, 'category', 'category_logo'),
      brandLogo: _extractLogo(json, 'brand', 'brand_logo'),
      averageRating: json['average_rating'] != null ? double.tryParse(json['average_rating'].toString()) : null,
      createdAt: json['created_at'],
      petType: json['pet_type'],
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      dimensions: json['dimensions'],
    );
  }

  // Helper to extract logo URL from multiple possible API shapes.
  static String? _extractLogo(Map<String, dynamic> json, String nestedKey, String flatKey) {
    try {
      // nested object e.g. json['category'] = { 'name': 'Dry food', 'logo': 'https://...' }
      if (json[nestedKey] is Map) {
        final map = json[nestedKey] as Map<String, dynamic>;
        final candidate = map['logo'] ?? map['image'] ?? map['icon'] ?? map['thumbnail'];
        String? extracted;
        if (candidate is Map) {
          // sometimes image is nested like { 'url': '/media/..' }
          extracted = (candidate['url'] ?? candidate['image'] ?? candidate['file'])?.toString();
        } else if (candidate != null) {
          extracted = candidate.toString();
        }
        if (extracted != null) return _normalizeUrl(extracted);
      }
      // flat keys e.g. 'category_logo' or 'brand_logo'
      if (json[flatKey] != null) return _normalizeUrl(json[flatKey]?.toString() ?? '');
      // some APIs may return nested name + image fields like category_image
      final altKey = '${nestedKey}_image';
      if (json[altKey] != null) return _normalizeUrl(json[altKey]?.toString() ?? '');
    } catch (_) {}
    return null;
  }

  static String? _normalizeUrl(String url) {
    if (url.isEmpty) return null;
    final trimmed = url.trim();
    // If it's already absolute, return as-is
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('data:') || trimmed.startsWith('//')) {
      return trimmed;
    }
    // If it's a root-relative path, prefix baseUrl
    if (trimmed.startsWith('/')) {
      return '${ApiConstants.baseUrl}$trimmed';
    }
    // Otherwise, try to prefix with baseUrl + '/'
    return '${ApiConstants.baseUrl}/$trimmed';
  }
}
