import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/post_model.dart';
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

    return Scaffold(
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
              padding: const EdgeInsets.all(16),
              children: [
                _buildPostHeader(context, post),
                const SizedBox(height: 12),
                Text(post.content, style: const TextStyle(fontSize: 16)),
                if (post.image != null) ...[
                  const SizedBox(height: 12),
                  Image.network(post.image!),
                ],
                const SizedBox(height: 12),
                _buildPostActions(context, post),
                const Divider(height: 32),
                Text('Comments (${post.commentsCount})', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                ...post.comments?.map((c) => _buildCommentItem(context, c)) ?? [],
              ],
            ),
          ),
          _buildCommentInput(context),
        ],
      ),
    );
  }

  Widget _buildPostHeader(BuildContext context, Post post) {
    return GestureDetector(
      onTap: post.isCurrentUserAuthor 
        ? null 
        : () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => UserProfileScreen(userId: post.author)),
          ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: post.authorAvatar != null ? NetworkImage(post.authorAvatar!) : null,
            child: post.authorAvatar == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(timeago.format(post.createdAt), style: Theme.of(context).textTheme.bodySmall),
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
    print('Building comment item: ${comment.id}, isAuthor: ${comment.isCurrentUserAuthor}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
            child: comment.authorAvatar == null ? const Icon(Icons.person) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.authorUsername, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(comment.content),
              ],
            ),
          ),
          if (comment.isCurrentUserAuthor)
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showCommentOptions(context, comment),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a comment...',
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _postComment(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isPostingComment ? null : _postComment,
          ),
        ],
      ),
    );
  }
}
