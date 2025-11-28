import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/currency.dart';
import '../models/store/product_model.dart';
import '../providers/store_provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------------------------------------------------
            // IMAGE SECTION: Expanded
            // This allows the image to grow if the card is tall (Featured),
            // but ensures the text area below remains compact.
            // ---------------------------------------------------------
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  product.primaryImage != null
                      ? Image.network(
                          product.primaryImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: theme.brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              child: Icon(
                                Icons.shopping_bag,
                                size: 48,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.5),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: theme.brightness == Brightness.dark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          child: Icon(
                            Icons.shopping_bag,
                            size: 48,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                  // Favorite Button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<StoreProvider>(
                      builder: (context, provider, child) {
                        final isFavorite =
                            provider.isProductFavorite(product.id);
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border),
                            color: isFavorite ? Colors.red : Colors.white,
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 40, minHeight: 40),
                            onPressed: () {
                              provider.toggleProductFavorite(product.id);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Discount Badge
                  if (product.hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.95),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '-${product.discountPercent}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---------------------------------------------------------
            // CONTENT SECTION: Compact
            // Uses MainAxisSize.min to keep everything tight at the bottom.
            // ---------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Keep content compact
                children: [
                  // Name
                  Text(
                    product.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Rating
                  if (product.averageRating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          product.averageRating!.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 8),

                  // ---------------------------------------------------
                  // BOTTOM ROW: Price (Left) & Stock (Right)
                  // Grouping these ensures they stay aligned regardless of card height
                  // ---------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Price Section
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$kCurrencySymbol${product.finalPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 6),
                              Flexible(
                                  child: Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(
                                    '$kCurrencySymbol${product.price.toStringAsFixed(0)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: theme
                                          .textTheme.bodyMedium?.color
                                          ?.withOpacity(0.6),
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),

                      // Stock Status
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          product.stock > 0 ? 'In stock' : 'Out of stock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: product.stock > 0
                                ? Colors.greenAccent.shade400
                                : Colors.redAccent.shade200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}