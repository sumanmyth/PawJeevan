import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/common/feed_filter.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/post_card.dart';
import '../../../widgets/post_skeleton.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  bool _initialLoadDone = false;
  bool _isFilterVisible = true;
  FeedFilter _currentFilter = FeedFilter.recent;
  final ScrollController _scrollController = ScrollController();
  double _lastScrollPosition = 0;

  @override
  void initState() {
    super.initState();
    _loadPosts();
    _setupScrollController();
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels < 0) return;
      
      // Compare current scroll position with last position to determine direction
      if (_scrollController.position.pixels > _lastScrollPosition) {
        // Scrolling down - hide filter
        if (_isFilterVisible) {
          setState(() => _isFilterVisible = false);
        }
      } else {
        // Scrolling up - show filter
        if (!_isFilterVisible) {
          setState(() => _isFilterVisible = true);
        }
      }
      _lastScrollPosition = _scrollController.position.pixels;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    
    final provider = context.read<CommunityProvider>();
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      await provider.fetchPosts(filter: _currentFilter);
    }
  }

  Widget _buildFilterChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            selected: _currentFilter == FeedFilter.recent,
            label: Text(
              'Recent',
              style: TextStyle(
                color: _currentFilter == FeedFilter.recent
                  ? const Color(0xFF7C3AED)
                  : (isDark ? Colors.white : const Color(0xFF7C3AED)),
              ),
            ),
            avatar: Icon(
              Icons.access_time,
              color: _currentFilter == FeedFilter.recent
                  ? const Color(0xFF7C3AED)
                  : (isDark ? Colors.white70 : const Color(0xFF7C3AED)),
            ),
            onSelected: (selected) {
              setState(() {
                _currentFilter = FeedFilter.recent;
                context.read<CommunityProvider>().fetchPosts(filter: _currentFilter);
              });
            },
            selectedColor: isDark ? const Color.fromRGBO(124, 58, 237, 0.12) : const Color.fromRGBO(124, 58, 237, 0.08),
            backgroundColor: isDark ? Colors.grey.shade800 : null,
            checkmarkColor: const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _currentFilter == FeedFilter.trending,
            label: Text(
              'Trending',
              style: TextStyle(
                color: _currentFilter == FeedFilter.trending
                    ? const Color(0xFF7C3AED)
                    : (isDark ? Colors.white : const Color(0xFF7C3AED)),
              ),
            ),
            avatar: Icon(
              Icons.trending_up,
              color: _currentFilter == FeedFilter.trending
                  ? const Color(0xFF7C3AED)
                  : (isDark ? Colors.white70 : const Color(0xFF7C3AED)),
            ),
            onSelected: (selected) {
              setState(() {
                _currentFilter = FeedFilter.trending;
                context.read<CommunityProvider>().fetchPosts(filter: _currentFilter);
              });
            },
            selectedColor: isDark ? const Color.fromRGBO(124, 58, 237, 0.12) : const Color.fromRGBO(124, 58, 237, 0.08),
            backgroundColor: isDark ? Colors.grey.shade800 : null,
            checkmarkColor: const Color(0xFF7C3AED),
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _currentFilter == FeedFilter.followed,
            label: Text(
              'Following',
              style: TextStyle(
                color: _currentFilter == FeedFilter.followed
                    ? const Color(0xFF7C3AED)
                    : (isDark ? Colors.white : const Color(0xFF7C3AED)),
              ),
            ),
            avatar: Icon(
              Icons.people,
              color: _currentFilter == FeedFilter.followed
                  ? const Color(0xFF7C3AED)
                  : (isDark ? Colors.white70 : const Color(0xFF7C3AED)),
            ),
            onSelected: (selected) {
              setState(() {
                _currentFilter = FeedFilter.followed;
                context.read<CommunityProvider>().fetchPosts(filter: _currentFilter);
              });
            },
            selectedColor: isDark ? const Color.fromRGBO(124, 58, 237, 0.12) : const Color.fromRGBO(124, 58, 237, 0.08),
            backgroundColor: isDark ? Colors.grey.shade800 : null,
            checkmarkColor: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer<CommunityProvider>(
      builder: (_, provider, __) {
        Widget mainContent;
        
        if (provider.posts.isEmpty) {
          if (provider.isLoading) {
            // show skeleton placeholders while loading
            mainContent = ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 110,
              ),
              itemCount: 3,
              itemBuilder: (context, index) => const PostSkeleton(),
            );
          } else if (provider.error != null) {
            mainContent = Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${provider.error}',
                    style: TextStyle(
                      color: isDark ? Colors.red.shade200 : Colors.red.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchPosts(filter: _currentFilter),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            mainContent = Center(
              child: Text(
                'No posts yet. Be the first!',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            );
          }
        } else {
          mainContent = ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 110,
            ),
            itemCount: provider.posts.length,
            itemBuilder: (context, index) {
              final post = provider.posts[index];
              return PostCard(key: ValueKey(post.id), post: post);
            },
          );
        }

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _isFilterVisible ? 56.0 : 0.0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isFilterVisible ? 1.0 : 0.0,
                child: _buildFilterChips(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => provider.fetchPosts(filter: _currentFilter),
                child: mainContent,
              ),
            ),
          ],
        );
      },
    );
  }
}