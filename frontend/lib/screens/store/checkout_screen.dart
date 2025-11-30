// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/store_service.dart';
import '../../models/store/cart_model.dart';
import '../../providers/auth_provider.dart';
import '../../utils/currency.dart';
import '../../providers/settings_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/custom_app_bar.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart? initialCart;
  const CheckoutScreen({super.key, this.initialCart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final StoreService _store = StoreService();
  bool _loading = true;
  bool _placing = false;
  Cart? _cart;

  // form fields
  final TextEditingController _nameCtl = TextEditingController();
  final TextEditingController _phoneCtl = TextEditingController();
  final TextEditingController _addressCtl = TextEditingController();
  final TextEditingController _cityCtl = TextEditingController();
  final TextEditingController _stateCtl = TextEditingController();
  final TextEditingController _pinCtl = TextEditingController();
  final TextEditingController _couponCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _phoneCtl.dispose();
    _addressCtl.dispose();
    _cityCtl.dispose();
    _pinCtl.dispose();
    _stateCtl.dispose();
    _couponCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Pre-fill from user profile if available. Obtain provider before any awaits.
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null) {
        _nameCtl.text = user.displayName;
        _phoneCtl.text = user.phone ?? '';
        // Do NOT auto-fill address — require user to enter address manually
        _addressCtl.text = '';
        _stateCtl.text = '';
      }

      // If an initial cart was provided (e.g. Buy Now), use it instead of fetching server cart
      if (widget.initialCart != null) {
        setState(() => _cart = widget.initialCart);
      } else {
        final data = await _store.fetchCart();
        if (data != null) {
          setState(() => _cart = Cart.fromJson(data));
        }
      }
    } catch (e) {
      debugPrint('Error loading checkout data: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get subtotal => _cart?.subtotal ?? 0.0;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
      if (_cart == null || _cart!.items.isEmpty) {
      showAppSnackBar(context, const SnackBar(content: Text('Your cart is empty')));
      return;
    }

    setState(() => _placing = true);
    try {
      // Build payload matching backend OrderViewSet.create expectations
      // compute totals locally to send to backend
      const double shippingCost = 0.0; // TODO: calculate or fetch based on address
      const double tax = 0.0;
      const double discount = 0.0; // TODO: apply coupon logic
      final double total = subtotal - discount + shippingCost + tax;

      // Get payment method from settings and normalize for backend
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      final rawMethod = settings.paymentMethod;
      String paymentMethodForApi;
      final rm = rawMethod.toLowerCase();
      if (rm == 'cod' || rm.contains('cod') || rm.contains('cash')) {
        paymentMethodForApi = 'cod';
      } else {
        // default to cod if unknown
        paymentMethodForApi = 'cod';
      }

      final payload = {
        'delivery_method': 'shipping',
        'shipping_address': _addressCtl.text.trim(),
        'shipping_city': _cityCtl.text.trim(),
        'shipping_state': _stateCtl.text.trim(),
        'shipping_zip': _pinCtl.text.trim(),
        'shipping_phone': _phoneCtl.text.trim(),
        'payment_method': paymentMethodForApi,
        // monetary fields expected by backend
        'subtotal': subtotal,
        'shipping_cost': shippingCost,
        'tax': tax,
        'discount_amount': discount,
        'total': total,
        'currency': 'NPR',
        'coupon_code': _couponCtl.text.trim().isNotEmpty ? _couponCtl.text.trim() : null,
      };

      // If this screen was opened with an initialCart (Buy Now), include items in the payload
      if (widget.initialCart?.items.isNotEmpty ?? false) {
        payload['items'] = widget.initialCart!.items
        .map((it) => {
          'product_id': it.productId,
          'product_price': it.productPrice,
          'quantity': it.quantity,
            })
        .toList();
      }

      final resp = await _store.createOrder(payload: payload);
      if (resp is Map<String, dynamic>) {
        if (mounted) showAppSnackBar(context, const SnackBar(content: Text('Order placed successfully')));
        if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => OrderConfirmationScreen(order: resp)));
      } else {
        if (mounted) showAppSnackBar(context, const SnackBar(content: Text('Checkout not implemented on server')));
      }
    } catch (e) {
      if (mounted) showAppSnackBar(context, SnackBar(content: Text('Failed to place order: $e')));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const CustomAppBar(title: 'Checkout', showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),
                            Text('Shipping Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameCtl,
                              decoration: const InputDecoration(labelText: 'Full name'),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneCtl,
                              decoration: const InputDecoration(labelText: 'Phone'),
                              keyboardType: TextInputType.phone,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a phone number' : null,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _addressCtl,
                              decoration: const InputDecoration(labelText: 'Address'),
                              maxLines: 3,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your address' : null,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextFormField(controller: _cityCtl, decoration: const InputDecoration(labelText: 'City'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter city' : null)),
                                const SizedBox(width: 12),
                                Expanded(child: TextFormField(controller: _stateCtl, decoration: const InputDecoration(labelText: 'State'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter state' : null)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: TextFormField(controller: _pinCtl, decoration: const InputDecoration(labelText: 'Pin'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter pin' : null)),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Text('Payment method', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            // Show currently selected payment method from settings
                            Card(
                              child: Builder(builder: (ctx) {
                                final settings = context.watch<SettingsProvider>();
                                return ListTile(
                                  leading: const Icon(Icons.money),
                                  title: Text(settings.paymentMethodLabel),
                                  subtitle: const Text('Pay when you receive the items'),
                                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                                );
                              }),
                            ),
                            const SizedBox(height: 18),
                            Text('Order Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // coupon
                                    TextFormField(
                                      controller: _couponCtl,
                                      decoration: const InputDecoration(labelText: 'Coupon code (optional)'),
                                    ),
                                    const SizedBox(height: 12),
                                    // List of items
                                    if (_cart?.items.isNotEmpty == true) ...[
                                      Column(
                                        children: List.generate(_cart!.items.length, (i) {
                                          final item = _cart!.items[i];
                                          return Column(
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 26,
                                                    backgroundColor: Colors.grey[100],
                                                    backgroundImage: item.imageUrl != null ? NetworkImage(item.imageUrl!) : null,
                                                    child: item.imageUrl == null ? Icon(Icons.pets, color: Theme.of(context).colorScheme.primary) : null,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(item.productName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                                        const SizedBox(height: 6),
                                                        Text('Qty: ${item.quantity}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withAlpha((0.8 * 255).round()))),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('$kCurrencySymbol${item.productPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                                ],
                                              ),
                                              if (i != _cart!.items.length - 1) ...[const SizedBox(height: 12), const Divider(height: 1), const SizedBox(height: 12)],
                                            ],
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 12),
                                      const Divider(height: 1),
                                      const SizedBox(height: 12),
                                    ] else ...[
                                      // fallback when cart empty
                                      Center(child: Text('No items', style: Theme.of(context).textTheme.bodyMedium)),
                                      const SizedBox(height: 12),
                                    ],

                                    // Totals
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Subtotal'), Text('$kCurrencySymbol${subtotal.toStringAsFixed(2)}')]),
                                    const SizedBox(height: 6),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Shipping'), const Text('Free', style: TextStyle(color: Colors.green))]),
                                    const SizedBox(height: 8),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)), Text('$kCurrencySymbol${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _placing ? null : _placeOrder,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _placing ? const CircularProgressIndicator(color: Colors.white) : const Text('Place Order', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
