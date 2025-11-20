import 'package:flutter/material.dart';

class CommunityTabConfig {
  static const double smallScreenWidth = 450;
  static const double largeScreenWidth = 600;

  static List<TabItem> tabs = [
    const TabItem(
      title: 'Feed',
      icon: Icons.feed,
      route: '/feed',
    ),
    const TabItem(
      title: 'Groups',
      icon: Icons.groups,
      route: '/groups',
    ),
    const TabItem(
      title: 'Events',
      icon: Icons.event,
      route: '/events',
    ),
    const TabItem(
      title: 'Lost & Found',
      icon: Icons.search,
      shortTitle: 'Lost',
      route: '/lost-found',
    ),
  ];
}

class TabItem {
  final String title;
  final String? shortTitle;
  final IconData icon;
  final String route;

  const TabItem({
    required this.title,
    required this.icon,
    required this.route,
    this.shortTitle,
  });

  String get displayTitle => shortTitle ?? title;
}

class TabBuilder {
  static Widget buildTab({
    required TabItem item,
    required bool isSmall,
    required bool isMedium,
    required bool isLarge,
  }) {
    if (isSmall) {
      return Tab(text: item.title);
    }

    return Tab(
      height: isLarge ? 50 : null,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: isLarge ? 20 : 18),
            SizedBox(width: isLarge ? 6 : 4),
            Text(isMedium ? item.displayTitle : item.title),
          ],
        ),
      ),
    );
  }
}