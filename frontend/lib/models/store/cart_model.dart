class CartItem {
  final int id;
  final int productId;
  final String? productSlug;
  final String productName;
  final double productPrice;
  int quantity;
  final String? imageUrl;

  CartItem({
    required this.id,
    required this.productId,
    this.productSlug,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Helper to safely extract an int ID from various shapes
    int extractId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      if (val is Map) {
        // common keys
        if (val['id'] != null) return extractId(val['id']);
        if (val['pk'] != null) return extractId(val['pk']);
      }
      return 0;
    }

    String extractName(dynamic productField) {
      if (productField == null) return 'Product';
      if (productField is String) return productField;
      if (productField is Map) {
        final n = productField['name'] ?? productField['title'] ?? productField['product_name'];
        if (n is String) return n;
      }
      return 'Product';
    }

    double extractPrice(dynamic json, dynamic productField) {
      // try direct fields first
      final cand = json['product_price'] ?? json['price'] ?? json['unit_price'];
      if (cand != null) {
        return double.tryParse(cand.toString()) ?? 0.0;
      }
      // fallback to product object
      if (productField is Map) {
        final p = productField['price'] ?? productField['final_price'] ?? productField['product_price'];
        if (p != null) return double.tryParse(p.toString()) ?? 0.0;
      }
      return 0.0;
    }

    final productField = json['product'] ?? json['product_data'];
    return CartItem(
      id: extractId(json['id']),
      productId: extractId(productField ?? json['product_id']),
      productSlug: (productField is Map)
          ? (productField['slug'] ?? productField['product_slug'] ?? productField['slug_name']) as String?
          : (json['product_slug'] ?? json['slug']) as String?,
      productName: json['product_name'] is String
          ? json['product_name']
          : extractName(productField ?? json['product_name']),
      productPrice: extractPrice(json, productField),
      quantity: (json['quantity'] is int) ? json['quantity'] : int.tryParse((json['quantity'] ?? '1').toString()) ?? 1,
      imageUrl: (productField is Map)
          ? (productField['primary_image'] ?? productField['image'] ?? productField['thumbnail']) as String?
          : (json['product_image'] ?? json['primary_image']) as String?,
    );
  }

  double get subtotal => productPrice * (quantity); 
}

class Cart {
  final int id;
  final List<CartItem> items;

  Cart({required this.id, required this.items});

  factory Cart.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] ?? json['cart_items'] ?? [];
    final items = (itemsJson as List).map((i) => CartItem.fromJson(i as Map<String, dynamic>)).toList();
    return Cart(id: json['id'] ?? 0, items: items);
  }

  double get subtotal => items.fold(0.0, (p, e) => p + e.subtotal);
}
