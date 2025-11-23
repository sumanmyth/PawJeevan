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
    final theme = Theme.of(context);
    const primary = Color(0xFF7C3AED);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shadowColor: primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: primary.withOpacity(0.08),
        ),
      ),
      color: theme.cardColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildContent(context),
              if (post.image != null && post.image!.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildImage(context),
              ],
              const SizedBox(height: 12),
              _buildActions(context, provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primary = Color(0xFF7C3AED);
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
              border: Border.all(
                color: primary.withOpacity(0.9), 
                width: 1.6,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: primary.withOpacity(0.12),
              backgroundImage: (post.authorAvatar != null && post.authorAvatar!.isNotEmpty) 
                  ? NetworkImage(post.authorAvatar!) 
                  : null,
              child: (post.authorAvatar == null || post.authorAvatar!.isEmpty) 
                  ? Icon(Icons.person, color: primary) 
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.authorUsername,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold) ?? const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  timeago.format(post.createdAt),
                  style: TextStyle(
                    // Fixed: Use Grey for readability
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
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

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF7C3AED);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.06)),
      ),
      child: Text(
        post.content,
        style: theme.textTheme.bodyMedium?.copyWith(height: 1.4) ?? const TextStyle(fontSize: 15, height: 1.4),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final theme = Theme.of(context);
    const primary = Color(0xFF7C3AED);

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withOpacity(0.08)),
        image: DecorationImage(
          image: NetworkImage(post.image!),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
  Widget _buildActions(BuildContext context, CommunityProvider provider) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          primary: primary,
          icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: post.isLiked ? Colors.red : null,
          label: '${post.likesCount}',
          onPressed: () => provider.toggleLike(post.id),
        ),
        _buildActionButton(
          primary: primary,
          icon: Icons.comment_outlined,
          label: '${post.commentsCount}',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailScreen(postId: post.id)),
          ),
        ),
        _buildActionButton(
          primary: primary,
          icon: Icons.share_outlined,
          label: 'Share',
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required Color primary,
    required IconData icon,
    required String label,
    Color? iconColor,
    VoidCallback? onPressed,
  }) {
    final fgColor = primary;
    final bgColor = primary.withOpacity(0.06);

    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: fgColor,
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: iconColor ?? fgColor,
        size: 20,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: fgColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}