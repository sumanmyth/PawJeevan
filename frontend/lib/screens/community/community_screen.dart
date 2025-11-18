import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/community_provider.dart';
import '../../widgets/custom_app_bar.dart';
import 'posts/create_post_screen.dart';
import 'groups/create_group_screen.dart';
import 'events/create_event_screen.dart';
import 'lost_found/create_lost_found_screen.dart';
import 'user_search_screen.dart';
import 'community_config.dart';
import 'tabs/feed_tab.dart';
import 'tabs/groups_tab.dart';
import 'tabs/events_tab.dart';
import 'tabs/lost_found_tab.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  VoidCallback? _refreshGroupsCallback;
  VoidCallback? _refreshEventsCallback;
  VoidCallback? _refreshLostFoundCallback;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (mounted) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget? _buildFab() {
    switch (_currentTabIndex) {
      case 0: // Feed
        return FloatingActionButton(
          onPressed: () => _navigateToCreateScreen(const CreatePostScreen()),
          backgroundColor: Colors.purple,
          tooltip: 'Create Post',
          child: const Icon(Icons.add_comment),
        );
      case 1: // Groups
        return FloatingActionButton(
          onPressed: () => _navigateToCreateScreen(const CreateGroupScreen()),
          backgroundColor: Colors.purple,
          tooltip: 'Create Group',
          child: const Icon(Icons.group_add),
        );
      case 2: // Events
        return FloatingActionButton(
          onPressed: () => _navigateToCreateScreen(const CreateEventScreen()),
          backgroundColor: Colors.purple,
          tooltip: 'Create Event',
          child: const Icon(Icons.event),
        );
      case 3: // Lost & Found
        return FloatingActionButton(
          onPressed: () => _navigateToCreateScreen(const CreateLostFoundScreen()),
          backgroundColor: Colors.purple,
          tooltip: 'Create Report',
          child: const Icon(Icons.add_alert),
        );
      default:
        return null;
    }
  }

  Future<void> _navigateToCreateScreen(Widget screen) async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (posted == true && mounted) {
      if (_currentTabIndex == 0) {
        // Add a small delay before fetching posts to ensure server processing
        await Future.delayed(const Duration(milliseconds: 500));
        await context.read<CommunityProvider>().fetchPosts();
      } else if (_currentTabIndex == 1) {
        // Refresh groups tab using callback
        _refreshGroupsCallback?.call();
      } else if (_currentTabIndex == 2) {
        // Refresh events tab using callback
        _refreshEventsCallback?.call();
      } else if (_currentTabIndex == 3) {
        // Refresh lost & found tab using callback
        _refreshLostFoundCallback?.call();
      }
    }
  }

  Future<void> _navigateToSearch() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserSearchScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < CommunityTabConfig.smallScreenWidth;
    final isMediumScreen = screenWidth >= CommunityTabConfig.smallScreenWidth && 
                          screenWidth < CommunityTabConfig.largeScreenWidth;
    final isLargeScreen = screenWidth >= CommunityTabConfig.largeScreenWidth;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Community',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Users',
            onPressed: _navigateToSearch,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              // Scrollable on small screens to ensure all tabs are visible
              isScrollable: isSmallScreen,
              // Center alignment for scrollable tabs
              tabAlignment: isSmallScreen 
                ? TabAlignment.center 
                : TabAlignment.fill,
              labelColor: Colors.purple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.purple,
              indicatorSize: isSmallScreen 
                ? TabBarIndicatorSize.label 
                : TabBarIndicatorSize.tab,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                fontSize: isLargeScreen ? 16 : (isMediumScreen ? 14 : 14),
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: isLargeScreen ? 16 : (isMediumScreen ? 14 : 14),
                fontWeight: FontWeight.normal,
              ),
              // Dynamic padding based on screen size
              labelPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : (isMediumScreen ? 8 : 12),
                vertical: isLargeScreen ? 4 : 0,
              ),
              // Container padding for scroll indicators on small screens
              padding: isSmallScreen 
                ? const EdgeInsets.symmetric(horizontal: 8) 
                : EdgeInsets.zero,
              tabs: _buildTabs(isSmallScreen, isMediumScreen, isLargeScreen),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: CommunityTabConfig.tabs.map((tab) {
                switch (tab.route) {
                  case '/feed':
                    return const FeedTab();
                  case '/groups':
                    return GroupsTab(
                      onRefreshCallbackRegistered: (callback) {
                        _refreshGroupsCallback = callback;
                      },
                    );
                  case '/events':
                    return EventsTab(
                      onRefreshCallbackRegistered: (callback) {
                        _refreshEventsCallback = callback;
                      },
                    );
                  case '/lost-found':
                    return LostFoundTab(
                      onRefreshCallbackRegistered: (callback) {
                        _refreshLostFoundCallback = callback;
                      },
                    );
                  default:
                    return const SizedBox.shrink();
                }
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  List<Widget> _buildTabs(bool isSmall, bool isMedium, bool isLarge) {
    if (isSmall) {
      // Small screens - text only, but full text (scrollable)
      return const [
        Tab(text: 'Feed'),
        Tab(text: 'Groups'),
        Tab(text: 'Events'),
        Tab(text: 'Lost & Found'),
      ];
    } else if (isMedium) {
      // Medium screens - icons with text, wrapped to prevent overflow
      return [
        const Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed, size: 18),
                SizedBox(width: 4),
                Text('Feed'),
              ],
            ),
          ),
        ),
        const Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups, size: 18),
                SizedBox(width: 4),
                Text('Groups'),
              ],
            ),
          ),
        ),
        const Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, size: 18),
                SizedBox(width: 4),
                Text('Events'),
              ],
            ),
          ),
        ),
        const Tab(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 18),
                SizedBox(width: 4),
                Text('Lost'),
              ],
            ),
          ),
        ),
      ];
    } else {
      // Large screens - full size with icons and complete text
      return [
        const Tab(
          height: 50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.feed, size: 20),
                SizedBox(width: 6),
                Text('Feed'),
              ],
            ),
          ),
        ),
        const Tab(
          height: 50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups, size: 20),
                SizedBox(width: 6),
                Text('Groups'),
              ],
            ),
          ),
        ),
        const Tab(
          height: 50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event, size: 20),
                SizedBox(width: 6),
                Text('Events'),
              ],
            ),
          ),
        ),
        const Tab(
          height: 50,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 20),
                SizedBox(width: 6),
                Text('Lost & Found'),
              ],
            ),
          ),
        ),
      ];
    }
  }
}


