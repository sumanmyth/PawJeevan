import 'package:flutter/material.dart';
import '../../services/store_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../utils/currency.dart';
import '../../widgets/custom_app_bar.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final StoreService _store = StoreService();
  bool _loading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final data = await _store.fetchOrders();
      if (mounted) setState(() => _orders = data);
    } catch (e) {
      if (mounted) showAppSnackBar(context, SnackBar(content: Text('Failed to load orders: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildOrderTile(Map<String, dynamic> order) {
    final items = (order['items'] as List<dynamic>?) ?? [];
    final first = items.isNotEmpty ? items.first as Map<String, dynamic> : null;
    final subtitle = first != null ? '${first['product_name'] ?? ''}${items.length > 1 ? '  •  +${items.length - 1} more' : ''}' : 'No items';
    final total = order['total'] ?? order['subtotal'] ?? 0;
    final created = order['created_at'] ?? '';
    final orderNo = order['order_number'] ?? '—';
    // derive status and color
    final statusRaw = (order['status'] ?? '').toString().toLowerCase();
    String statusLabel = statusRaw.isNotEmpty ? statusRaw : 'pending';
    Color statusColor = Colors.orange;
    if (statusRaw.contains('pending')) {
      statusLabel = 'Pending';
      statusColor = Colors.orange;
    } else if (statusRaw.contains('processing')) {
      statusLabel = 'Processing';
      statusColor = Colors.blue;
    } else if (statusRaw.contains('packed')) {
      statusLabel = 'Packed';
      statusColor = Colors.purple;
    } else if (statusRaw.contains('shipped')) {
      statusLabel = 'Shipped';
      statusColor = Colors.teal;
    } else if (statusRaw.contains('delivered')) {
      statusLabel = 'Delivered';
      statusColor = Colors.green;
    } else if (statusRaw.contains('cancel') || statusRaw.contains('refun')) {
      statusLabel = statusRaw.contains('refun') ? 'Refunded' : 'Cancelled';
      statusColor = Colors.red;
    }

    String? thumbUrl;
    try {
      thumbUrl = (first?['product_image'] ?? first?['image'] ?? first?['image_url'] ?? first?['product']?['image'] ?? first?['product']?['primary_image'] ?? '')?.toString();
      if (thumbUrl != null && thumbUrl.isEmpty) thumbUrl = null;
    } catch (_) {
      thumbUrl = null;
    }

    String fullImageUrl(String? url) {
      if (url == null || url.isEmpty) return '';
      // If already absolute, return as is
      if (url.startsWith('http://') || url.startsWith('https://')) return url;
      return '${ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '')}/${url.replaceAll(RegExp(r'^/+'), '')}';
    }

    final brightness = Theme.of(context).brightness;
    final chipBg = brightness == Brightness.dark ? statusColor.withOpacity(0.22) : statusColor.withOpacity(0.12);
    final priceBg = brightness == Brightness.dark ? Theme.of(context).colorScheme.primary.withOpacity(0.16) : Theme.of(context).colorScheme.primary.withOpacity(0.08);
    final borderClr = Theme.of(context).dividerColor.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
          if (mounted) await _loadOrders();
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: borderClr),
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: thumbUrl != null && thumbUrl.isNotEmpty
                    ? Image.network(
                        fullImageUrl(thumbUrl),
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(width: 56, height: 56, color: Theme.of(context).dividerColor, child: const Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))));
                        },
                        errorBuilder: (context, error, stackTrace) => Container(width: 56, height: 56, color: Theme.of(context).dividerColor, child: Icon(Icons.pets, color: Theme.of(context).primaryColor)),
                      )
                    : Container(width: 56, height: 56, color: Theme.of(context).dividerColor, child: Icon(Icons.pets, color: Theme.of(context).primaryColor)),
              ),
              const SizedBox(width: 12),
              // main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order label and number (left)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(orderNo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                    const SizedBox(height: 6),
                    Text(created, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8))),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // status (top-right) and price button (right)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // status chip at top-right
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(20)),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  const SizedBox(height: 8),
                  // price as a button-like pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: priceBg, borderRadius: BorderRadius.circular(10)),
                    child: Text('$kCurrencySymbol${double.tryParse(total.toString())?.toStringAsFixed(2) ?? total}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'My Orders', showBackButton: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(child: Text('No orders yet', style: Theme.of(context).textTheme.titleMedium))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 12, bottom: 24),
                    itemCount: _orders.length,
                    itemBuilder: (_, i) => _buildOrderTile(_orders[i]),
                  ),
                ),
    );
  }
}
