import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/community/group_model.dart';
import '../../../models/community/group_post_model.dart';
import '../../../services/community_service.dart';
import '../../profile/user_profile_screen.dart';
import '../../../utils/helpers.dart';

class GroupPostsTab extends StatefulWidget {
  final Group group;
  final int? currentUserId;

  const GroupPostsTab({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  State<GroupPostsTab> createState() => _GroupPostsTabState();
}

class _GroupPostsTabState extends State<GroupPostsTab> {
  final TextEditingController _postController = TextEditingController();
  final ScrollController _postsScrollController = ScrollController();
  final CommunityService _communityService = CommunityService();
  final ImagePicker _picker = ImagePicker();
  
  List<GroupPost> _posts = [];
  bool _isLoadingPosts = true;
  XFile? _selectedImage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchGroupPosts();
    
    // Auto-refresh posts every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchGroupPosts(silent: true);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _postController.dispose();
    _postsScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchGroupPosts({bool silent = false}) async {
    final groupId = widget.group.id ?? 0;
    if (groupId == 0) {
      if (!silent) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
      return;
    }

    if (!silent) {
      setState(() {
        _isLoadingPosts = true;
      });
    }

    try {
      final posts = await _communityService.getGroupPosts(groupId);
      if (mounted) {
        setState(() {
          _posts = posts.reversed.toList();
          _isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error fetching group posts: $e');
      if (mounted && !silent) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<void> _createPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) {
      return;
    }

    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final content = _postController.text.trim();
      final groupId = widget.group.id ?? 0;
      
      await _communityService.createGroupPost(
        groupId: groupId,
        content: content,
        imageFile: _selectedImage,
      );
      
      _postController.clear();
      setState(() {
        _selectedImage = null;
      });

      await _fetchGroupPosts();

      // Auto-scroll to top to show new post
      if (_postsScrollController.hasClients) {
        _postsScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          const SnackBar(
            content: Text('Post created successfully'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      print('Error creating post: $e');
      setState(() {
        _isLoadingPosts = false;
      });
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePost(GroupPost post) async {
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
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _communityService.deleteGroupPost(post.id);
      await _fetchGroupPosts();
      
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          const SnackBar(
            content: Text('Post deleted successfully'),
            backgroundColor: Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      print('Error deleting post: $e');
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text('Failed to delete post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePin(GroupPost post) async {
    try {
      final isPinned = await _communityService.togglePinGroupPost(post.id);
      await _fetchGroupPosts();
      
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text(isPinned ? 'Post pinned' : 'Post unpinned'),
            backgroundColor: const Color(0xFF7C3AED),
          ),
        );
      }
    } catch (e) {
      print('Error toggling pin: $e');
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text('Failed to ${post.isPinned ? "unpin" : "pin"} post: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sort posts: pinned first, then by newest
    final sortedPosts = List<GroupPost>.from(_posts);
    sortedPosts.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return Column(
      children: [
        Expanded(
          child: _isLoadingPosts
              ? const Center(child: CircularProgressIndicator())
              : sortedPosts.isEmpty
                  ? Center(
                      child: Text(
                        'No posts yet. Be the first to post!',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchGroupPosts,
                      child: ListView.builder(
                        key: const PageStorageKey<String>('group_posts'),
                        controller: _postsScrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedPosts.length,
                        itemBuilder: (context, index) {
                          return _buildPostCard(sortedPosts[index]);
                        },
                      ),
                    ),
        ),
        _buildPostInput(),
      ],
    );
  }

  Widget _buildPostInput() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedImage != null)
              Stack(
                children: [
                  Container(
                    height: 180,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: kIsWeb
                          ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                          : FutureBuilder(
                              future: _selectedImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                }
                                return const Center(child: CircularProgressIndicator());
                              },
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black87,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.image_rounded,
                      color: Color(0xFF7C3AED),
                    ),
                    onPressed: _pickImage,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _postController,
                      decoration: InputDecoration(
                        hintText: 'Share something with the group...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color.fromRGBO(124, 58, 237, 0.9)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _createPost,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(GroupPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfileScreen(userId: post.author),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: post.authorAvatar != null
                        ? NetworkImage(post.authorAvatar!)
                        : null,
                    child: post.authorAvatar == null
                        ? Text(
                            post.authorUsername[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(userId: post.author),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              post.authorUsername,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            if (post.isPinned) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7C3AED).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.push_pin,
                                      size: 12,
                                      color: Color(0xFF7C3AED),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Pinned',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF7C3AED),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(post.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // More options menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      _deletePost(post);
                    } else if (value == 'pin') {
                      _togglePin(post);
                    }
                  },
                  itemBuilder: (context) {
                    List<PopupMenuEntry<String>> items = [];
                    
                    // Show pin option only for group creator
                    if (widget.currentUserId == widget.group.creatorId) {
                      items.add(
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(post.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                              const SizedBox(width: 12),
                              Text(post.isPinned ? 'Unpin Post' : 'Pin Post'),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    // Show delete option for post author or group creator
                    if (widget.currentUserId == post.author || widget.currentUserId == widget.group.creatorId) {
                      items.add(
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Delete Post', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      );
                    }
                    
                    return items;
                  },
                ),
              ],
            ),
          ),
          // Content
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                post.content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          // Image
          if (post.image != null)
            GestureDetector(
              onTap: () {
                // Show full screen image
                showDialog(
                  context: context,
                  barrierColor: Colors.black87,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: EdgeInsets.zero,
                    child: Stack(
                      children: [
                        Center(
                          child: InteractiveViewer(
                            child: Image.network(
                              post.image!,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 16,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                child: Image.network(
                  post.image!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          if (post.content.isNotEmpty && post.image == null)
            const SizedBox(height: 8),
        ],
      ),
    );
  }
}
