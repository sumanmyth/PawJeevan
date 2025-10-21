import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../models/user_model.dart';
import 'user_profile_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final community = context.read<CommunityProvider>();
    try {
      if (widget.isFollowers) {
        _users = await community.getFollowers(widget.userId, force: true);
      } else {
        _users = await community.getFollowing(widget.userId, force: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load ${widget.title.toLowerCase()}: $e')),
        );
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

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            Text(
              '${_users.length} ${widget.title.toLowerCase()}',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: _users.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark 
                                  ? Colors.purple.shade900.withOpacity(0.3) 
                                  : Colors.purple.shade50,
                                border: Border.all(
                                  color: isDark 
                                    ? Colors.purple.shade300.withOpacity(0.3) 
                                    : Colors.purple.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                widget.isFollowers ? Icons.group_off : Icons.person_off,
                                size: 64,
                                color: isDark 
                                  ? Colors.purple.shade200 
                                  : Colors.purple.shade400,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No ${widget.title.toLowerCase()} yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: isDark 
                                  ? Colors.purple.shade200 
                                  : Colors.purple.shade800,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.isFollowers 
                                ? 'When other users follow you, they\'ll appear here'
                                : 'When you follow other users, they\'ll appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark 
                                  ? Colors.purple.shade300.withOpacity(0.8) 
                                  : Colors.purple.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: isDark ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isDark 
                                  ? Colors.purple.shade300.withOpacity(0.3) 
                                  : Colors.purple.shade200,
                              ),
                            ),
                            color: isDark 
                              ? Colors.purple.shade900.withOpacity(0.2) 
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
                                            ? Colors.purple.shade300 
                                            : Colors.purple.shade200,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: isDark 
                                          ? Colors.purple.shade800 
                                          : Colors.purple.shade50,
                                        backgroundImage: user.avatarUrl != null 
                                          ? NetworkImage(user.avatarUrl!) 
                                          : null,
                                        child: user.avatarUrl == null
                                          ? Icon(Icons.person, 
                                              size: 30,
                                              color: isDark 
                                                ? Colors.purple.shade200 
                                                : Colors.purple.shade400)
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
                                                : Colors.purple.shade900,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '@${user.username}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark 
                                                ? Colors.purple.shade200 
                                                : Colors.purple.shade600,
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
                                                  ? Colors.purple.shade200.withOpacity(0.8) 
                                                  : Colors.purple.shade700,
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
                                        ? Colors.purple.shade300 
                                        : Colors.purple.shade400,
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