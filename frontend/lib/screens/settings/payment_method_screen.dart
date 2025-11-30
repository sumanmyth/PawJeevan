import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/custom_app_bar.dart';

class PaymentMethodScreen extends StatelessWidget {
  const PaymentMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    // Only expose Cash on delivery for now. Store value as 'COD'.
    final methods = {'COD': 'Cash on delivery'};
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Payment Method', showBackButton: true),
      body: ListView.separated(
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
        itemCount: methods.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (ctx, i) {
          final entry = methods.entries.elementAt(i);
          final code = entry.key;
          final label = entry.value;
          final selected = (settings.paymentMethod == code);
          return ListTile(
            title: Text(label),
            trailing: selected ? const Icon(Icons.check, color: Color(0xFF7C3AED)) : null,
            onTap: () async {
              await context.read<SettingsProvider>().setPaymentMethod(code);
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