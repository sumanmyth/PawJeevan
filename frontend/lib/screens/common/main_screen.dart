import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fact_provider.dart';
import '../tabs/home_tab.dart';
import '../tabs/store_tab.dart';
import '../tabs/ai_tab.dart';
import '../community/community_screen.dart';
import '../tabs/profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  // PageController removed to prevent PageView from painting multiple pages

  final _tabs = [
    const HomeTab(),
    const StoreTab(),
    const AiTab(),
    const CommunityScreen(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: GestureDetector(
        // Simple horizontal swipe handler to change tabs while ensuring
        // only the active page is painted (IndexedStack) to avoid ghosting.
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 200) return; // ignore slow drags
          setState(() {
            if (velocity < 0) {
              // swipe left -> next
              _currentIndex = (_currentIndex + 1).clamp(0, _tabs.length - 1);
            } else {
              // swipe right -> previous
              _currentIndex = (_currentIndex - 1).clamp(0, _tabs.length - 1);
            }
          });
          if (_currentIndex == 0) {
            Provider.of<FactProvider>(context, listen: false).nextFact();
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _tabs,
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
            // Slightly smaller blur for a more subtle frosted effect
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(
              // Slightly more opaque so the nav feels less transparent
              color: isDark
              ? Colors.black.withOpacity(0.60)
              : Colors.white.withOpacity(0.72),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  indicatorColor: isDark
                      ? const Color(0xFF6B46C1).withOpacity(0.3)
                      : Colors.purple.shade100,
                  labelTextStyle: MaterialStateProperty.all(
                    TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                child: _buildGlidingNavigationBar(isDark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlidingNavigationBar(bool isDark) {
    final itemCount = _tabs.length;
    return SizedBox(
      height: 75,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullWidth = constraints.maxWidth;
          final horizontalPadding = 12.0;
          final usableWidth = fullWidth - (horizontalPadding * 2);

          double indicatorFactor;
          if (fullWidth < 360) {
            indicatorFactor = 0.82;
          } else if (fullWidth < 420) {
            indicatorFactor = 0.78;
          } else if (fullWidth < 600) {
            indicatorFactor = 0.72;
          } else if (fullWidth < 900) {
            indicatorFactor = 0.68;
          } else {
            indicatorFactor = 0.60;
          }

          final itemWidth = usableWidth / itemCount;
          final indicatorWidth = itemWidth * indicatorFactor;
          double leftPos = horizontalPadding + (_currentIndex * itemWidth) + (itemWidth - indicatorWidth) / 2;
          final minLeft = horizontalPadding;
          final maxLeft = fullWidth - horizontalPadding - indicatorWidth;
          if (leftPos < minLeft) leftPos = minLeft;
          if (leftPos > maxLeft) leftPos = maxLeft;

          final Color selectedColor = isDark ? const Color(0xFFB794F6) : const Color(0xFF6B46C1);

          return Stack(
            alignment: Alignment.centerLeft,
            children: [
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

              // items
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    children: List.generate(itemCount, (i) {
                      final selected = i == _currentIndex;
                      late final Widget icon;
                      late final Widget selectedIcon;

                      if (i == 0) {
                        icon = SizedBox(width: 24, height: 24, child: Icon(Icons.home_outlined, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700));
                        selectedIcon = SizedBox(width: 24, height: 24, child: Icon(Icons.home, size: 24, color: selectedColor));
                      } else if (i == 1) {
                        icon = SizedBox(width: 24, height: 24, child: Icon(Icons.shopping_bag_outlined, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700));
                        selectedIcon = SizedBox(width: 24, height: 24, child: Icon(Icons.shopping_bag, size: 24, color: selectedColor));
                      } else if (i == 2) {
                        icon = SizedBox(width: 24, height: 24, child: Icon(Icons.smart_toy_outlined, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700));
                        selectedIcon = SizedBox(width: 24, height: 24, child: Icon(Icons.smart_toy, size: 24, color: selectedColor));
                      } else if (i == 3) {
                        icon = SizedBox(width: 24, height: 24, child: Icon(Icons.people_outline, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700));
                        selectedIcon = SizedBox(width: 24, height: 24, child: Icon(Icons.people, size: 24, color: selectedColor));
                      } else {
                        icon = SizedBox(width: 24, height: 24, child: Icon(Icons.person_outline, size: 24, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700));
                        selectedIcon = SizedBox(width: 24, height: 24, child: Icon(Icons.person, size: 24, color: selectedColor));
                      }

                      final label = i == 0
                          ? 'Home'
                          : i == 1
                              ? 'Store'
                              : i == 2
                                  ? 'AI'
                                  : i == 3
                                      ? 'Community'
                                      : 'Profile';

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _currentIndex = i;
                            });
                            if (i == 0) {
                              Provider.of<FactProvider>(context, listen: false).nextFact();
                            }
                          },
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
                                  child: selected ? selectedIcon : icon,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: selected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
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