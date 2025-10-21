import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_app_bar.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'payment_method_screen.dart';
import 'send_feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings', showBackButton: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _Header(title: 'Notifications'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: settings.pushNotifications,
                  onChanged: (v) => context.read<SettingsProvider>().setPushNotifications(v),
                  title: const Text('Push Notifications'),
                  subtitle: const Text('Receive general notifications'),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: settings.promoNotifications,
                  onChanged: (v) => context.read<SettingsProvider>().setPromoNotifications(v),
                  title: const Text('Promotions'),
                  subtitle: const Text('Get offers and promotional updates'),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: settings.newProductNotifications,
                  onChanged: (v) => context.read<SettingsProvider>().setNewProductNotifications(v),
                  title: const Text('New Products'),
                  subtitle: const Text('Be notified when new products arrive'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const _Header(title: 'App Settings'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Language'),
                  subtitle: Text(settings.language),
                  leading: const Icon(Icons.language, color: Colors.purple),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showLanguageSheet(context),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: settings.darkMode,
                  onChanged: (v) => context.read<SettingsProvider>().setDarkMode(v),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Reduce eye strain with a dark theme'),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Payment Method'),
                  subtitle: Text(settings.paymentMethod),
                  leading: const Icon(Icons.payment, color: Colors.purple),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final updated = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
                    );
                    if (updated == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment method updated')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const _Header(title: 'Account Actions'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                ListTile(
                  title: const Text('Edit Profile'),
                  leading: const Icon(Icons.person, color: Colors.purple),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final ok = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                    );
                    if (ok == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile updated')),
                      );
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Change Password'),
                  leading: const Icon(Icons.lock, color: Colors.purple),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Send Feedback'),
                  leading: const Icon(Icons.feedback, color: Colors.purple),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _sendFeedback(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final langs = ['English', 'हिंदी (Hindi)', 'Español', 'Français', 'Deutsch'];
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: langs.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (ctx, i) {
            final lang = langs[i];
            final selected = (settings.language == lang);
            return ListTile(
              title: Text(lang),
              trailing: selected ? const Icon(Icons.check, color: Colors.purple) : null,
              onTap: () async {
                await settings.setLanguage(lang);
                if (ctx.mounted) Navigator.pop(ctx);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Language saved (restart may be required)')),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  void _sendFeedback(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SendFeedbackScreen()),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}