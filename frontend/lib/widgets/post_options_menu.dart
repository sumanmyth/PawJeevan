import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/community/post_model.dart';
import '../providers/community_provider.dart';
import '../screens/community/posts/edit_post_screen.dart';
import '../utils/helpers.dart';

class PostOptionsMenu extends StatefulWidget {
  final Post post;
  final VoidCallback? onDeleted;

  const PostOptionsMenu({
    super.key,
    required this.post,
    this.onDeleted,
  });

  @override
  State<PostOptionsMenu> createState() => _PostOptionsMenuState();
}

class _PostOptionsMenuState extends State<PostOptionsMenu> {
  final bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    // Only show edit/delete options if the current user is the post author
    if (!widget.post.isCurrentUserAuthor) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report),
            title: const Text('Report Post'),
            onTap: () {
              Navigator.pop(context);
              Helpers.showInstantSnackBar(
                context,
                const SnackBar(content: Text('Post reported')),
              );
            },
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit Post'),
          onTap: () => _handleEdit(context),
        ),
        if (_isDeleting)
          const ListTile(
            leading: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Deleting...'),
          )
        else
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
            onTap: () => _handleDelete(context),
          ),
      ],
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    Navigator.pop(context); // Close bottom sheet
    
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EditPostScreen(post: widget.post)),
    );

    if (edited == true && context.mounted) {
      final provider = context.read<CommunityProvider>();
      await provider.fetchPosts();
      await provider.getPostDetail(widget.post.id, force: true);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    print('_handleDelete called for post ${widget.post.id}');
    
    // Close bottom sheet first
    Navigator.pop(context);
    
    if (!context.mounted) return;

    // Show confirmation dialog with built-in state management
    print('Showing delete confirmation dialog');
    final bool? success = await Helpers.showBlurredDialog<bool>(
      context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          bool isDeleting = false;

          void handleDelete() async {
            try {
              setDialogState(() => isDeleting = true);

              print('Starting delete operation via provider...');
              final provider = Provider.of<CommunityProvider>(context, listen: false);
              final success = await provider.deletePost(widget.post.id);

              print('Provider delete returned: $success');

              if (!dialogContext.mounted) return;

              if (success) {
                // Close dialog and indicate success
                Navigator.pop(dialogContext, true);
              } else {
                Helpers.showInstantSnackBar(
                  dialogContext,
                  const SnackBar(content: Text('Failed to delete post')),
                );
                Navigator.pop(dialogContext, false);
              }
            } catch (e) {
              print('Error during delete: $e');
              if (dialogContext.mounted) {
                Helpers.showInstantSnackBar(
                  dialogContext,
                  SnackBar(content: Text('Failed to delete post: $e')),
                );
                Navigator.pop(dialogContext, false);
              }
            }
          }

          return AlertDialog(
            title: const Text('Delete Post'),
            content: const Text('Are you sure you want to delete this post?'),
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

    // If deletion was successful
    if (success == true && context.mounted) {
      print('Delete successful, showing confirmation');
      Helpers.showInstantSnackBar(
        context,
        const SnackBar(content: Text('Post deleted successfully')),
      );
      
      // Call the callback to notify parent
      print('Calling onDeleted callback');
      widget.onDeleted?.call();
    }
  }
}