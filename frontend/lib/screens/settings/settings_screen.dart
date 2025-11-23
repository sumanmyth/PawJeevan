import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Ensure these imports point to your actual file locations
import '../../providers/settings_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/helpers.dart';
import '../profile/edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'payment_method_screen.dart';
import 'send_feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure your SettingsProvider is properly registered in main.dart
    final settings = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate padding to avoid content hiding behind transparent AppBars
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Settings', showBackButton: true),
      body: ListView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
        children: [
          const _Header(title: 'Notifications'),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ModernSwitchTile(
                value: settings.promoNotifications,
                onChanged: (v) => context.read<SettingsProvider>().setPromoNotifications(v),
                title: 'Promotions',
                subtitle: 'Get offers and promotional updates',
                icon: Icons.local_offer,
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _ModernSwitchTile(
                value: settings.newProductNotifications,
                onChanged: (v) => context.read<SettingsProvider>().setNewProductNotifications(v),
                title: 'New Products',
                subtitle: 'Be notified when new products arrive',
                icon: Icons.new_releases,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 20),

          const _Header(title: 'Privacy'),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ModernSwitchTile(
                value: settings.profileLocked,
                onChanged: (v) async {
                  try {
                    await context.read<SettingsProvider>().setProfileLocked(v);
                      if (context.mounted) {
                      Helpers.showInstantSnackBar(
                        context,
                        SnackBar(
                          content: Text(v 
                            ? 'Profile locked. Your posts are now private.' 
                            : 'Profile unlocked. Your posts are now public.'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    }
                  } catch (e) {
                      if (context.mounted) {
                      Helpers.showInstantSnackBar(
                        context,
                        SnackBar(
                          content: Text('Failed to update: $e'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                title: 'Lock Profile',
                subtitle: 'Hide posts, followers, and following',
                icon: Icons.lock_outline,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 20),

          const _Header(title: 'App Settings'),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ModernListTile(
                title: 'Language',
                subtitle: settings.language,
                icon: Icons.language,
                isDark: isDark,
                onTap: () => _showLanguageSheet(context),
              ),
              _Divider(isDark: isDark),
              _ModernSwitchTile(
                value: settings.darkMode,
                onChanged: (v) => context.read<SettingsProvider>().setDarkMode(v),
                title: 'Dark Mode',
                subtitle: 'Reduce eye strain with a dark theme',
                icon: Icons.dark_mode,
                isDark: isDark,
              ),
              _Divider(isDark: isDark),
              _ModernListTile(
                title: 'Payment Method',
                subtitle: settings.paymentMethod,
                icon: Icons.payment,
                isDark: isDark,
                onTap: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentMethodScreen()),
                  );
                  if (updated == true && context.mounted) {
                    Helpers.showInstantSnackBar(
                      context,
                      const SnackBar(content: Text('Payment method updated')),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          const _Header(title: 'Account Actions'),
          _SettingsCard(
            isDark: isDark,
            children: [
              _ModernListTile(
                title: 'Edit Profile',
                subtitle: 'Update your information',
                icon: Icons.person,
                isDark: isDark,
                onTap: () async {
                  final ok = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                  if (ok == true && context.mounted) {
                    Helpers.showInstantSnackBar(
                      context,
                      const SnackBar(content: Text('Profile updated')),
                    );
                  }
                },
              ),
              _Divider(isDark: isDark),
              _ModernListTile(
                title: 'Change Password',
                subtitle: 'Update your password',
                icon: Icons.lock,
                isDark: isDark,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  );
                },
              ),
              _Divider(isDark: isDark),
              _ModernListTile(
                title: 'Send Feedback',
                subtitle: 'Help us improve',
                icon: Icons.feedback,
                isDark: isDark,
                onTap: () => _sendFeedback(context),
              ),
            ],
          ),

          const SizedBox(height: 24),
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
              trailing: selected ? const Icon(Icons.check, color: Color(0xFF7C3AED)) : null,
              onTap: () async {
                await settings.setLanguage(lang);
                if (ctx.mounted) Navigator.pop(ctx);
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
    // Removed unused 'isDark' variable
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF7C3AED),
          fontWeight: FontWeight.bold,
          fontSize: 15,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsCard({
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.grey.shade900.withOpacity(0.5) 
          : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color.fromRGBO(124, 58, 237, 0.3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(124, 58, 237, 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ModernListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _ModernListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // FIXED: Changed opacity from 0.8 to 0.1. 
                // Before: Purple background + Purple icon = Invisible icon.
                // Now: Light Purple tint background + Purple icon = Visible.
                color: const Color(0xFF7C3AED).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF7C3AED),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernSwitchTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDark;

  const _ModernSwitchTile({
    required this.value,
    required this.onChanged,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
               // FIXED: Changed opacity from 0.8 to 0.1 for visibility
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7C3AED),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;

  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      color: Color.fromRGBO(124, 58, 237, 0.2),
    );
  }
}