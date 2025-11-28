import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/store/product_model.dart';
import '../providers/store_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top image with rounded top corners (slightly taller)
            SizedBox(
              height: 160,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: product.primaryImage != null
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                            child: Image.network(product.primaryImage!, fit: BoxFit.cover),
                          )
                        : Container(color: Colors.grey[200]),
                  ),
                    // Favorite overlay (similar to adoption card)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Consumer<StoreProvider>(
                        builder: (context, provider, child) {
                          final isFavorite = provider.isProductFavorite(product.id);
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                              color: isFavorite ? Colors.red : Colors.white,
                              iconSize: 22,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                              onPressed: () {
                                provider.toggleProductFavorite(product.id);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurpleAccent.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  // Rating number (if available) - placed above price for emphasis
                  if (product.averageRating != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(product.averageRating!.toStringAsFixed(1), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      // Price: even bigger and bold
                      Text('₹${product.finalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, color: Colors.green, fontWeight: FontWeight.bold)),
                      if (product.hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.price.toStringAsFixed(0)}',
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey[700],
                            color: Colors.grey[700],
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
