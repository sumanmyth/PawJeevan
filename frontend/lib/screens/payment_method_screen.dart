import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_app_bar.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final methods = ['Card', 'UPI', 'NetBanking', 'COD'];

    return Scaffold(
      appBar: const CustomAppBar(title: 'Payment Method', showBackButton: true),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: methods.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final m = methods[i];
          final selected = (settings.paymentMethod == m);
          return ListTile(
            title: Text(m),
            trailing: selected ? const Icon(Icons.check, color: Colors.purple) : null,
            onTap: () async {
              await context.read<SettingsProvider>().setPaymentMethod(m);
              if (ctx.mounted) {
                Navigator.pop(ctx, true);
              }
            },
          );
        },
      ),
    );
  }
}