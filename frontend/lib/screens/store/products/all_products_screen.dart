import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/store_provider.dart';
import '../../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class AllProductsScreen extends StatelessWidget {
  final String title;
  final bool featured;

  const AllProductsScreen({super.key, required this.title, this.featured = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<StoreProvider>();
    // If requested, prefer featured products. Ensure they are loaded if empty.
    if (featured && provider.featuredProducts.isEmpty) {
      // Kick off a load; this is safe to call repeatedly because provider will
      // no-op if a load is already in progress.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadFeaturedProducts(ignoreFilters: true);
      });
    }

    final products = featured ? provider.featuredProducts : provider.products;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: const Color(0xFF7C3AED),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color.fromRGBO(124, 58, 237, 0.85)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        Icons.store,
                        size: 120,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 16),
            sliver: products.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.store,
                            size: 64,
                            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                          ),
                          const SizedBox(height: 16),
                          const Text('No products found'),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = products[index];
                          return ProductCard(
                            product: p,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: p.slug)),
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }
}
