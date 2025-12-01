import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/store_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/custom_app_bar.dart';
import '../store/adoption/pet_detail_screen.dart';
import '../store/products/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Load adoptions to get favorite pets data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadAdoptions(showAllStatuses: false);
      // also load products to populate product wishlist
      context.read<StoreProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Wishlist',
        showBackButton: true,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          children: [
            Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              child: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF7C3AED),
                labelColor: const Color(0xFF7C3AED),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Products'),
                  Tab(text: 'Pets'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductsTab(),
                  _buildPetsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsTab() {
    return Consumer<StoreProvider>(builder: (context, provider, child) {
      if (provider.isLoading && provider.products.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

        // Prefer server-provided wishlist product objects when available so all
        // loved products are shown even if the global products list doesn't contain them.
        final favoriteProducts = (provider.wishlistProducts.isNotEmpty
            ? provider.wishlistProducts
            : provider.products.where((p) => provider.isProductFavorite(p.id)).toList())
          .where((p) => provider.isProductFavorite(p.id))
          .toList();

      if (favoriteProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'No favorite products yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start adding products to your wishlist',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: favoriteProducts.length,
        itemBuilder: (context, index) {
          final product = favoriteProducts[index];
          return ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: product.slug)),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildPetsTab() {
    return Consumer<StoreProvider>(
      builder: (context, provider, child) {
        final favoritePets = provider.adoptions
            .where((pet) => provider.isPetFavorite(pet.id))
            .toList();

        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (favoritePets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No favorite pets yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the heart icon on pets to add them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: favoritePets.length,
          itemBuilder: (context, index) {
            final pet = favoritePets[index];
            return _buildPetCard(pet, provider);
          },
        );
      },
    );
  }

  Widget _buildPetCard(dynamic pet, StoreProvider provider) {
    return Card(
      clipBehavior: Clip.hardEdge,
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PetDetailScreen(adoptionId: pet.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (pet.photo != null)
                    Image.network(
                      pet.photo!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.pets, size: 48),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.pets, size: 48),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        // FIXED: Replaced withOpacity with withValues
                        color: Colors.black.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite),
                        color: Colors.red,
                        iconSize: 20,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        onPressed: () {
                          provider.togglePetFavorite(pet.id);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      pet.petName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Compact details row: breed • gender • location (truncated)
                    Row(
                      children: [
                        // Breed takes remaining space, truncated if needed
                        Flexible(
                          child: Text(
                            pet.breed ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Pet type badge (e.g., Dog, Cat)
                        if (pet.petType != null && (pet.petType as String).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.pets,
                                  size: 14,
                                  color: Color(0xFF7C3AED),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  // Prefer a nicely formatted display if available
                                  (pet.petTypeDisplay ?? pet.petType) as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[200] : Colors.black,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 6),

                        // Gender icon + text
                        if (pet.gender != null && (pet.gender as String).isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                pet.gender.toString().toLowerCase() == 'male' ? Icons.male : Icons.female,
                                size: 14,
                                color: const Color(0xFF7C3AED),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pet.gender ?? '',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[200] : Colors.black,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Age chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9D8FD),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cake, size: 14, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 6),
                          Text(
                            pet.ageDisplay,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}