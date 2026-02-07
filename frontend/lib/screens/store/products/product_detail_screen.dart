import 'package:flutter/material.dart';
import '../../../services/store_service.dart';
import '../../../models/store/product_detail_model.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../pet/widgets/full_screen_image.dart';
import 'package:provider/provider.dart';
import '../review_compose_screen.dart';
import '../product_reviews_screen.dart';
import '../../../providers/store_provider.dart';
import '../../../utils/currency.dart';
import '../../../utils/helpers.dart';
import '../checkout_screen.dart';
import '../../../models/store/cart_model.dart';

class ProductDetailScreen extends StatefulWidget {
  final String slug;
  const ProductDetailScreen({super.key, required this.slug});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  final StoreService _store = StoreService();
  ProductDetail? _product;
  bool _loading = true;
  bool _adding = false;
  bool _canReview = false;
  bool _hasReviewed = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _descExpanded = false;
  late final AnimationController _savePulseController;
  late final Animation<double> _saveScale;

  Widget _logoOrPlaceholder(
      {String? url,
      required String name,
      required String heroTag,
      double size = 28}) {
    String initials() {
      if (name.trim().isEmpty) return '';
      final parts = name.trim().split(RegExp(r"\s+"));
      if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
      final a = parts[0].substring(0, 1);
      final b = parts.length > 1 ? parts[1].substring(0, 1) : '';
      return (a + b).toUpperCase();
    }

    if (url != null && url.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImage(
                images: [url],
                initialIndex: 0,
                heroTag: heroTag,
                heroIndex: 0,
              ),
            ),
          );
        },
        child: Hero(
          tag: heroTag,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
              image:
                  DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
          ),
        ),
      );
    }

    // placeholder with initials
    final bg = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey[800]
        : const Color(0xFFEDE7F6); // adapt placeholder bg
    const txtColor = Color(0xFF7C3AED);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: Text(initials(),
          style: const TextStyle(color: txtColor, fontWeight: FontWeight.bold)),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
    _savePulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _saveScale = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _savePulseController, curve: Curves.easeOut));
    _savePulseController.addStatusListener((s) {
      if (s == AnimationStatus.completed) _savePulseController.reverse();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _savePulseController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final p = await _store.fetchProductDetail(widget.slug);
      setState(() => _product = p);
      // Log logos for debugging if available
      if (_product != null) {
        debugPrint(
            'Product categoryLogo: ${_product!.categoryLogo}, brandLogo: ${_product!.brandLogo}');
        // Check review eligibility for authenticated users
        final auth = context.read<AuthProvider>();
        final userId = auth.user?.id;
        if (userId != null) {
          final can = await _store.isProductVerifiedPurchase(_product!.id);
          final has = await _store.hasUserReviewedProduct(_product!.id, userId);
          if (mounted) {
            setState(() {
              _canReview = can;
              _hasReviewed = has;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading product detail: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<bool> _addToCart() async {
    if (_product == null) return false;
    setState(() => _adding = true);
    try {
      final ok = await _store.addToCart(productId: _product!.id, quantity: 1);
      showAppSnackBar(context,
          SnackBar(content: Text(ok ? 'Added to cart' : 'Failed to add')));
      return ok;
    } catch (e) {
      // Parse common server messages and show a friendlier message to the user
      final raw = e.toString();
      String friendly = 'Failed to add to cart. Please try again.';

      // Example server message: "Only 0 items available" or "Only 3 items available"
      final regex =
          RegExp(r"Only\s*(\d+)\s*items?\s*available", caseSensitive: false);
      final m = regex.firstMatch(raw);
      if (m != null) {
        final available = int.tryParse(m.group(1) ?? '0') ?? 0;
        if (available == 0) {
          friendly = 'Sorry — this product is currently out of stock.';
        } else {
          friendly =
              'Only $available left in stock. Please reduce quantity or try again.';
        }
      } else if (raw.toLowerCase().contains('out of stock') ||
          raw.toLowerCase().contains('not enough') ||
          raw.toLowerCase().contains('stock')) {
        friendly = 'Sorry — not enough stock available for this item.';
      } else if (raw.toLowerCase().contains('authentication') ||
          raw.toLowerCase().contains('token')) {
        friendly = 'Please sign in to add items to your cart.';
      }

      showAppSnackBar(
          context,
          SnackBar(
              content: Text(friendly), behavior: SnackBarBehavior.floating));
      return false;
    } finally {
      setState(() => _adding = false);
    }
  }

  Future<void> _buyNow() async {
    if (_product == null) return;
    // If product is out of stock, show friendly message and don't proceed
    if (_product!.stock <= 0) {
      showAppSnackBar(
        context,
        const SnackBar(
          content: Text('Sorry — this product is currently out of stock.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // Build a temporary Cart with this single product (Buy Now flow)
    final cartItem = CartItem(
      id: _product!.id,
      productId: _product!.id,
      productSlug: _product!.slug,
      productName: _product!.name,
      productPrice: _product!.finalPrice,
      quantity: 1,
      imageUrl: _product!.primaryImage,
    );

    final tempCart = Cart(id: 0, items: [cartItem]);

    if (!mounted) return;
    // Navigate to the Checkout screen with the temp cart (does not add to server cart)
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => CheckoutScreen(initialCart: tempCart)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;
    final mutedColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey;
    final chipBg =
        theme.brightness == Brightness.dark ? Colors.grey[800] : Colors.white;
    final chipBorder =
        BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.08));
    // Layout & typography scale for modern spacing
    const double titleSize = 24.0;
    const double headerSize = 18.0;
    const double subtitleSize = 14.0;
    const double labelSize = 16.0;
    const double bodySize = 16.0;
    const double chipFontSize = 14.0;
    const double sectionGap = 18.0;
    const double smallGap = 10.0;
    const double iconSize = 18.0;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
          title: _product?.name ?? 'Product', showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _product == null
              ? const Center(child: Text('Product not found'))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image carousel / header with top gap and rounded corners
                      Builder(builder: (context) {
                        // reduce the visual gap by using a smaller offset
                        final topGap = MediaQuery.of(context).padding.top +
                            (kToolbarHeight * 0.35);
                        return Container(
                          margin:
                              EdgeInsets.only(top: topGap, left: 16, right: 16),
                          height: 320,
                          child: PhysicalModel(
                            color: Colors.transparent,
                            elevation: 8,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: Builder(builder: (context) {
                              final imgs = _product!.images.isNotEmpty
                                  ? _product!.images
                                      .map((e) => e.image)
                                      .toList()
                                  : (_product!.primaryImage != null
                                      ? [_product!.primaryImage!]
                                      : <String>[]);
                              final count = imgs.length;
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: PageView.builder(
                                      controller: _pageController,
                                      physics: const BouncingScrollPhysics(
                                          parent:
                                              AlwaysScrollableScrollPhysics()),
                                      itemCount: count > 0 ? count : 1,
                                      onPageChanged: (i) =>
                                          setState(() => _currentPage = i),
                                      itemBuilder: (context, index) {
                                        final img =
                                            count > 0 ? imgs[index] : null;
                                        if (img == null) {
                                          return Container(
                                              color: Colors.grey[200]);
                                        }
                                        final heroTag =
                                            'product_photo_${_product!.id}_$index';
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => FullScreenImage(
                                                  images: imgs,
                                                  initialIndex: index,
                                                  heroTag: heroTag,
                                                  heroIndex: index,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Hero(
                                            tag: heroTag,
                                            child: Image.network(
                                              img,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              loadingBuilder: (context, child,
                                                  loadingProgress) {
                                                if (loadingProgress == null) {
                                                  return child;
                                                }
                                                return const Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    color: Color(0xFF7C3AED),
                                                  ),
                                                );
                                              },
                                              errorBuilder:
                                                  (context, error, st) =>
                                                      Container(
                                                color: Colors.grey[300],
                                                child: const Center(
                                                    child: Icon(
                                                        Icons.broken_image)),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (count > 1)
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      bottom: 8,
                                      child: Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withOpacity(0.35),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(count, (i) {
                                              final active = i == _currentPage;
                                              return GestureDetector(
                                                behavior:
                                                    HitTestBehavior.opaque,
                                                onTap: () {
                                                  if (_pageController
                                                      .hasClients) {
                                                    _pageController
                                                        .animateToPage(i,
                                                            duration:
                                                                const Duration(
                                                                    milliseconds:
                                                                        300),
                                                            curve: Curves
                                                                .easeInOut);
                                                  } else {
                                                    _pageController
                                                        .jumpToPage(i);
                                                  }
                                                },
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 6.0,
                                                      vertical: 6.0),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 250),
                                                    width: active ? 12 : 10,
                                                    height: active ? 12 : 10,
                                                    decoration: BoxDecoration(
                                                      color: active
                                                          ? const Color(
                                                              0xFF7C3AED)
                                                          : Colors.white
                                                              .withOpacity(0.6),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                          color:
                                                              Colors.white70),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ),
                                    ),
                                  // (moved) rating badge will be rendered below the image
                                ],
                              );
                            }),
                          ),
                        );
                      }),
                      // Rating row under image (right-aligned)
                      if (_product != null && _product!.averageRating != null)
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 16.0, top: 12.0, left: 16.0),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Material(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[900]
                                  : Colors.white,
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: List.generate(5, (i) {
                                        final filled = i <
                                            _product!.averageRating!.round();
                                        return Icon(Icons.star,
                                            size: 16,
                                            color: filled
                                                ? Colors.amber
                                                : Colors.grey);
                                      }),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                        _product!.averageRating!
                                            .toStringAsFixed(1),
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                ProductReviewsScreen(
                                                    productId: _product!.id,
                                                    productName:
                                                        _product!.name),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(40, 24),
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap),
                                      child: const Text('View all'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _product!.name,
                              style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          fontSize: titleSize,
                                          fontWeight: FontWeight.bold) ??
                                  const TextStyle(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            // Place write-review control under the rating row to avoid overlap
                            Builder(builder: (context) {
                              final authProv =
                                  Provider.of<AuthProvider>(context);
                              if (!authProv.isAuthenticated) {
                                return const SizedBox.shrink();
                              }
                              if (!_canReview) return const SizedBox.shrink();
                              if (_hasReviewed) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: const Text('Purchased',
                                      style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600)),
                                );
                              }
                              return SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (_product == null) return;
                                    final res = await Navigator.push<bool?>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ReviewComposeScreen(
                                            productId: _product!.id),
                                      ),
                                    );
                                    if (res == true) {
                                      if (mounted) {
                                        setState(() => _hasReviewed = true);
                                      }
                                      await _load();
                                      showAppSnackBar(
                                          context,
                                          const SnackBar(
                                              content:
                                                  Text('Review submitted')));
                                    }
                                  },
                                  icon: const Icon(Icons.rate_review, size: 18),
                                  label: const Text('Write a review'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C3AED),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 12),
                                    textStyle: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: smallGap),

                            // Explicit Category and Brand rows with optional logos
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.pets,
                                            size: 20, color: Color(0xFF7C3AED)),
                                        const SizedBox(width: 10),
                                        Text('Category: ',
                                            style: TextStyle(
                                                fontSize: labelSize,
                                                fontWeight: FontWeight.w800,
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black)),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    if (_product!.categoryName != null) ...[
                                      _logoOrPlaceholder(
                                          url: _product!.categoryLogo,
                                          name: _product!.categoryName ?? '',
                                          heroTag:
                                              'category_logo_${_product!.id}',
                                          size: 34),
                                      const SizedBox(width: 10),
                                      Flexible(
                                          child: Text(
                                              _product!.categoryName ?? '',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: textColor,
                                                  fontSize: bodySize))),
                                    ] else ...[
                                      Text('—',
                                          style: TextStyle(color: mutedColor)),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.storefront,
                                            size: 20, color: Color(0xFF7C3AED)),
                                        const SizedBox(width: 10),
                                        Text('Brand: ',
                                            style: TextStyle(
                                                fontSize: labelSize,
                                                fontWeight: FontWeight.w800,
                                                color: theme.brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black)),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    if (_product!.brandName != null) ...[
                                      _logoOrPlaceholder(
                                          url: _product!.brandLogo,
                                          name: _product!.brandName ?? '',
                                          heroTag: 'brand_logo_${_product!.id}',
                                          size: 34),
                                      const SizedBox(width: 10),
                                      Text(
                                        _product!.brandName ?? '',
                                        style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: bodySize),
                                      ),
                                    ] else ...[
                                      Text('—',
                                          style: TextStyle(color: mutedColor)),
                                    ],
                                    const Spacer(),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: sectionGap),

                            // Price and discount
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                    '$kCurrencySymbol${_product!.finalPrice.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 28,
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(width: 14),
                                if (_product!.discountPrice != null)
                                  Text(
                                      'Was $kCurrencySymbol${_product!.price.toStringAsFixed(0)}',
                                      style: TextStyle(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: mutedColor,
                                          fontSize: subtitleSize)),
                                const SizedBox(width: 8),
                                if (_product!.discountPrice != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Text(
                                        '-${((_product!.price - _product!.discountPrice!) / _product!.price * 100).round()}%',
                                        style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600)),
                                  ),
                              ],
                            ),

                            const SizedBox(height: smallGap),

                            // Short info row: SKU, Stock, Pet Type
                            Wrap(
                              spacing: 14,
                              runSpacing: 10,
                              children: [
                                if (_product!.sku != null)
                                  Chip(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    avatar: const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.qr_code,
                                            size: 16,
                                            color: Color(0xFF7C3AED))),
                                    label: Text('SKU: ${_product!.sku!}',
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: chipFontSize)),
                                    backgroundColor: chipBg,
                                    shape: StadiumBorder(side: chipBorder),
                                  ),
                                Chip(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  avatar: const CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.white,
                                      child: Icon(Icons.inventory,
                                          size: 16, color: Color(0xFF7C3AED))),
                                  label: Text('Stock: ${_product!.stock}',
                                      style: TextStyle(
                                          color: textColor,
                                          fontSize: chipFontSize)),
                                  backgroundColor: chipBg,
                                  shape: StadiumBorder(side: chipBorder),
                                ),
                                if (_product!.petType != null)
                                  Chip(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    avatar: const CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.white,
                                        child: Icon(Icons.pets,
                                            size: 16,
                                            color: Color(0xFF7C3AED))),
                                    label: Text(_product!.petType!,
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: chipFontSize)),
                                    backgroundColor: chipBg,
                                    shape: StadiumBorder(side: chipBorder),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Description (chip-style container similar to weight/dimensions)
                            if (_product!.description != null &&
                                _product!.description!.isNotEmpty) ...[
                              Container(
                                margin:
                                    const EdgeInsets.only(top: 8, bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.fromBorderSide(chipBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Description',
                                        style: TextStyle(
                                            fontSize: headerSize,
                                            fontWeight: FontWeight.w800,
                                            color: theme.brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black)),
                                    const SizedBox(height: 8),
                                    AnimatedSize(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      curve: Curves.easeInOut,
                                      alignment: Alignment.topCenter,
                                      child: ConstrainedBox(
                                        constraints: _descExpanded
                                            ? const BoxConstraints()
                                            : const BoxConstraints(
                                                maxHeight: bodySize * 6.0),
                                        child: Text(
                                          _product!.description!,
                                          style: TextStyle(
                                              fontSize: bodySize,
                                              color: textColor,
                                              height: 1.4),
                                          softWrap: true,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // only show toggle when description is long enough
                                    if ((_product!.description?.length ?? 0) >
                                        240)
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: TextButton(
                                          style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(60, 24),
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap),
                                          onPressed: () => setState(() =>
                                              _descExpanded = !_descExpanded),
                                          child: Text(
                                              _descExpanded
                                                  ? 'Show less'
                                                  : 'Show more',
                                              style: const TextStyle(
                                                  color: Color(0xFF7C3AED),
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            // Additional details (show icons for clarity)
                            if (_product!.weight != null ||
                                (_product!.dimensions != null &&
                                    _product!.dimensions!.isNotEmpty)) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              if (_product!.weight != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.fromBorderSide(chipBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.fitness_center,
                                          size: iconSize,
                                          color: Color(0xFF7C3AED)),
                                      const SizedBox(width: 10),
                                      RichText(
                                        text: TextSpan(
                                          children: [
                                            TextSpan(
                                                text: 'Weight: ',
                                                style: TextStyle(
                                                    color: theme.brightness ==
                                                            Brightness.dark
                                                        ? Colors.white
                                                        : Colors.black,
                                                    fontSize: bodySize,
                                                    fontWeight:
                                                        FontWeight.w800)),
                                            TextSpan(
                                                text: '${_product!.weight} kg',
                                                style: TextStyle(
                                                    color: textColor,
                                                    fontSize: bodySize,
                                                    fontWeight:
                                                        FontWeight.normal)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_product!.dimensions != null &&
                                  _product!.dimensions!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: chipBg,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.fromBorderSide(chipBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.straighten,
                                          size: iconSize,
                                          color: Color(0xFF7C3AED)),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                  text: 'Dimensions: ',
                                                  style: TextStyle(
                                                      color: theme.brightness ==
                                                              Brightness.dark
                                                          ? Colors.white
                                                          : Colors.black,
                                                      fontSize: bodySize,
                                                      fontWeight:
                                                          FontWeight.w800)),
                                              TextSpan(
                                                  text:
                                                      '${_product!.dimensions}',
                                                  style: TextStyle(
                                                      color: textColor,
                                                      fontSize: bodySize,
                                                      fontWeight:
                                                          FontWeight.normal)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 12),
                            ],

                            const SizedBox(height: 12),
                            // Buy Now button (full width) placed above the Save + Add to cart row
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF8B5CF6),
                                        Color(0xFF7C3AED)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFF7C3AED)
                                              .withOpacity(0.25),
                                          blurRadius: 14,
                                          offset: const Offset(0, 8)),
                                    ],
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(28),
                                      onTap: _adding ? null : _buyNow,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 14.0, horizontal: 18.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            // circular icon badge
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withOpacity(0.18),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.08),
                                                      blurRadius: 6,
                                                      offset:
                                                          const Offset(0, 3))
                                                ],
                                              ),
                                              child: const Center(
                                                child: Icon(Icons.payment,
                                                    color: Colors.white,
                                                    size: 18),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Buy Now',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16)),
                                                SizedBox(height: 2),
                                                Text('Fast checkout',
                                                    style: TextStyle(
                                                        color: Colors.white70,
                                                        fontSize: 12)),
                                              ],
                                            ),
                                            const Spacer(),
                                            const Icon(Icons.chevron_right,
                                                color: Colors.white70),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Save + Add to cart row
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  // Add to cart (expanded)
                                  Expanded(
                                    child: Material(
                                      elevation: 6,
                                      borderRadius: BorderRadius.circular(28),
                                      color: const Color(0xFF7C3AED),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(28),
                                        onTap: _adding ? null : _addToCart,
                                        splashColor: Colors.white24,
                                        highlightColor: Colors.white10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          alignment: Alignment.center,
                                          child: _adding
                                              ? const SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white))
                                              : const Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.shopping_cart,
                                                        color: Colors.white,
                                                        size: 20),
                                                    SizedBox(width: 10),
                                                    Text('Add to Cart',
                                                        style: TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16)),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Save (outlined) button on the right with pulse animation and snackbar
                                  Consumer<StoreProvider>(
                                      builder: (context, provider, child) {
                                    final saved = _product != null
                                        ? provider
                                            .isProductFavorite(_product!.id)
                                        : false;
                                    return ScaleTransition(
                                      scale: _saveScale,
                                      child: OutlinedButton.icon(
                                        onPressed: _product == null
                                            ? null
                                            : () {
                                                // immediate UI feedback: pulse and show snackbar right away
                                                _savePulseController.forward(
                                                    from: 0);
                                                final nowSaved = !saved;
                                                // toggle in background (persist)
                                                provider.toggleProductFavorite(
                                                    _product!.id);
                                                // show snack immediately (hide any current)
                                                showAppSnackBar(
                                                  context,
                                                  SnackBar(
                                                    content: Text(nowSaved
                                                        ? 'Saved'
                                                        : 'Removed from saved'),
                                                    duration: const Duration(
                                                        milliseconds: 1200),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                  ),
                                                );
                                              },
                                        icon: Icon(
                                            saved
                                                ? Icons.favorite
                                                : Icons.favorite_border,
                                            color: saved
                                                ? Colors.white
                                                : const Color(0xFF7C3AED),
                                            size: 20),
                                        label: Text('Save',
                                            style: TextStyle(
                                                color: saved
                                                    ? Colors.white
                                                    : const Color(0xFF7C3AED),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16)),
                                        style: OutlinedButton.styleFrom(
                                          side: saved
                                              ? BorderSide.none
                                              : const BorderSide(
                                                  color: Color(0xFF7C3AED)),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(28)),
                                          fixedSize: const Size(140, 56),
                                          backgroundColor: saved
                                              ? const Color(0xFF7C3AED)
                                              : Colors.transparent,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
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
