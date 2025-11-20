import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/community_provider.dart';
import '../screens/community/posts/post_detail_screen.dart';
import '../screens/profile/user_profile_screen.dart';
import '../models/community/post_model.dart';
import 'post_options_menu.dart';

class PostCard extends StatelessWidget {
  final Post post;
  const PostCard({super.key, required this.post});

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
              _buildHeader(context, isDark),
              const SizedBox(height: 12),
              _buildContent(isDark),
              if (post.image != null) ...[
                const SizedBox(height: 12),
                _buildImage(),
              ],
              const SizedBox(height: 12),
              _buildActions(context, provider, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return GestureDetector(
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
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
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
    );
  }

  Widget _buildImage() {
    return Container(
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
    );
  }

  Widget _buildActions(BuildContext context, CommunityProvider provider, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          isDark: isDark,
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: post.isLiked ? Colors.red : null,
          label: '${post.likesCount}',
          onPressed: () => provider.toggleLike(post.id),
        ),
        _buildActionButton(
          isDark: isDark,
          icon: Icons.comment_outlined,
          label: '${post.commentsCount}',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
          ),
        ),
        _buildActionButton(
          isDark: isDark,
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required bool isDark,
    required IconData icon,
    required String label,
    Color? iconColor,
    VoidCallback? onPressed,
  }) {
    final baseColor = isDark ? Colors.purple.shade200 : Colors.purple.shade700;
    
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: baseColor,
        backgroundColor: isDark ? Colors.purple.shade900.withOpacity(0.3) : Colors.purple.shade50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: iconColor ?? baseColor,
        size: 20,
      ),
      label: Text(
        label,
        style: TextStyle(color: baseColor),
      ),
    );
  }
}