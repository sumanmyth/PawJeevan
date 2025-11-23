import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../models/user/user_model.dart';
import '../profile/user_profile_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../utils/helpers.dart';

class FollowListScreen extends StatefulWidget {
  final int userId;
  final String title;
  final bool isFollowers; // true for followers, false for following

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowers,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  bool _isLoading = true;
  List<User> _users = [];
  List<User> _filteredUsers = [];
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.displayName.toLowerCase().contains(query) ||
                 user.username.toLowerCase().contains(query) ||
                 (user.bio?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final community = context.read<CommunityProvider>();
    try {
      if (widget.isFollowers) {
        _users = await community.getFollowers(widget.userId, force: true);
      } else {
        _users = await community.getFollowing(widget.userId, force: true);
      }
      _filteredUsers = _users;
    } catch (e) {
      if (mounted) {
        final errorText = e.toString();
        // Check if it's a locked profile error
        if (errorText.contains('locked') || errorText.contains('private') || errorText.contains('403')) {
          _errorMessage = 'This profile is locked.\n${widget.isFollowers ? 'Followers' : 'Following'} list is private.';
        } else {
            _errorMessage = 'Failed to load ${widget.title.toLowerCase()}';
            Helpers.showInstantSnackBar(
              context,
              SnackBar(content: Text('Error: $e')),
            );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: true,
        titleWidget: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}...',
                hintStyle: const TextStyle(
                  color: Colors.black45,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_errorMessage == null)
                  Text(
                    '${_filteredUsers.length} ${widget.title.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
        actions: [
          if (_errorMessage == null && _users.isNotEmpty)
            IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _searchController.clear();
                  }
                });
              },
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: Padding(padding: EdgeInsets.only(top: topPadding), child: const CircularProgressIndicator()))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: topPadding + 32, left: 32, right: 32, bottom: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color.fromRGBO(124, 58, 237, 0.3),
                            border: Border.all(
                              color: const Color.fromRGBO(124, 58, 237, 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_outline,
                            size: 64,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Profile Locked',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark 
                              ? const Color.fromRGBO(124, 58, 237, 0.8) 
                              : const Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
              onRefresh: _loadData,
              child: _filteredUsers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: topPadding + 32, left: 32, right: 32, bottom: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark 
                                  ? const Color.fromRGBO(124, 58, 237, 0.3) 
                                  : const Color(0xFF7C3AED),
                                border: Border.all(
                                  color: isDark 
                                    ? const Color.fromRGBO(124, 58, 237, 0.3) 
                                    : const Color(0xFF7C3AED),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                  _searchController.text.isNotEmpty 
                                    ? Icons.search_off
                                    : widget.isFollowers ? Icons.group_off : Icons.person_off,
                                  size: 64,
                                  color: isDark ? const Color(0xFF7C3AED) : Colors.white,
                                ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              _searchController.text.isNotEmpty 
                                ? 'No results found'
                                : 'No ${widget.title.toLowerCase()} yet',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchController.text.isNotEmpty 
                                ? 'Try searching with different keywords'
                                : widget.isFollowers 
                                  ? 'When other users follow you, they\'ll appear here'
                                  : 'When you follow other users, they\'ll appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? const Color.fromRGBO(124, 58, 237, 0.8) : const Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(top: topPadding + 8, bottom: 16),
                      itemCount: _filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = _filteredUsers[index];
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: isDark ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark 
                                  ? const Color.fromRGBO(124, 58, 237, 0.3) 
                                  : const Color(0xFF7C3AED),
                              ),
                            ),
                            color: isDark 
                              ? const Color.fromRGBO(124, 58, 237, 0.2) 
                              : Colors.white,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => UserProfileScreen(userId: user.id),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Avatar with border
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDark 
                                            ? const Color(0xFF7C3AED) 
                                            : const Color(0xFF7C3AED),
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                          backgroundColor: isDark 
                                            ? const Color(0xFF7C3AED) 
                                            : const Color(0xFF7C3AED),
                                        backgroundImage: user.avatarUrl != null 
                                          ? NetworkImage(user.avatarUrl!) 
                                          : null,
                                        child: user.avatarUrl == null
                                          ? const Icon(Icons.person, 
                                              size: 30,
                                              color: Color(0xFF7C3AED))
                                          : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // User info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user.displayName,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: isDark 
                                                ? Colors.white 
                                                : const Color(0xFF7C3AED),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '@${user.username}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark 
                                                ? const Color(0xFF7C3AED) 
                        : const Color(0xFF7C3AED),
                                            ),
                                          ),
                                          if (user.bio?.isNotEmpty ?? false) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              user.bio!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: isDark 
                                                  ? const Color.fromRGBO(124, 58, 237, 0.8) 
                                                  : const Color(0xFF7C3AED),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Arrow icon
                                    Icon(
                                      Icons.chevron_right,
                                      color: isDark 
                                        ? const Color(0xFF7C3AED) 
                                        : const Color(0xFF7C3AED),
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
    );
  }
}