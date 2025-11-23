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
    IconData icon;
    VoidCallback onPressed;

    switch (_currentTabIndex) {
      case 0: // Feed
        icon = Icons.add_comment;
        onPressed = () => _navigateToCreateScreen(const CreatePostScreen());
        break;
      case 1: // Groups
        icon = Icons.group_add;
        onPressed = () => _navigateToCreateScreen(const CreateGroupScreen());
        break;
      case 2: // Events
        icon = Icons.event;
        onPressed = () => _navigateToCreateScreen(const CreateEventScreen());
        break;
      case 3: // Lost & Found
        icon = Icons.add_alert;
        onPressed = () => _navigateToCreateScreen(const CreateLostFoundScreen());
        break;
      default:
        return null;
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF6B46C1), Color(0xFF9F7AEA), Color(0xFFB794F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            // Fixed: replaced deprecated withOpacity with withValues
            color: const Color(0xFF6B46C1).withValues(alpha: 0.4), 
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCreateScreen(Widget screen) async {
    final posted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    if (posted == true && mounted) {
      if (_currentTabIndex == 0) {
        await Future.delayed(const Duration(milliseconds: 500));
        await context.read<CommunityProvider>().fetchPosts();
      } else if (_currentTabIndex == 1) {
        _refreshGroupsCallback?.call();
      } else if (_currentTabIndex == 2) {
        _refreshEventsCallback?.call();
      } else if (_currentTabIndex == 3) {
        _refreshLostFoundCallback?.call();
      }
    }
  }

  Future<void> _navigateToSearch() async {
    showDialog(
      context: context,
      builder: (context) => const UserSearchDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < CommunityTabConfig.smallScreenWidth;
    final isMediumScreen = screenWidth >= CommunityTabConfig.smallScreenWidth && 
                          screenWidth < CommunityTabConfig.largeScreenWidth;
    final isLargeScreen = screenWidth >= CommunityTabConfig.largeScreenWidth;
    
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
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
      body: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: isSmallScreen,
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
                labelPadding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 16 : (isMediumScreen ? 8 : 12),
                  vertical: isLargeScreen ? 4 : 0,
                ),
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
        ), // Closes Column
      ), // Closes Padding (This was missing!)
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0, right: 16.0),
        child: _buildFab(),
      ),
    );
  }

  List<Widget> _buildTabs(bool isSmall, bool isMedium, bool isLarge) {
    if (isSmall) {
      return const [
        Tab(text: 'Feed'),
        Tab(text: 'Groups'),
        Tab(text: 'Events'),
        Tab(text: 'Lost & Found'),
      ];
    } else if (isMedium) {
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