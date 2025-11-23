import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/community/post_model.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../profile/user_profile_screen.dart';
import 'edit_post_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isPostingComment = false;
  String _commentFilter = 'recent'; // 'recent' or 'trending'

  @override
  void initState() {
    super.initState();
    _loadPostDetail();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPostDetail() async {
    final provider = context.read<CommunityProvider>();
    await provider.getPostDetail(widget.postId, force: true);
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;
    setState(() => _isPostingComment = true);
    final provider = context.read<CommunityProvider>();
    await provider.addComment(widget.postId, _commentController.text.trim());
    await provider.getPostDetail(widget.postId, force: true); // Refresh post detail
    if (mounted) {
      _commentController.clear();
      setState(() => _isPostingComment = false);
    }
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Post'),
            onTap: () async {
              Navigator.pop(context);
              final edited = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPostScreen(post: post),
                ),
              );
              if (edited == true) {
                await context.read<CommunityProvider>().fetchPosts();
                await context.read<CommunityProvider>().getPostDetail(post.id, force: true);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Post'),
                  content: const Text('Are you sure you want to delete this post?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final success = await context.read<CommunityProvider>().deletePost(post.id);
                if (success && mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showCommentOptions(BuildContext context, Comment comment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Comment', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context); // Close options menu
              
              if (!context.mounted) return;
              
              // Show confirmation dialog with state management
              final success = await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder: (BuildContext dialogContext) => StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    bool isDeleting = false;
                    
                    void handleDelete() async {
                      try {
                        setState(() => isDeleting = true);
                        
                        print('Starting comment delete operation...');
                        final provider = Provider.of<CommunityProvider>(context, listen: false);
                        final success = await provider.deleteComment(widget.postId, comment.id);
                        
                        if (success) {
                          print('Comment deleted successfully');
                          await provider.getPostDetail(widget.postId, force: true);
                          
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, true);
                        } else {
                          print('Failed to delete comment');
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(content: Text('Failed to delete comment')),
                          );
                          Navigator.pop(dialogContext, false);
                        }
                      } catch (e) {
                        print('Error deleting comment: $e');
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('Error deleting comment: $e')),
                          );
                          Navigator.pop(dialogContext, false);
                        }
                      }
                    }

                    return AlertDialog(
                      title: const Text('Delete Comment'),
                      content: const Text('Are you sure you want to delete this comment?'),
                      actions: [
                        TextButton(
                          onPressed: isDeleting ? null : () {
                            print('Delete dialog: Cancel clicked');
                            Navigator.pop(dialogContext, false);
                          },
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: isDeleting ? null : handleDelete,
                          child: isDeleting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Delete'),
                        ),
                      ],
                    );
                  },
                ),
              );
              
              if (success == true && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Comment deleted successfully')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();
    final post = provider.postDetail(widget.postId) ??
        provider.posts.firstWhere((p) => p.id == widget.postId, orElse: () => Post.empty());
    
    print('Building post detail: ${post.id}, isAuthor: ${post.isCurrentUserAuthor}');

    final topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CustomAppBar(
        title: 'Post',
        showBackButton: true,
        actions: [
          if (post.isCurrentUserAuthor)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showPostOptions(post),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: topPadding + 16, left: 16, right: 16, bottom: 16),
              children: [
                _buildPostHeader(context, post),
                const SizedBox(height: 12),
                Text(post.content, style: const TextStyle(fontSize: 16)),
                if (post.image != null) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PostImageFullScreen(
                            imageUrl: post.image!,
                            authorName: post.authorUsername,
                            authorAvatar: post.authorAvatar,
                            content: post.content,
                            timestamp: post.createdAt,
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        post.image!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildPostActions(context, post),
                const Divider(height: 32),
                _buildCommentsHeader(context, post),
                const SizedBox(height: 16),
                ..._getSortedComments(post.comments ?? []).map((c) => _buildCommentItem(context, c)),
              ],
            ),
          ),
          _buildCommentInput(context),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context, Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.purple.shade300 : Colors.purple.shade200,
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: isDark ? Colors.purple.shade900 : Colors.purple.shade50,
              backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
              child: post.authorAvatar == null 
                ? Icon(Icons.person, color: isDark ? Colors.purple.shade200 : Colors.purple.shade400) 
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeago.format(post.createdAt), 
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.purple.shade300 : Colors.purple.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostActions(BuildContext context, Post post) {
    final provider = context.read<CommunityProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => provider.toggleLike(post.id),
          icon: Icon(
            post.isLiked ? Icons.favorite : Icons.favorite_border,
            color: post.isLiked ? Colors.red : null,
          ),
          label: Text('${post.likesCount}'),
        ),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.comment_outlined),
          label: Text('${post.commentsCount}'),
        ),
        TextButton.icon(onPressed: () {}, icon: const Icon(Icons.share_outlined), label: const Text('Share')),
      ],
    );
  }

  Widget _buildCommentItem(BuildContext context, Comment comment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    print('Building comment item: ${comment.id}, isAuthor: ${comment.isCurrentUserAuthor}');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.purple.shade900.withOpacity(0.2) 
          : Colors.purple.shade50.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.purple.shade300 : Colors.purple.shade200).withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? Colors.purple.shade300 : Colors.purple.shade200,
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: isDark ? Colors.purple.shade800 : Colors.purple.shade100,
              backgroundImage: comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
              child: comment.authorAvatar == null 
                ? Icon(
                    Icons.person, 
                    size: 20,
                    color: isDark ? Colors.purple.shade200 : Colors.purple.shade400,
                  ) 
                : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorUsername, 
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  comment.content,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        await context.read<CommunityProvider>().toggleCommentLike(widget.postId, comment.id);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              comment.isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: comment.isLiked ? Colors.red : (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likesCount}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (comment.isCurrentUserAuthor)
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.purple.shade300 : Colors.purple.shade600,
              ),
              onPressed: () => _showCommentOptions(context, comment),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsHeader(BuildContext context, Post post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Comments (${post.commentsCount})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDark 
              ? Colors.purple.shade900.withOpacity(0.2) 
              : Colors.purple.shade50.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isDark ? Colors.purple.shade300 : Colors.purple.shade200).withOpacity(0.3),
            ),
          ),
          child: DropdownButton<String>(
            value: _commentFilter,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.purple.shade200 : Colors.purple.shade600,
            ),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.purple.shade200 : Colors.purple.shade700,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
            items: const [
              DropdownMenuItem(value: 'recent', child: Text('Recent')),
              DropdownMenuItem(value: 'trending', child: Text('Trending')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _commentFilter = value);
              }
            },
          ),
        ),
      ],
    );
  }

  List<Comment> _getSortedComments(List<Comment> comments) {
    final sortedComments = List<Comment>.from(comments);
    if (_commentFilter == 'recent') {
      sortedComments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      // Trending: sort by likes count, then by creation date
      sortedComments.sort((a, b) {
        final likesCompare = b.likesCount.compareTo(a.likesCount);
        if (likesCompare != 0) return likesCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
    }
    return sortedComments;
  }

  Widget _buildCommentInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.purple.shade300 : Colors.purple.shade200).withOpacity(0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark 
                  ? Colors.purple.shade900.withOpacity(0.2) 
                  : Colors.purple.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: (isDark ? Colors.purple.shade300 : Colors.purple.shade200).withOpacity(0.3),
                ),
              ),
              child: TextField(
                controller: _commentController,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _postComment(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.purple.shade600,
                ],
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: _isPostingComment ? null : _postComment,
            ),
          ),
        ],
      ),
    );
  }
}

class PostImageFullScreen extends StatelessWidget {
  final String imageUrl;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final DateTime timestamp;

  const PostImageFullScreen({
    super.key,
    required this.imageUrl,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image viewer
          Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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
          // Top overlay with post info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 24,
              ),
              child: Row(
                children: [
                  // Back button
                  Material(
                    color: Colors.transparent,
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
                  const SizedBox(width: 12),
                  // Author info
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: authorAvatar != null ? NetworkImage(authorAvatar!) : null,
                    child: authorAvatar == null
                        ? const Icon(Icons.person, color: Colors.grey)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          timeago.format(timestamp),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom overlay with caption
          if (content.isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.0),
                    ],
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                  top: 24,
                ),
                child: Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
