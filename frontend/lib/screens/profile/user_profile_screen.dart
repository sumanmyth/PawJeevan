import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/user/user_model.dart';
import '../../models/community/post_model.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../community/posts/post_detail_screen.dart';
import '../community/follow_list_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void didUpdateWidget(UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload data if userId changes
    if (oldWidget.userId != widget.userId) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    if (!mounted || _isLoading) return;
    
    setState(() {
      _isLoading = true;
    });
    
    final provider = context.read<CommunityProvider>();
    final authProvider = context.read<AuthProvider>();
    
    try {
      // Get fresh user data first
      await provider.getUser(widget.userId, force: true);
      
      // Check if profile is locked and if current user is not the owner
      final user = provider.user(widget.userId);
      final isOwnProfile = authProvider.user?.id == widget.userId;
      
      // Only load posts if profile is not locked or it's own profile
      if (user != null && (!user.isProfileLocked || isOwnProfile)) {
        await provider.getUserPosts(widget.userId);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = community.user(widget.userId);
    final isOwnProfile = authProvider.user?.id == widget.userId;
    
    // Only get cached posts if profile is not locked or it's own profile
    final userPosts = (user != null && (!user.isProfileLocked || isOwnProfile))
        ? community.cachedUserPosts(widget.userId)
        : <Post>[];

    return Scaffold(
      appBar: CustomAppBar(
        title: user?.displayName ?? 'User Profile',
        showBackButton: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildProfileHeader(context, user),
                    _buildPostsList(context, userPosts),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, User user) {
    return Container(
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B46C1),
            Color(0xFF9F7AEA),
            Color(0xFFB794F6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Decorative paw patterns
          Positioned(
            top: 20,
            right: 20,
            child: Icon(
              Icons.pets,
              size: 80,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: Icon(
              Icons.pets,
              size: 60,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Positioned(
            top: 100,
            left: 20,
            child: Icon(
              Icons.pets,
              size: 40,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    if (user.avatarUrl != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImage(
                            imageUrl: user.avatarUrl!,
                            tag: 'user_avatar_${user.id}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade300, Colors.purple.shade500],
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Name and username
                Text(
                  user.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                
                // Bio if available
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    user.bio!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
                
                // Location if available
                if (user.location != null && user.location!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on, 
                        size: 16, 
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        user.location!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 20),
                
                // Stats row
                Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Followers',
                    user.followersCount,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FollowListScreen(
                            userId: user.id,
                            title: 'Followers',
                            isFollowers: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Following',
                    user.followingCount,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FollowListScreen(
                            userId: user.id,
                            title: 'Following',
                            isFollowers: false,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
                
                const SizedBox(height: 20),
                
                // Follow/Unfollow button - only show for other users
                if (context.read<AuthProvider>().user?.id != user.id) ...[
                  SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final community = context.read<CommunityProvider>();
                  final auth = context.read<AuthProvider>();
                  
                  try {
                    await community.followUser(user.id, unfollow: user.isFollowing);
                    
                    // The community provider now handles refreshing both users,
                    // we just need to update the auth provider's local user state
                    if (mounted) {
                      final currentUser = community.user(auth.user?.id ?? 0);
                      if (currentUser != null) {
                        auth.updateLocalUser(currentUser);
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to ${user.isFollowing ? "unfollow" : "follow"} user'),
                        ),
                      );
                    }
                  }
                },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: user.isFollowing 
                      ? Colors.red.shade400 
                      : Colors.green.shade500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  icon: Icon(user.isFollowing ? Icons.person_remove : Icons.person_add),
                  label: Text(
                    user.isFollowing ? 'Unfollow' : 'Follow',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, int count, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.purple.shade300.withOpacity(0.3) : Colors.purple.shade200,
              width: 1,
            ),
            color: isDark ? Colors.purple.shade900.withOpacity(0.2) : Colors.white.withOpacity(0.7),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.purple.shade900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsList(BuildContext context, List<Post> posts) {
    final community = context.watch<CommunityProvider>();
    final user = community.user(widget.userId);
    final currentUser = context.read<AuthProvider>().user;
    final isOwnProfile = currentUser?.id == widget.userId;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Check if profile is locked and user is not the owner
    if (user != null && user.isProfileLocked && !isOwnProfile) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
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
                Icons.lock_outline, 
                size: 64, 
                color: isDark 
                  ? Colors.purple.shade200 
                  : Colors.purple.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Locked',
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
              'This user\'s posts are private',
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
      );
    }
    
    if (posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.post_add, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No posts yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        return _buildPostCard(context, post);
      },
    );
  }

  Widget _buildPostCard(BuildContext context, Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isDark ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark
              ? Colors.purple.shade300.withOpacity(0.3)
              : Colors.purple.withOpacity(0.3),
        ),
      ),
      color: isDark
          ? Colors.purple.shade900.withOpacity(0.2)
          : Colors.purple.shade50.withOpacity(0.7),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PostDetailScreen(postId: post.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timestamp
              Text(
                timeago.format(post.createdAt),
                style: TextStyle(
                  color: isDark ? Colors.purple.shade300 : Colors.purple.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              
              // Content
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black12 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.purple.shade200.withOpacity(0.3)
                        : Colors.purple.shade100,
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
              
              // Image if available
              if (post.image != null) ...[
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple.shade200),
                    image: DecorationImage(
                      image: NetworkImage(post.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Stats
              Row(
                children: [
                  Icon(
                    post.isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 18,
                    color: post.isLiked
                        ? Colors.red
                        : (isDark ? Colors.purple.shade300 : Colors.purple.shade600),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.likesCount}',
                    style: TextStyle(
                      color: isDark ? Colors.purple.shade300 : Colors.purple.shade600,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.comment_outlined,
                    size: 18,
                    color: isDark ? Colors.purple.shade300 : Colors.purple.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: TextStyle(
                      color: isDark ? Colors.purple.shade300 : Colors.purple.shade600,
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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImage({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Interactive image viewer with zoom and pan
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
            ),
          ),
          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Material(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
