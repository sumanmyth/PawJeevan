import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/community/group_model.dart';
import '../../../services/api_service.dart';
import '../../../utils/helpers.dart';
import '../../pet/widgets/full_screen_image.dart';
import 'group_chat_tab.dart';
import 'group_posts_tab.dart';
import 'edit_group_screen.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Group group;
  final VoidCallback? onGroupChanged;

  const GroupDetailsScreen({super.key, required this.group, this.onGroupChanged});

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _group = widget.group;
    _tabController = TabController(length: 2, vsync: this);
    _loadUserId();
  }

  late Group _group;


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('user_id');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _group.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
            ),
            Text(
              '2 members',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showGroupInfo,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[200],
              borderRadius: BorderRadius.circular(28),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color.fromRGBO(124, 58, 237, 0.9)],
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
              tabs: const [
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 18),
                      SizedBox(width: 8),
                      Text('Chat'),
                    ],
                  ),
                ),
                Tab(
                  icon: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Posts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          GroupChatTab(
            group: _group,
            currentUserId: _currentUserId,
          ),
          GroupPostsTab(
            group: _group,
            currentUserId: _currentUserId,
          ),
        ],
      ),
    );
  }

  void _showGroupInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Group Info',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image
                      if (_group.coverImage != null && _group.coverImage!.isNotEmpty)
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FullScreenImage(
                                      imageUrl: _group.coverImage!,
                                      heroTag: 'group_cover_${_group.slug}',
                                    ),
                                  ),
                                );
                              },
                              child: Hero(
                                tag: 'group_cover_${_group.slug}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    _group.coverImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                        )
                      else
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color.fromRGBO(124, 58, 237, 0.9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.groups,
                              size: 80,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Group Name
                      Text(
                        _group.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Info Cards
                      _buildInfoCard(
                        icon: Icons.groups_outlined,
                        label: 'Members',
                        value: '${_group.membersCount ?? 0}',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildInfoCard(
                        icon: _group.isPrivate ? Icons.lock_outline : Icons.public_outlined,
                        label: 'Privacy',
                        value: _group.isPrivate ? 'Private' : 'Public',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildInfoCard(
                        icon: Icons.category_outlined,
                        label: 'Type',
                        value: _group.groupTypeDisplay ?? _formatGroupType(_group.groupType),
                        isDark: isDark,
                      ),
                      
                      if (_group.isPrivate && _group.joinKey != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.key_outlined,
                          label: 'Join Key',
                          value: _group.joinKey!,
                          isDark: isDark,
                          copyable: true,
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Description Section
                      Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                          ),
                        ),
                        child: Text(
                          _group.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: isDark ? Colors.grey[300] : Colors.grey[800],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Action Buttons
                      if (_group.creatorId == _currentUserId) ...[
                        // Admin options
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Manage Group',
                          onTap: () async {
                            Navigator.pop(context); // Close group info
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditGroupScreen(group: _group),
                              ),
                            );
                            // If we got an updated Group back, refresh local state and reopen info
                            if (result is Group && mounted) {
                              setState(() {
                                _group = result;
                              });
                              // Re-open the updated info sheet
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) _showGroupInfo();
                              });
                              return;
                            }
                            // fallback: if caller returned true, navigate back to groups list
                            if (result == true && mounted) {
                              Navigator.pop(context);
                            }
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          icon: Icons.delete_outline,
                          label: 'Delete Group',
                          onTap: () {
                            _showDeleteConfirmation();
                          },
                          isDark: isDark,
                          isDestructive: true,
                        ),
                      ] else ...[
                        // Member options
                        _buildActionButton(
                          icon: Icons.exit_to_app_outlined,
                          label: 'Leave Group',
                          onTap: () {
                            _showLeaveConfirmation();
                          },
                          isDark: isDark,
                          isDestructive: true,
                        ),
                      ],
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    bool copyable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF7C3AED),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              icon: Icon(
                Icons.copy_outlined,
                size: 20,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: value));
                  Helpers.showInstantSnackBar(
                    context,
                    const SnackBar(
                      content: Text('Copied to clipboard'),
                      duration: Duration(milliseconds: 900),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (_) {
                  Helpers.showInstantSnackBar(
                    context,
                    const SnackBar(
                      content: Text('Failed to copy'),
                      duration: Duration(milliseconds: 900),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDestructive
                ? Colors.red.withOpacity(0.3)
                : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : (isDark ? Colors.grey[300] : Colors.grey[700]),
              size: 22,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black),
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDestructive ? Colors.red : (isDark ? Colors.grey[600] : Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatGroupType(String type) {
    return type.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }
  
  void _showDeleteConfirmation() {
    // Close the group info sheet first
    Navigator.pop(context);
    
    // Then show confirmation dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Group'),
          content: Text(
            'Are you sure you want to delete "${_group.name}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteGroup();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  
  void _showLeaveConfirmation() {
    // Close the group info sheet first
    Navigator.pop(context);
    
    // Then show confirmation dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave Group'),
            content: Text(
            'Are you sure you want to leave "${_group.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _leaveGroup();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _deleteGroup() async {
    try {
      await ApiService.deleteGroup(_group.slug);
      
      if (mounted) {
        widget.onGroupChanged?.call(); // Trigger refresh
        Navigator.pop(context, true); // Go back to groups list with result
        Helpers.showInstantSnackBar(
          context,
          const SnackBar(
            content: Text('Group deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text('Failed to delete group: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _leaveGroup() async {
    try {
      await ApiService.leaveGroup(_group.slug);
      
      if (mounted) {
        widget.onGroupChanged?.call(); // Trigger refresh
        Navigator.pop(context, true); // Go back to groups list with result
        Helpers.showInstantSnackBar(
          context,
          const SnackBar(
            content: Text('Left group successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Helpers.showInstantSnackBar(
          context,
          SnackBar(
            content: Text('Failed to leave group: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
