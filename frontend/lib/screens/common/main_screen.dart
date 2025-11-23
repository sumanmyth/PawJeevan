import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fact_provider.dart';
import '../tabs/home_tab.dart';
import '../tabs/store_tab.dart';
import '../tabs/ai_tab.dart';
import '../community/community_screen.dart';
import '../tabs/profile_tab.dart';

class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) => child;
}

class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<_NavItem> _navItems = [
    const _NavItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home', page: HomeTab()),
    const _NavItem(icon: Icons.shopping_bag_outlined, selectedIcon: Icons.shopping_bag, label: 'Store', page: StoreTab()),
    const _NavItem(icon: Icons.smart_toy_outlined, selectedIcon: Icons.smart_toy, label: 'AI', page: AiTab()),
    const _NavItem(icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Community', page: CommunityScreen()),
    const _NavItem(icon: Icons.person_outline, selectedIcon: Icons.person, label: 'Profile', page: ProfileTab()),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: ScrollConfiguration(
        behavior: _NoGlowScrollBehavior(),
        child: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (int idx) {
            setState(() {
              _currentIndex = idx;
            });
            if (idx == 0) {
              Provider.of<FactProvider>(context, listen: false).nextFact();
            }
          },
          children: _navItems.map((e) => e.page).toList(),
        ),
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 25,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              color: isDark
                  ? Colors.black.withOpacity(0.60)
                  : Colors.white.withOpacity(0.72),
              child: _buildGlidingNavigationBar(isDark, context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlidingNavigationBar(bool isDark, BuildContext context) {
    final itemCount = _navItems.length;
    
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    final double barHeight = 75 + (bottomPadding > 0 ? bottomPadding / 2 : 0);

    return SizedBox(
      height: barHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth;
          final horizontalPadding = 12.0;
          final usableWidth = fullWidth - (horizontalPadding * 2);

          double indicatorFactor;
          if (fullWidth < 360) indicatorFactor = 0.82;
          else if (fullWidth < 420) indicatorFactor = 0.78;
          else if (fullWidth < 600) indicatorFactor = 0.72;
          else if (fullWidth < 900) indicatorFactor = 0.68;
          else indicatorFactor = 0.60;

          final itemWidth = usableWidth / itemCount;
          final indicatorWidth = itemWidth * indicatorFactor;
          
          double leftPos = horizontalPadding + (_currentIndex * itemWidth) + (itemWidth - indicatorWidth) / 2;
          
          final Color selectedColor = isDark ? const Color(0xFFB794F6) : const Color(0xFF6B46C1);
          final Color unselectedColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
              // 1. Gliding Pill - This will ALWAYS slide smoothly
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
                left: leftPos,
                top: 12,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  width: indicatorWidth,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selectedColor.withOpacity(isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),

              // 2. Icons
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, bottomPadding > 0 ? 10 : 0),
                  child: Row(
                    children: List.generate(itemCount, (i) {
                      final item = _navItems[i];
                      final selected = i == _currentIndex;

                      return Expanded(
                        child: InkWell(
                          // --- LOGIC START ---
                          onTap: () {
                            final int difference = (i - _currentIndex).abs();
                            
                            if (difference > 1) {
                              // TELEPORT: If skipping tabs (e.g. 1 to 3), cut instantly.
                              _pageController.jumpToPage(i);
                            } else {
                              // SLIDE: If neighbor (e.g. 1 to 2), animate smoothly.
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          // --- LOGIC END ---
                          borderRadius: BorderRadius.zero,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                  child: SizedBox(
                                    key: ValueKey(selected),
                                    width: 24,
                                    height: 24,
                                    child: Icon(
                                      selected ? item.selectedIcon : item.icon,
                                      size: 24,
                                      color: selected ? selectedColor : unselectedColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? (isDark ? Colors.white : Colors.black87) : unselectedColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}