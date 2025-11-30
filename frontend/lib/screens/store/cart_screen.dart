import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import '../../services/store_service.dart';
import '../../models/store/cart_model.dart';
import 'products/product_detail_screen.dart';
import 'checkout_screen.dart';
import '../common/main_screen.dart';
import '../../utils/currency.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final StoreService _store = StoreService();
  Cart? _cart;
  bool _loading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _loading = true);
    try {
      final data = await _store.fetchCart();
      if (data != null) {
        // data is returned as Map<String, dynamic> from the service
        if (mounted) {
          setState(() {
            _cart = Cart.fromJson(data);
          });
        }
      }
    } catch (e) {
      if (mounted) Helpers.showInstantSnackBar(context, SnackBar(content: Text('Failed to load cart: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changeQuantity(int index, int delta) async {
    final item = _cart!.items[index];
    final newQty = (item.quantity + delta).clamp(1, 999);
    if (newQty == item.quantity) return;
    setState(() => item.quantity = newQty);
    try {
      await _store.updateCartItem(itemId: item.id, quantity: newQty);
      await _loadCart();
    } catch (e) {
      if (mounted) Helpers.showInstantSnackBar(context, SnackBar(content: Text('Failed to update quantity')));
    }
  }

  Future<void> _removeItem(int index) async {
    final item = _cart!.items[index];
    setState(() => _processing = true);
    try {
      await _store.removeFromCart(itemId: item.id);
      await _loadCart();
    } catch (e) {
      if (mounted) Helpers.showInstantSnackBar(context, SnackBar(content: Text('Failed to remove item')));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _confirmAndRemove(int index) async {
    if (!mounted) return;
    final theme = Theme.of(context);
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Remove item',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (ctx, a1, a2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6.0, sigmaY: 6.0),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: AlertDialog(
                backgroundColor: theme.dialogBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                title: const Text('Remove item'),
                content: const Text('Are you sure you want to remove this item from your cart?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text('Cancel', style: TextStyle(color: theme.colorScheme.primary))),
                  ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('Remove')),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        return FadeTransition(opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: child);
      },
    );

    if (confirmed == true) {
      await _removeItem(index);
    }
  }

  Widget _buildItem(BuildContext ctx, int index) {
    final item = _cart!.items[index];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.cardColor; // adapt to theme
    final borderColor = isDark ? Colors.transparent : const Color(0xFFF3E8FF);
    final imageBg = isDark ? Colors.grey[800] : const Color.fromRGBO(250, 244, 253, 1);
    final qtyBg = isDark ? Colors.grey[900] : Colors.white;
    final deleteColor = isDark ? Colors.redAccent.shade200 : Colors.redAccent;
    final productNameStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 16) ?? const TextStyle(fontWeight: FontWeight.w800, fontSize: 16);
    final priceStyle = TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700);
    final mutedColor = theme.textTheme.bodySmall?.color?.withOpacity(0.85) ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.12 : 0.04), blurRadius: 12, offset: const Offset(0, 6))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // tappable product image -> open product detail
                GestureDetector(
                  onTap: () {
                    final slug = item.productSlug;
                    if (slug == null || slug.isEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: item.productId.toString())),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(slug: slug)),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 76,
                      height: 76,
                      color: imageBg,
                      child: item.imageUrl != null
                          ? Image.network(item.imageUrl!, fit: BoxFit.cover, width: 76, height: 76, loadingBuilder: (ctx, child, prog) {
                              if (prog == null) return child;
                              return const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)));
                            })
                          : Center(child: Icon(Icons.pets, color: theme.colorScheme.primary, size: 36)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.productName, style: productNameStyle),
                      const SizedBox(height: 6),
                      Text('$kCurrencySymbol${item.productPrice.toStringAsFixed(2)}', style: priceStyle),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          // quantity controls (rounded pill)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                            decoration: BoxDecoration(
                              color: qtyBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? Colors.grey[800]! : const Color(0xFFEDE7F6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _changeQuantity(index, -1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.remove, size: 18)),
                                ),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text(item.quantity.toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                                InkWell(
                                  onTap: () => _changeQuantity(index, 1),
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.add, size: 18)),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Subtotal column (label above, amount below) to avoid overflow
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Subtotal', style: TextStyle(color: mutedColor, fontSize: 12)),
                              const SizedBox(height: 6),
                              Text('$kCurrencySymbol${item.subtotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.textTheme.bodyLarge?.color)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // positioned delete button at top-right INSIDE the padded area (red circular style)
          Positioned(
            right: 8,
            top: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _processing ? null : () => _confirmAndRemove(index),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: deleteColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.18 : 0.08), blurRadius: 6, offset: const Offset(0, 2))]),
                  child: Icon(Icons.delete, size: 18, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Your Cart',
        showBackButton: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_cart == null || _cart!.items.isEmpty)
              ? Center(child: Text('Your cart is empty', style: Theme.of(context).textTheme.titleMedium))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadCart,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 12, bottom: 12),
                          itemCount: _cart!.items.length,
                          itemBuilder: _buildItem,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -6))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Order Summary Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 6))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Order Summary', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Subtotal', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                    Text('$kCurrencySymbol${_cart!.subtotal.toStringAsFixed(2)}', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Shipping', style: TextStyle(color: theme.textTheme.bodySmall?.color)),
                                    Text('Free', style: TextStyle(color: Colors.green[600], fontWeight: FontWeight.w600)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    Text('$kCurrencySymbol${_cart!.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Primary: Proceed to Checkout (rounded pill)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF9A6BFF), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                // more rounded pill
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [BoxShadow(color: const Color(0xFF7C3AED).withOpacity(0.18), blurRadius: 18, offset: const Offset(0, 8))],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(28),
                                  onTap: () async {
                                    if (!mounted) return;
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
                                  },
                                  child: const Center(
                                    child: Text('Proceed to Checkout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Secondary: Continue Shopping
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: theme.brightness == Brightness.dark ? Colors.white10 : Colors.white.withOpacity(0.06),
                                side: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.12)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () {
                                // Navigate to Store tab (replace stack)
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                                  (route) => false,
                                );
                              },
                              child: Text('Continue Shopping', style: TextStyle(color: theme.brightness == Brightness.dark ? theme.colorScheme.onSurface : Colors.black87, fontSize: 15)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
