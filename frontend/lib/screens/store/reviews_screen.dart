import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/constants.dart';
import '../../services/store_service.dart';
import 'products/product_detail_screen.dart';
// simple inline stars renderer
import 'review_compose_screen.dart';
import 'product_reviews_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _eligibleProducts = [];
  // Cache fetched product info for review tiles: id -> { 'name': ..., 'image': ... }
  final Map<int, Map<String, String?>> _productCache = {};
  final Set<int> _productFetching = {};

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (!auth.isAuthenticated || auth.user == null) {
        _reviews = [];
      } else {
        final userId = auth.user!.id;
        _reviews = await _store.fetchUserReviews(userId: userId);
        // Also load eligible purchased products for quick compose
        _eligibleProducts =
            await _store.getEligibleProductsForReview(userId: userId);
        // Prefetch product details for reviews to avoid showing wrong names
        final ids = <int>{};
        for (final r in _reviews) {
          try {
            final pid = widgetFallbackProductId(r['product']);
            if (pid > 0) ids.add(pid);
          } catch (_) {}
        }
        for (final id in ids) {
          if (!_productCache.containsKey(id) &&
              !_productFetching.contains(id)) {
            _productFetching.add(id);
            _populateProductCache(id);
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load reviews: $e')),
      );
      _reviews = [];
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _openComposeForProduct(int productId) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
          builder: (_) => ReviewComposeScreen(productId: productId)),
    );

    if (created == true) {
      await _loadReviews();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Review submitted')));
    }
  }

  Future<void> _showEligiblePicker() async {
    if (_eligibleProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No eligible purchased products found')));
      return;
    }
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text('Select a product to review',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _eligibleProducts.length,
                      itemBuilder: (context, idx) {
                        final p = _eligibleProducts[idx];
                        // Kick off lazy thumbnail fetch if missing
                        if ((p['thumbnail'] == null ||
                                p['thumbnail'].toString().isEmpty) &&
                            p['_fetching_thumb'] != true) {
                          // mark fetching to avoid duplicate calls
                          p['_fetching_thumb'] = true;
                          _fetchAndPopulateThumbnail(
                              p['id'] as int, idx, setModalState);
                        }
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          onTap: () async {
                            Navigator.of(context).pop();
                            String? slug = p['slug']?.toString();
                            if (slug == null || slug.isEmpty) {
                              try {
                                final det = await _store
                                    .fetchProductById(p['id'] as int);
                                if (det != null) slug = det.slug;
                              } catch (e) {}
                            }
                            if (slug != null && slug.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailScreen(slug: slug!),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Product details not available')));
                            }
                          },
                          leading: Builder(builder: (context) {
                            final dynamic thumb = p['thumbnail'];
                            String? url;
                            if (thumb != null) {
                              if (thumb is String) {
                                final s = thumb.toString();
                                if (s.startsWith('http'))
                                  url = s;
                                else if (s.contains('http')) {
                                  final idx = s.indexOf('http');
                                  url = s.substring(idx);
                                }
                              } else if (thumb is Map) {
                                url = (thumb['url'] ??
                                        thumb['path'] ??
                                        thumb['thumbnail'] ??
                                        thumb['image'])
                                    ?.toString();
                              } else {
                                final s = thumb.toString();
                                if (s.contains('http')) {
                                  final idx = s.indexOf('http');
                                  url = s.substring(idx);
                                }
                              }
                            }

                            final labelStr = (p['label'] ?? '').toString();
                            final avatarChar = labelStr.isNotEmpty
                                ? labelStr.substring(0, 1)
                                : '?';

                            if (url != null && url.isNotEmpty) {
                              // Prefix relative paths with base URL
                              if (!url.startsWith('http')) {
                                final path =
                                    url.startsWith('/') ? url : '/$url';
                                url = ApiConstants.baseUrl + path;
                              } else {
                                // If the server returned an absolute localhost URL, replace
                                // the host with the configured `ApiConstants.baseUrl` so
                                // device/emulator can reach the host.
                                url = url.replaceFirst(
                                    RegExp(
                                        r'https?://(localhost|127\.0\.0\.1)(:\d+)?'),
                                    ApiConstants.baseUrl);
                              }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12.0),
                                child: Image.network(
                                  url,
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => CircleAvatar(
                                      radius: 28, child: Text(avatarChar)),
                                ),
                              );
                            }

                            return CircleAvatar(
                                radius: 28, child: Text(avatarChar));
                          }),
                          title: Text(
                            p['label'] ?? 'Product #${p['id']}',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.color),
                          ),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              backgroundColor: const Color(0xFF7C3AED),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _openComposeForProduct(p['id'] as int);
                            },
                            child: const Text('Write',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Extract an integer product id from a variety of possible shapes
  int widgetFallbackProductId(dynamic prod) {
    try {
      if (prod == null) return 0;
      if (prod is int) return prod;
      if (prod is Map) {
        final idVal = prod['id'] ?? prod['pk'] ?? prod['product_id'];
        final parsed =
            idVal is int ? idVal : int.tryParse(idVal?.toString() ?? '');
        return parsed ?? 0;
      }
      final parsed = int.tryParse(prod.toString());
      return parsed ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _fetchAndPopulateThumbnail(int productId, int index,
      [StateSetter? innerSetState]) async {
    try {
      // Try fetching by id first (some backends only support list queries by id),
      // fall back to slug-style detail if needed.
      var det = await _store.fetchProductById(productId);
      if (det == null) {
        det = await _store.fetchProductDetail(productId.toString());
      }
      if (det == null) return;
      String? candidate;
      if (det.primaryImage != null && det.primaryImage!.isNotEmpty)
        candidate = det.primaryImage;
      if ((candidate == null || candidate.isEmpty) && det.images.isNotEmpty)
        candidate = det.images.first.image;
      if (candidate != null && candidate.isNotEmpty) {
        // normalize relative paths
        String url = candidate;
        if (!url.startsWith('http')) {
          final path = url.startsWith('/') ? url : '/$url';
          url = ApiConstants.baseUrl + path;
        } else {
          url = url.replaceFirst(
              RegExp(r'https?://(localhost|127\.0\.0\.1)(:\d+)?'),
              ApiConstants.baseUrl);
        }
        if (innerSetState != null) {
          innerSetState(() {
            _eligibleProducts[index]['thumbnail'] = url;
          });
        } else if (mounted) {
          setState(() {
            _eligibleProducts[index]['thumbnail'] = url;
          });
        }
      }
    } catch (e) {
      // ignore errors silently
    }
  }

  String _normalizeImageUrl(String url) {
    if (url.isEmpty) return url;
    var out = url;
    if (!out.startsWith('http')) {
      final path = out.startsWith('/') ? out : '/$out';
      out = ApiConstants.baseUrl + path;
    } else {
      out = out.replaceFirst(
          RegExp(r'https?://(localhost|127\.0\.0\.1)(:\d+)?'),
          ApiConstants.baseUrl);
    }
    return out;
  }

  Future<void> _populateProductCache(int productId) async {
    if (_productFetching.contains(productId)) return;
    _productFetching.add(productId);
    try {
      final det = await _store.fetchProductById(productId);
      if (det == null) {
        final pd = await _store.fetchProductDetail(productId.toString());
        if (pd != null) {
          _productCache[productId] = {
            'name': pd.name,
            'image': pd.primaryImage ??
                (pd.images.isNotEmpty ? pd.images.first.image : null)
          };
        }
      } else {
        _productCache[productId] = {
          'name': det.name,
          'image': det.primaryImage ??
              (det.images.isNotEmpty ? det.images.first.image : null)
        };
      }
      if (mounted) setState(() {});
    } catch (e) {
      // ignore
    } finally {
      _productFetching.remove(productId);
    }
  }

  Widget _buildReviewTile(Map<String, dynamic> r, AuthProvider auth) {
    final product = r['product'];
    String title = r['title'] ?? '';
    String comment = r['comment'] ?? '';
    final rating = r['rating'] is int
        ? r['rating'] as int
        : int.tryParse(r['rating']?.toString() ?? '') ?? 0;
    // Determine product id and label; prefer cached product info (authoritative)
    final int pid = widgetFallbackProductId(product);
    String productLabel = '';
    String? productImage;
    if (pid > 0 && _productCache.containsKey(pid)) {
      productLabel = _productCache[pid]!['name'] ?? '';
      productImage = _productCache[pid]!['image'];
    }
    // Fall back to review-embedded product info
    if (productLabel.isEmpty) {
      if (product is Map) {
        productLabel = (product['title'] ?? product['name'] ?? product['slug'])
                ?.toString() ??
            '';
        productImage = productImage ??
            (product['primary_image'] ??
                    product['thumbnail'] ??
                    product['image'] ??
                    product['photo'])
                ?.toString();
      } else if (product != null) {
        productLabel = 'Product #${product.toString()}';
      }
    }
    // Ensure we fetch product details if not cached yet
    if (pid > 0 &&
        !_productCache.containsKey(pid) &&
        !_productFetching.contains(pid)) {
      _productFetching.add(pid);
      _populateProductCache(pid);
    }

    Widget _buildStars(int rating) {
      final stars = List<Widget>.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 18,
          color: Colors.amber,
        );
      });
      return Row(children: stars);
    }

    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final titleColor = theme.textTheme.titleMedium?.color ?? Colors.black87;
    final bodyColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;

    final borderColor = theme.dividerColor
        .withOpacity(theme.brightness == Brightness.dark ? 0.12 : 0.08);

    return Card(
      color: cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // product image (opens product detail)
                GestureDetector(
                  onTap: () async {
                    try {
                      String? slug;
                      if (product is Map) slug = product['slug']?.toString();
                      if (slug == null || slug.isEmpty) {
                        final det = await _store.fetchProductById(pid);
                        slug = det?.slug;
                      }
                      if (slug != null && slug.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(slug: slug!),
                          ),
                        );
                      }
                    } catch (e) {
                      // ignore
                    }
                  },
                  child: (productImage != null && productImage.isNotEmpty)
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            _normalizeImageUrl(productImage),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => CircleAvatar(
                                radius: 20,
                                child: Text((productLabel.isNotEmpty
                                    ? productLabel.substring(0, 1)
                                    : '?'))),
                          ),
                        )
                      : CircleAvatar(
                          radius: 20,
                          child: Text((productLabel.isNotEmpty
                              ? productLabel.substring(0, 1)
                              : '?'))),
                ),
                const SizedBox(width: 10),
                // title area and tappable region for opening reviews
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      try {
                        if (pid > 0) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductReviewsScreen(
                                  productId: pid,
                                  productName: productLabel.isNotEmpty
                                      ? productLabel
                                      : null),
                            ),
                          );
                        }
                      } catch (e) {}
                    },
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.5,
                      child: Text(
                        productLabel.isNotEmpty
                            ? productLabel
                            : 'Product #$pid',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: titleColor),
                      ),
                    ),
                  ),
                ),
                if (auth.isAuthenticated &&
                    auth.user != null &&
                    r['user'] != null &&
                    r['user'] == auth.user!.id)
                  IconButton(
                    onPressed: () async {
                      // compute product id for composer
                      int? pid;
                      try {
                        if (product is Map)
                          pid = product['id'] ?? product['product_id'];
                        else if (product is int) pid = product;
                      } catch (e) {
                        pid = null;
                      }
                      final edited = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ReviewComposeScreen(
                            productId:
                                pid ?? widgetFallbackProductId(r['product']),
                            reviewId: r['id'] as int?,
                            initialRating: r['rating'] is int
                                ? r['rating'] as int
                                : int.tryParse(r['rating']?.toString() ?? ''),
                            initialTitle: r['title']?.toString(),
                            initialComment: r['comment']?.toString(),
                          ),
                        ),
                      );
                      if (edited == true) {
                        await _loadReviews();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Review updated')));
                      }
                    },
                    icon: const Icon(Icons.edit, size: 20),
                    color: const Color(0xFF7C3AED),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Make stars/title/comment tappable to open the product's reviews
            GestureDetector(
              onTap: () {
                try {
                  if (pid > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductReviewsScreen(
                            productId: pid,
                            productName:
                                productLabel.isNotEmpty ? productLabel : null),
                      ),
                    );
                  }
                } catch (e) {}
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // rating stars
                  _buildStars(rating),
                  const SizedBox(height: 8),
                  // optional review title
                  if (title.isNotEmpty)
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: titleColor)),
                  // comment/body
                  if (comment.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(comment, style: TextStyle(color: bodyColor)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'Reviews', showBackButton: true),
      body: RefreshIndicator(
        onRefresh: _loadReviews,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: Text('Your reviews',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color)),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _reviews.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 40),
                              Center(
                                  child: Text(auth.isAuthenticated
                                      ? 'No reviews yet.'
                                      : 'Please sign in to view reviews.')),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _reviews.length,
                            itemBuilder: (context, idx) =>
                                _buildReviewTile(_reviews[idx], auth),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 18.0, right: 8.0),
        child: FloatingActionButton.extended(
          onPressed: _showEligiblePicker,
          icon: const Icon(Icons.add, color: Colors.white),
          label:
              const Text('Write Review', style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF7C3AED),
          elevation: 10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
