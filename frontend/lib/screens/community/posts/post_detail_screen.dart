import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../utils/helpers.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/community/post_model.dart';
import '../../../providers/community_provider.dart';
import '../../../widgets/custom_app_bar.dart';
import '../../profile/user_profile_screen.dart';
import '../../pet/widgets/full_screen_image.dart';
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
    // Capture the state context to avoid using a deactivated bottom-sheet context
    final parentContext = context;

    showModalBottomSheet(
      context: parentContext,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Post'),
            onTap: () async {
              // Close the bottom sheet using its own context, but perform navigation
              // and provider interaction using the parent state context to avoid
              // looking up ancestors on a deactivated context.
              Navigator.pop(context);
              final edited = await Navigator.push<bool>(
                parentContext,
                MaterialPageRoute(
                  builder: (_) => EditPostScreen(post: post),
                ),
              );
              if (edited == true && mounted) {
                final provider = context.read<CommunityProvider>();
                await provider.fetchPosts();
                await provider.getPostDetail(post.id, force: true);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              final confirm = await Helpers.showBlurredConfirmationDialog(
                parentContext,
                title: 'Delete Post',
                content: 'Are you sure you want to delete this post?',
                cancelLabel: 'Cancel',
                confirmLabel: 'Delete',
                confirmDestructive: true,
              );
              if (confirm == true) {
                if (!mounted) return;
                final provider = context.read<CommunityProvider>();
                print('PostDetail: attempting to delete post ${post.id}');
                final success = await provider.deletePost(post.id);
                print('PostDetail: provider.deletePost returned: $success, error: ${provider.error}');
                if (success && mounted) {
                  // Ensure the main posts list is refreshed so the post disappears
                  // from any feed or list screens before popping the detail view.
                  await provider.fetchPosts();
                  Navigator.pop(context);
                } else {
                  // Show user-facing feedback when delete fails
                  if (mounted) {
                    Helpers.showInstantSnackBar(
                      context,
                      SnackBar(content: Text('Failed to delete post: ${provider.error ?? 'Unknown error'}')),
                    );
                  }
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
              final success = await Helpers.showBlurredDialog<bool>(
                context,
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
                          Helpers.showInstantSnackBar(
                            dialogContext,
                            const SnackBar(content: Text('Failed to delete comment')),
                          );
                          Navigator.pop(dialogContext, false);
                        }
                      } catch (e) {
                        print('Error deleting comment: $e');
                        if (dialogContext.mounted) {
                          Helpers.showInstantSnackBar(
                            dialogContext,
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
                Helpers.showInstantSnackBar(
                  context,
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
                          builder: (context) => FullScreenImage(
                            imageUrl: post.image!,
                            title: post.authorUsername,
                            heroTag: 'post_image_${post.id}',
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Hero(
                        tag: 'post_image_${post.id}',
                        child: Image.network(
                          post.image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
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
                color: const Color(0xFF7C3AED),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFF7C3AED),
              backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
              child: post.authorAvatar == null 
                ? const Icon(Icons.person, color: Color(0xFF7C3AED)) 
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
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7C3AED),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const primary = Color(0xFF7C3AED);
    print('Building comment item: ${comment.id}, isAuthor: ${comment.isCurrentUserAuthor}');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: comment.isCurrentUserAuthor
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfileScreen(userId: comment.author),
                      ),
                    ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withOpacity(0.9),
                  width: 1.2,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: primary.withOpacity(0.12),
                backgroundImage: comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
                child: comment.authorAvatar == null 
                  ? const Icon(
                      Icons.person, 
                      size: 20,
                      color: Color(0xFF7C3AED),
                    ) 
                  : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: comment.isCurrentUserAuthor
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserProfileScreen(userId: comment.author),
                            ),
                          ),
                  child: Text(
                    comment.authorUsername,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: primary,
                    ),
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
              icon: const Icon(
                Icons.more_vert,
                color: primary,
              ),
              onPressed: () => _showCommentOptions(context, comment),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsHeader(BuildContext context, Post post) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF7C3AED).withOpacity(0.12),
            ),
          ),
          child: DropdownButton<String>(
            value: _commentFilter,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF7C3AED),
            ),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C3AED),
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
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.12),
                ),
              ),
              child: TextField(
                controller: _commentController,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color ?? Colors.black87,
                ),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => _postComment(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF7C3AED),
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


