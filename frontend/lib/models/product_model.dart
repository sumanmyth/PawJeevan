class Product {
  final int id;
  final String name;
  final String slug;
  final double price;
  final double? discountPrice;
  final String? primaryImage;
  final String? categoryName;
  final String? brandName;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    this.discountPrice,
    this.primaryImage,
    this.categoryName,
    this.brandName,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      price: double.parse(json['price'].toString()),
      discountPrice: json['discount_price'] != null
          ? double.parse(json['discount_price'].toString())
          : null,
      primaryImage: json['primary_image'],
      categoryName: json['category_name'],
      brandName: json['brand_name'],
      stock: json['stock'] ?? 0,
    );
  }

  double get finalPrice => discountPrice ?? price;
  bool get hasDiscount => discountPrice != null && discountPrice! < price;
  int get discountPercent => hasDiscount
      ? (((price - discountPrice!) / price) * 100).round()
      : 0;
}