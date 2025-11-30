import 'package:flutter/material.dart';
import '../../utils/currency.dart';
import '../../widgets/custom_app_bar.dart';
import '../common/main_screen.dart';
import 'order_detail_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Map<String, dynamic> order;
  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7C3AED);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = theme.textTheme.headlineSmall?.color ?? theme.colorScheme.onSurface;
    final orderNo = order['order_number'] ?? order['id']?.toString() ?? '—';
    final total = order['total'] ?? order['subtotal'] ?? 0;
    final address = (order['shipping_address'] ?? '').toString();
    final email = (order['email'] ?? order['user_email'] ?? '').toString();
    final emailHint = email.isNotEmpty ? ' ($email)' : '';

    return Scaffold(
      appBar: const CustomAppBar(title: 'Confirmation', showBackButton: false),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  // Use translucent accent background and purple tick in both themes
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(Icons.check_circle, size: 48, color: accent),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Order Confirmed', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: primaryTextColor)),
            const SizedBox(height: 8),
            Text(
              'Your order has been placed. We will notify you when the order is shipped.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 6),
            Text(
              'A confirmation receipt has been sent to your email$emailHint.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color),
            ),

            const SizedBox(height: 18),
            // summary card (no estimated delivery)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Order Number', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('#${orderNo.toString()}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Total Amount'), Text('$kCurrencySymbol${double.tryParse(total.toString())?.toStringAsFixed(2) ?? total}', style: TextStyle(fontWeight: FontWeight.w700, color: theme.textTheme.bodyLarge?.color))]),
                    const SizedBox(height: 10),
                    if (address.isNotEmpty) ...[
                      const Divider(height: 18),
                      Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(address, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),
            // buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  // View Order Details
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
                },
                child: const Text('View Order Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: accent.withOpacity(0.12)),
                  backgroundColor: isDark ? Colors.white10 : accent.withOpacity(0.08),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Continue shopping: open MainScreen on Store tab
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1)),
                    (route) => false,
                  );
                },
                child: Text('Continue Shopping', style: TextStyle(color: isDark ? theme.colorScheme.onSurface : Colors.black87, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
