import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/auth_provider.dart';
import '../../providers/fact_provider.dart';
import '../../providers/notification_provider.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/helpers.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

// Primary purple used across Home tab cards
const Color _kPrimaryPurple = Color(0xFF7C3AED);

class _HomeTabState extends State<HomeTab> {
  bool _showWelcome = false;
  int? _lastUserId;

  @override
  void initState() {
    super.initState();
    _checkWelcomeStatus();
  }

  Future<void> _checkWelcomeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShownWelcome = prefs.getBool('has_shown_welcome') ?? false;
    
    if (!hasShownWelcome) {
      if (mounted) {
        setState(() {
          _showWelcome = true;
        });
      }
      
      await prefs.setBool('has_shown_welcome', true);
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showWelcome = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final factProvider = Provider.of<FactProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (user?.id != _lastUserId) {
      _lastUserId = user?.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        factProvider.nextFact();
      });
    }

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'PawJeevan',
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  if (notificationProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          notificationProvider.unreadCount <= 99 
                              ? '${notificationProvider.unreadCount}' 
                              : '99+',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Helpers.showInstantSnackBar(
                context,
                const SnackBar(content: Text('Cart - Coming soon!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: EdgeInsets.only(top: topPadding, bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Welcome Banner
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: _showWelcome ? null : 0,
              child: AnimatedOpacity(
                opacity: _showWelcome ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7C3AED),
                        Color.fromRGBO(124, 58, 237, 0.85),
                        Color.fromRGBO(124, 58, 237, 0.65),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(124, 58, 237, 0.3),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned(
                        right: -20,
                        top: -20,
                        child: Opacity(
                          opacity: 0.1,
                          child: Icon(Icons.pets, size: 120, color: Colors.white),
                        ),
                      ),
                      const Positioned(
                        right: 40,
                        bottom: -30,
                        child: Opacity(
                          opacity: 0.08,
                          child: Icon(Icons.pets, size: 100, color: Colors.white),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color.fromRGBO(255, 255, 255, 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.waving_hand, color: Colors.white, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Welcome Back!',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    user?.displayName ?? 'Pet Lover',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromRGBO(255, 255, 255, 0.95),
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Ready to make a difference in a pet\'s life today?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color.fromRGBO(255, 255, 255, 0.85),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(255, 255, 255, 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.3), width: 2),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                onPressed: () {
                                  setState(() {
                                    _showWelcome = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Did You Know card
            const _DidYouKnowCard(),

            const SizedBox(height: 8),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.shopping_cart,
                          label: 'Shop',
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.camera_alt,
                          label: 'Scan Pet',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.chat,
                          label: 'AI Chat',
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.group,
                          label: 'Community',
                          color: Colors.pink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Featured Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Products',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Helpers.showInstantSnackBar(
                            context,
                            const SnackBar(content: Text('Shop - Coming soon!')),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return _FeaturedProductCard(index: index);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tips & Articles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pet Care Tips',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _TipCard(
                    title: 'Daily Exercise',
                    description: 'Keep your pet active and healthy',
                    icon: Icons.directions_run,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 8),
                  const _TipCard(
                    title: 'Balanced Diet',
                    description: 'Nutrition tips for your furry friend',
                    icon: Icons.restaurant,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  const _TipCard(
                    title: 'Regular Checkups',
                    description: 'Schedule vet appointments',
                    icon: Icons.medical_services,
                    color: Colors.red,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(content: Text('$label - Coming soon!')),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedProductCard extends StatelessWidget {
  final int index;
  const _FeaturedProductCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12, bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
           onTap: () {
             Helpers.showInstantSnackBar(
              context,
              SnackBar(content: Text('Product ${index + 1} - Coming soon!')),
             );
           },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                decoration: const BoxDecoration(
                  color: Color.fromRGBO(124, 58, 237, 0.1),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                    child: Icon(Icons.pets, size: 50, color: _kPrimaryPurple),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product ${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$${(index + 1) * 10}.99',
                      style: const TextStyle(
                        color: _kPrimaryPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TipCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(content: Text('$title - Coming soon!')),
        );
      },
      borderRadius: BorderRadius.circular(12),
        child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(124, 58, 237, 0.03),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color.withOpacity(0.75)),
          ],
        ),
      ),
    );
  }
}

class _DidYouKnowCard extends StatelessWidget {
  // FIXED: Removed {super.key} entirely. 
  // Since this is a private class and 'key' is never passed to it, the analyzer marks it as unused.
  const _DidYouKnowCard();

  @override
  Widget build(BuildContext context) {
    final factProvider = context.watch<FactProvider>();
    final fact = factProvider.currentFact;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C3AED),
            Color.fromRGBO(124, 58, 237, 0.85),
            Color.fromRGBO(124, 58, 237, 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(124, 58, 237, 0.18),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorations
          const Positioned(
            right: -6, top: -12,
            child: Opacity(opacity: 0.10, child: Icon(Icons.pets, size: 100, color: Colors.white)),
          ),
          const Positioned(
            right: 36, bottom: -12,
            child: Opacity(opacity: 0.07, child: Icon(Icons.pets, size: 72, color: Colors.white)),
          ),
          const Positioned(
            left: -8, top: -4,
            child: Opacity(opacity: 0.06, child: Icon(Icons.pets, size: 72, color: Colors.white)),
          ),
          const Positioned(
            bottom: -26, left: 0, right: 0,
            child: Center(child: Opacity(opacity: 0.06, child: Icon(Icons.pets, size: 88, color: Colors.white))),
          ),
          const Positioned(
            left: 20, bottom: 10,
            child: Opacity(opacity: 0.06, child: Icon(Icons.pets, size: 56, color: Colors.white)),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14).copyWith(bottom: 64),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lightbulb, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Did You Know?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                  child: Text(
                    fact,
                    key: ValueKey<String>(fact),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.35),
                  ),
                ),
              ],
            ),
          ),

          // Tappable area for full fact
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                splashColor: Colors.white10,
                onTap: () {
                  showDialog<void>(
                    context: context,
                    barrierColor: const Color.fromRGBO(0, 0, 0, 0.5),
                    builder: (context) => BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Dialog(
                        backgroundColor: Colors.transparent,
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 520),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade900.withOpacity(0.95)
                              : const Color.fromRGBO(255, 255, 255, 0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(0, 0, 0, 0.18),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Did You Know?',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              Text(fact, style: const TextStyle(fontSize: 15, height: 1.4)),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      factProvider.nextFact();
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _kPrimaryPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Next Fact'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Next Fact Button
          Positioned(
            right: 14,
            bottom: 12,
            child: TextButton(
              onPressed: () => factProvider.nextFact(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.12),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Next Fact', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}