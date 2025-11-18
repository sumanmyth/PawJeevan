import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/feed_filter.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/post_card.dart';

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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            selected: _currentFilter == FeedFilter.recent,
            label: const Text('Recent'),
            avatar: const Icon(Icons.access_time),
            onSelected: (selected) {
              setState(() {
                _currentFilter = FeedFilter.recent;
                context.read<CommunityProvider>().fetchPosts(filter: _currentFilter);
              });
            },
            selectedColor: Colors.purple.shade100,
            checkmarkColor: Colors.purple,
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _currentFilter == FeedFilter.trending,
            label: const Text('Trending'),
            avatar: const Icon(Icons.trending_up),
            onSelected: (selected) {
              setState(() {
                _currentFilter = FeedFilter.trending;
                context.read<CommunityProvider>().fetchPosts(filter: _currentFilter);
              });
            },
            selectedColor: Colors.purple.shade100,
            checkmarkColor: Colors.purple,
          ),
          const SizedBox(width: 8),
          FilterChip(
            selected: _currentFilter == FeedFilter.followed,
            label: const Text('Following'),
            avatar: const Icon(Icons.people),
            onSelected: (selected) {
              setState(() {
                _currentFilter = FeedFilter.followed;
                context.read<CommunityProvider>().fetchPosts(filter: _currentFilter);
              });
            },
            selectedColor: Colors.purple.shade100,
            checkmarkColor: Colors.purple,
          ),
        ],
      ),
    );
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
                    onPressed: () => provider.fetchPosts(filter: _currentFilter),
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
            controller: _scrollController,
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
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