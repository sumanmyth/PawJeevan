import 'package:flutter/material.dart';
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

  final _tabs = [
    const HomeTab(),
    const StoreTab(),
    const AiTab(),
    const CommunityScreen(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      // Each tab manages its own (curved) custom app bar; keep body clean here
      body: _tabs[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            indicatorColor: isDark 
                ? const Color(0xFF6B46C1).withOpacity(0.3)
                : Colors.purple.shade100,
            backgroundColor: isDark 
                ? Colors.grey.shade900
                : Colors.white,
            height: 70,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              NavigationDestination(
                icon: Icon(
                  Icons.home_outlined,
                  color: isDark ? Colors.grey.shade400 : null,
                ),
                selectedIcon: Icon(
                  Icons.home,
                  color: isDark ? const Color(0xFFB794F6) : const Color(0xFF6B46C1),
                ),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.shopping_bag_outlined,
                  color: isDark ? Colors.grey.shade400 : null,
                ),
                selectedIcon: Icon(
                  Icons.shopping_bag,
                  color: isDark ? const Color(0xFFB794F6) : const Color(0xFF6B46C1),
                ),
                label: 'Store',
              ),
              NavigationDestination(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _currentIndex == 2
                          ? [
                              const Color(0xFF6B46C1),
                              const Color(0xFF9F7AEA),
                              const Color(0xFFB794F6),
                            ]
                          : [
                              isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            ],
                    ),
                  ),
                  child: Icon(
                    _currentIndex == 2 ? Icons.smart_toy : Icons.smart_toy_outlined,
                    color: _currentIndex == 2 
                        ? Colors.white 
                        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    size: 24,
                  ),
                ),
                selectedIcon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6B46C1),
                        Color(0xFF9F7AEA),
                        Color(0xFFB794F6),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                label: 'AI',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.people_outline,
                  color: isDark ? Colors.grey.shade400 : null,
                ),
                selectedIcon: Icon(
                  Icons.people,
                  color: isDark ? const Color(0xFFB794F6) : const Color(0xFF6B46C1),
                ),
                label: 'Community',
              ),
              NavigationDestination(
                icon: Icon(
                  Icons.person_outline,
                  color: isDark ? Colors.grey.shade400 : null,
                ),
                selectedIcon: Icon(
                  Icons.person,
                  color: isDark ? const Color(0xFFB794F6) : const Color(0xFF6B46C1),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}