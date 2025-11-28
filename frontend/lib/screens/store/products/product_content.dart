import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../models/store/product_model.dart';
import '../../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class ProductContent extends StatefulWidget {
  const ProductContent({super.key});

  @override
  State<ProductContent> createState() => _ProductContentState();
}

class _ProductContentState extends State<ProductContent> {
  @override
  void initState() {
    super.initState();
    // Ensure products are loaded when this content appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StoreProvider>();
      if (provider.products.isEmpty) provider.loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final List<Product> products = provider.products;
    final bool loading = provider.isLoading;

    if (loading) return const Center(child: CircularProgressIndicator());

    if (products.isEmpty) return const Center(child: Text('No products found'));

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: products.length,
      itemBuilder: (context, i) {
        final p = products[i];
        return ProductCard(
          product: p,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(slug: p.slug),
            ),
          ),
        );
      },
    );
  }
}
