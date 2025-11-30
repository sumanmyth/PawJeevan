import 'package:flutter/material.dart';
import '../../utils/currency.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../settings/send_feedback_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderDetailScreen({super.key, required this.order});

  String _fullImageUrl(String? url) {
    if (url == null) return '';
    final s = url.toString();
    if (s.isEmpty) return '';
    if (s.startsWith('http')) return s;
    if (s.startsWith('/')) return '${ApiConstants.baseUrl}$s';
    return '${ApiConstants.baseUrl}/$s';
  }

  String? _resolveItemImage(Map<String, dynamic> item) {
    try {
      // 1) Direct common keys (string)
      final direct = ['product_image', 'primary_image', 'image', 'image_url', 'product_image_url', 'thumbnail', 'photo', 'file', 'path', 'src', 'url', 'image_path', 'imageUrl'];
      for (final k in direct) {
        final v = item[k];
        if (v is String && v.isNotEmpty) return _fullImageUrl(v);
      }

      // 2) media field can be String, List or Map
      final media = item['media'] ?? item['images'] ?? item['photos'] ?? item['gallery'];
      if (media is String && media.isNotEmpty) return _fullImageUrl(media);
      if (media is List && media.isNotEmpty) {
        final first = media.first;
        if (first is String && first.isNotEmpty) return _fullImageUrl(first);
        if (first is Map) {
          for (final k in ['url', 'path', 'file', 'src']) {
            if (first[k] is String && (first[k] as String).isNotEmpty) return _fullImageUrl(first[k]);
          }
        }
      }
      if (media is Map) {
        for (final k in ['url', 'path', 'file', 'src']) {
          if (media[k] is String && (media[k] as String).isNotEmpty) return _fullImageUrl(media[k]);
        }
      }

      // 3) nested product object (Map) - try same logic as above
      final prod = item['product'];
      if (prod is Map<String, dynamic>) {
        for (final k in direct) {
          final v = prod[k];
          if (v is String && v.isNotEmpty) return _fullImageUrl(v);
        }
        final pmedia = prod['media'] ?? prod['images'] ?? prod['photos'];
        if (pmedia is String && pmedia.isNotEmpty) return _fullImageUrl(pmedia);
        if (pmedia is List && pmedia.isNotEmpty) {
          final first = pmedia.first;
          if (first is String && first.isNotEmpty) return _fullImageUrl(first);
          if (first is Map) {
            for (final k in ['url', 'path', 'file', 'src']) {
              if (first[k] is String && (first[k] as String).isNotEmpty) return _fullImageUrl(first[k]);
            }
          }
        }
      }

      // 4) fallback: find any string value that looks like an image filename (extension)
      final imageExt = RegExp(r'\.(jpg|jpeg|png|gif|webp|svg)(\?|$)', caseSensitive: false);
      for (final e in item.entries) {
        final v = e.value;
        if (v is String && v.isNotEmpty && imageExt.hasMatch(v)) return _fullImageUrl(v);
      }

      return null;
    } catch (_) {
      return null;
    }
  }



  Widget _buildTimeline(BuildContext context, int currentIndex, List<Map<String, String>> stepsWithKeys) {
    // Improved vertical timeline: use Theme colors so timeline is readable in dark mode
    final colorScheme = Theme.of(context).colorScheme;
    final onSurface = Theme.of(context).textTheme.bodyMedium?.color ?? colorScheme.onSurface;
    const accentColor = Color(0xFF7C3AED); // requested purple accent
    return Column(
      children: List.generate(stepsWithKeys.length, (i) {
        final step = stepsWithKeys[i];
        final label = step['label']!;
        final done = i <= currentIndex;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: done ? accentColor : Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: done ? accentColor : colorScheme.onSurface.withOpacity(0.12), width: 1.5),
                        boxShadow: done ? [BoxShadow(color: accentColor.withOpacity(0.12), blurRadius: 6, offset: const Offset(0, 2))] : null,
                      ),
                      child: Icon(
                          // pick an icon per step key; fallback to a circle marker
                          ({
                            'pending': Icons.shopping_bag,
                            'processing': Icons.autorenew,
                            'packed': Icons.inventory_2,
                            'shipped': Icons.local_shipping,
                            'delivered': Icons.home_filled,
                            'cancelled': Icons.cancel,
                            'refunded': Icons.receipt_long,
                          }[step['key'] ?? '']) ?? Icons.fiber_manual_record,
                          color: done ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
                          size: done ? 18 : 16),
                    ),
                    if (i < stepsWithKeys.length - 1)
                      Expanded(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.only(top: 8),
                          color: i < currentIndex ? accentColor.withOpacity(0.9) : colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: done ? onSurface : onSurface.withOpacity(0.9), fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(
                        step['timestamp']?.isNotEmpty == true ? step['timestamp']! : (done ? 'Completed' : 'Pending'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: print order summary and sample item keys to diagnose missing images
    try {
      final rawItems = order['items'];
      final previewItems = rawItems is List ? rawItems.cast<dynamic>() : <dynamic>[];
      print('OrderDetailScreen: order id=${order['id'] ?? order['order_number'] ?? 'unknown'} status=${order['status'] ?? ''} items_count=${previewItems.length}');
      if (previewItems.isNotEmpty) {
        final sample = previewItems.first;
        if (sample is Map) print('OrderDetailScreen: sample item keys=${sample.keys.toList()}');
        else print('OrderDetailScreen: sample item value=$sample');
      }
    } catch (e) {
      print('OrderDetailScreen: debug print failed: $e');
    }
    final orderNo = order['order_number'] ?? order['id']?.toString() ?? '—';
    final created = order['created_at'] ?? '';
    final deliveryEstimate = order['delivery_estimate'] ?? ''; // optional field
    final status = order['status'] ?? '';
    final rawItems = order['items'];
    final items = rawItems is List ? rawItems.cast<dynamic>() : <dynamic>[];
    final itemCount = items.length;
    final shippingAddress = (order['shipping_address'] ?? '').toString();
    final shippingCity = (order['shipping_city'] ?? '').toString();
    final shippingState = (order['shipping_state'] ?? '').toString();
    final shippingZip = (order['shipping_zip'] ?? '').toString();
    final shippingPhone = (order['shipping_phone'] ?? '').toString();

    // Build ordered steps and attach timestamps from backend fields if available
    final s = (status ?? '').toString().toLowerCase();
    // Timeline steps (removed "Out for Delivery" as requested)
    final stepsWithKeys = <Map<String, String>>[
      {'key': 'pending', 'label': 'Order Placed', 'timestamp': (order['placed_at'] ?? created ?? '').toString()},
      {'key': 'processing', 'label': 'Processing', 'timestamp': (order['processing_at'] ?? '').toString()},
      {'key': 'packed', 'label': 'Packed', 'timestamp': (order['packed_at'] ?? '').toString()},
      {'key': 'shipped', 'label': 'Shipped', 'timestamp': (order['shipped_at'] ?? order['dispatched_at'] ?? '').toString()},
      {'key': 'delivered', 'label': 'Delivered', 'timestamp': (order['delivered_at'] ?? '').toString()},
    ];

    // If order has been cancelled or refunded, present that as a terminal step
    if (s.contains('cancel')) {
      stepsWithKeys.add({'key': 'cancelled', 'label': 'Cancelled', 'timestamp': (order['cancelled_at'] ?? '').toString()});
    } else if (s.contains('refund') || s.contains('refunded')) {
      stepsWithKeys.add({'key': 'refunded', 'label': 'Refunded', 'timestamp': (order['refunded_at'] ?? '').toString()});
    }

    // Compute current index based on status string
    int currentIndex = 0;
    for (var i = 0; i < stepsWithKeys.length; i++) {
      final key = stepsWithKeys[i]['key']!.toLowerCase();
      if (s.contains(key) || s == key.replaceAll(' ', '_')) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Order Tracking', showBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / order summary
            Text(deliveryEstimate.isNotEmpty ? 'Arriving $deliveryEstimate' : 'Order Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: Theme.of(context).dividerColor,
                        child: Builder(builder: (ctx) {
                          final firstItem = items.isNotEmpty ? (items.first as Map<String, dynamic>) : null;
                          final thumb = firstItem != null ? _resolveItemImage(firstItem) : null;
                          if (thumb != null && thumb.isNotEmpty) {
                            return Image.network(
                              thumb,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              loadingBuilder: (c, child, progress) => progress == null ? child : Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
                              errorBuilder: (_, __, ___) => Icon(Icons.pets, size: 36, color: Theme.of(context).primaryColor),
                            );
                          }
                          return Center(child: Icon(Icons.pets, size: 36, color: Theme.of(context).primaryColor));
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order #$orderNo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 6),
                          Text(items.isNotEmpty ? (items.first['product_name'] ?? '') : '', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text('$kCurrencySymbol${double.tryParse((order['total'] ?? order['subtotal'] ?? 0).toString())?.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('$itemCount item${itemCount == 1 ? '' : 's'}', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // status chip (theme-aware colors for dark mode)
                    Builder(builder: (ctx) {
                      final bool isDelivered = s.contains('deliv') || s.contains('delivered');
                      final bool isPacked = s.contains('packed');
                      const accentColor = Color(0xFF7C3AED);
                      final chipTextColor = isDelivered ? Colors.green : (isPacked ? accentColor : accentColor);
                      final chipBg = chipTextColor.withOpacity(0.12);
                      final labelText = s.contains('pending')
                          ? 'Pending'
                          : (s.contains('processing') ? 'Processing' : (s.contains('packed') ? 'Packed' : (s.contains('shipped') ? 'Shipped' : (s.contains('deliv') ? 'Delivered' : s.toString()))));
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: chipBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(labelText, style: TextStyle(color: chipTextColor, fontWeight: FontWeight.w700)),
                      );
                    })
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Timeline
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildTimeline(context, currentIndex, stepsWithKeys),
              ),
            ),

            const SizedBox(height: 12),

            // Order Details (expandable) — hide any top/bottom dividers from ExpansionTile
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                dividerTheme: const DividerThemeData(color: Colors.transparent, thickness: 0, space: 0),
              ),
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  title: const Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('$itemCount items from your order', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                  children: [
                    ...items.map((it) {
                      final m = it as Map<String, dynamic>;
                      final name = (m['product_name'] ?? m['name'] ?? '') as String;
                      final qty = m['quantity'] ?? m['qty'] ?? 1;
                      final price = m['product_price'] ?? m['price'] ?? 0;
                      final resolved = _resolveItemImage(m);
                      // Debug: print resolved URL for each item
                      try {
                        print('OrderDetailScreen: resolved image for item "$name" -> $resolved');
                      } catch (_) {}
                      return ListTile(
                        leading: resolved != null && resolved.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  resolved,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 56, height: 56, color: Theme.of(context).dividerColor),
                                  loadingBuilder: (ctx, child, progress) {
                                    if (progress == null) return child;
                                    return Container(width: 56, height: 56, color: Theme.of(context).dividerColor);
                                  },
                                ),
                              )
                            : ClipRRect(borderRadius: BorderRadius.circular(8), child: Container(width: 56, height: 56, color: Theme.of(context).dividerColor)),
                        title: Text(name),
                        subtitle: Text('Qty: $qty'),
                        trailing: Text('$kCurrencySymbol${double.tryParse(price.toString())?.toStringAsFixed(2) ?? price}'),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: MediaQuery.of(context).size.width > 700 ? 420 : double.infinity,
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Shipping Information', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Shipping to: ${shippingAddress.isNotEmpty ? '$shippingAddress, ' : ''}$shippingCity${shippingState.isNotEmpty ? ', $shippingState' : ''}${shippingZip.isNotEmpty ? ' $shippingZip' : ''}'),
                        const SizedBox(height: 8),
                        Text('Phone: ${shippingPhone.isNotEmpty ? shippingPhone : '—'}'),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: SizedBox(
                width: double.infinity,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Open the same Send Feedback screen used in Settings
                      final subj = 'Order #$orderNo — Support Request';
                      final msg = 'Order ID: $orderNo\nStatus: ${status ?? ''}\n\nPlease describe your issue or question here:\n- ';
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SendFeedbackScreen(initialSubject: subj, initialMessage: msg)),
                      );
                    },
                    icon: const Icon(Icons.support_agent, size: 20),
                    label: const Text('Contact Support', style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                      elevation: 6,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
