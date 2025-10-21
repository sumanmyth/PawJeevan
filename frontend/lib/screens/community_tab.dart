import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/community_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../models/post_model.dart';
import 'community/create_post_screen.dart';
import 'community/create_group_screen.dart';
import 'community/create_event_screen.dart';
import 'community/create_lost_found_screen.dart';
import 'post_detail_screen.dart';
import 'user_profile_screen.dart';
import '../widgets/post_options_menu.dart';

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 450;
    final isMediumScreen = screenWidth >= 450 && screenWidth < 600;
    final isLargeScreen = screenWidth >= 600;
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Community',
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
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
              children: const [
                _FeedTab(),
                _GroupsTab(),
                _EventsTab(),
                _LostFoundTab(),
              ],
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

// Rest of your widgets remain the same
class _FeedTab extends StatefulWidget {
  const _FeedTab();
  @override
  State<_FeedTab> createState() => __FeedTabState();
}

class __FeedTabState extends State<_FeedTab> {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    
    final provider = context.read<CommunityProvider>();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      await provider.fetchPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommunityProvider>(
      builder: (_, provider, __) {
        Widget mainContent;
        
        if (provider.posts.isEmpty) {
          if (provider.isLoading) {
            mainContent = const Center(child: CircularProgressIndicator());
          } else if (provider.error != null) {
            mainContent = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.fetchPosts,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            mainContent = const Center(child: Text('No posts yet. Be the first!'));
          }
        } else {
          mainContent = ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.posts.length,
            itemBuilder: (context, index) {
              final post = provider.posts[index];
              return _PostCard(post: post);
            },
          );
        }

        return RefreshIndicator(
          onRefresh: provider.fetchPosts,
          child: mainContent,
        );
      },
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CommunityProvider>();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.purple.shade300.withOpacity(0.3) : Colors.purple.withOpacity(0.3)
        ),
      ),
      color: isDark ? Colors.purple.shade900.withOpacity(0.2) : Colors.purple.shade50.withOpacity(0.7),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: post.isCurrentUserAuthor 
                  ? null 
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.author)),
                    ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: isDark ? [
                            Colors.purple.shade200,
                            Colors.purple.shade400,
                          ] : [
                            Colors.purple.shade300,
                            Colors.purple.shade200,
                          ],
                        ),
                        border: Border.all(
                          color: isDark ? Colors.purple.shade200 : Colors.purple.shade300, 
                          width: 2
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade100,
                        backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
                        child: post.authorAvatar == null ? Icon(Icons.person, color: Colors.purple.shade700) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorUsername,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            timeago.format(post.createdAt),
                            style: TextStyle(
                              color: isDark ? Colors.purple.shade300 : Colors.purple.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        print('Opening post options for post ${post.id}');
                        print('Is current user author: ${post.isCurrentUserAuthor}');
                        showModalBottomSheet(
                          context: context,
                          builder: (context) => PostOptionsMenu(
                            post: post,
                            onDeleted: () {
                              context.read<CommunityProvider>().fetchPosts();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.purple.shade200.withOpacity(0.3) : Colors.purple.shade100
                  ),
                ),
                child: Text(
                  post.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.purple.shade100 : Colors.purple.shade900,
                    height: 1.4,
                  ),
                ),
              ),
              if (post.image != null) ...[
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.shade100.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(post.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                      backgroundColor: isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => provider.toggleLike(post.id),
                    icon: Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : (isDark ? Colors.purple.shade200 : Colors.purple.shade700),
                      size: 20,
                    ),
                    label: Text(
                      '${post.likesCount}',
                      style: TextStyle(color: isDark ? Colors.purple.shade200 : Colors.purple.shade700),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                      backgroundColor: isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
                    ),
                    icon: Icon(
                      Icons.comment_outlined, 
                      color: isDark ? Colors.purple.shade200 : Colors.purple.shade700, 
                      size: 20
                    ),
                    label: Text(
                      '${post.commentsCount}',
                      style: TextStyle(color: isDark ? Colors.purple.shade200 : Colors.purple.shade700),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                      backgroundColor: isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () {},
                    icon: Icon(
                      Icons.share_outlined, 
                      color: isDark ? Colors.purple.shade200 : Colors.purple.shade700, 
                      size: 20
                    ),
                    label: Text(
                      'Share', 
                      style: TextStyle(color: isDark ? Colors.purple.shade200 : Colors.purple.shade700)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupsTab extends StatelessWidget {
  const _GroupsTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Groups - Coming Soon'));
}

class _EventsTab extends StatelessWidget {
  const _EventsTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Events - Coming Soon'));
}

class _LostFoundTab extends StatelessWidget {
  const _LostFoundTab();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Lost & Found - Coming Soon'));
}
