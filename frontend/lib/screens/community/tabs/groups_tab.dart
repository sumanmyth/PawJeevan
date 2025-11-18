import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../services/api_service.dart';
import '../../../models/group_model.dart';
import '../groups/group_chat_screen.dart';
import '../groups/edit_group_screen.dart';

class GroupsTab extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallbackRegistered;
  
  const GroupsTab({super.key, this.onRefreshCallbackRegistered});

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> with SingleTickerProviderStateMixin {
  late Future<List<Group>> _groupsFuture;
  int? _currentUserId;
  late TabController _tabController;
  int _currentTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searchExpanded = false;
  bool _showTabs = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index;
          _groupsFuture = _fetchGroupsWithDebug();
        });
      }
    });
    _loadCurrentUser();
    _groupsFuture = _fetchGroupsWithDebug();
    
    // Register the refresh callback with parent
    widget.onRefreshCallbackRegistered?.call(refreshGroups);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final direction = _scrollController.position.userScrollDirection;
      
      // Hide tabs when scrolling down, show when scrolling up
      if (direction == ScrollDirection.reverse && _showTabs) {
        setState(() {
          _showTabs = false;
        });
      } else if (direction == ScrollDirection.forward && !_showTabs) {
        setState(() {
          _showTabs = true;
        });
      }
    }
  }

  // Public method to refresh groups from external calls
  void refreshGroups() {
    setState(() {
      _groupsFuture = _fetchGroupsWithDebug();
    });
  }

  // Manual refresh method for pull-to-refresh
  Future<void> _refreshGroups() async {
    setState(() {
      _groupsFuture = _fetchGroupsWithDebug();
    });
    await _groupsFuture;
  }

  Future<void> _loadCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    setState(() {
      _currentUserId = userId;
    });
  }

  Future<List<Group>> _fetchGroupsWithDebug() async {
    final dio = Dio();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    String endpoint = '${ApiConstants.baseUrl}${ApiConstants.groups}';
    if (_currentTab == 0) {
      // My Groups (created by me)
      endpoint = '${ApiConstants.baseUrl}${ApiConstants.groups}my/';
    } else if (_currentTab == 1) {
      // Discover Groups (not a member of)
      endpoint = '${ApiConstants.baseUrl}${ApiConstants.groups}discover/';
    } else if (_currentTab == 2) {
      // Joined Groups (member of but not creator)
      endpoint = '${ApiConstants.baseUrl}${ApiConstants.groups}joined/';
    }
    
    final response = await dio.get(
      endpoint,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    final data = response.data;
    if (data is List) {
      return data.map<Group>((g) => Group.fromJson(g)).toList();
    } else if (data is Map && data['results'] is List) {
      return (data['results'] as List).map<Group>((g) => Group.fromJson(g)).toList();
    }
    return [];
  }

  Future<void> _deleteGroup(Group group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.deleteGroup(group.slug);
        setState(() {
          _groupsFuture = _fetchGroupsWithDebug();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting group: $e')),
          );
        }
      }
    }
  }

  void _showGroupOptions(Group group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Group'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGroupScreen(group: group),
                    ),
                  );
                  if (result == true) {
                    // Small delay to ensure backend has processed the update
                    await Future.delayed(const Duration(milliseconds: 300));
                    _refreshGroups();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Group', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteGroup(group);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showJoinedGroupOptions(Group group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.orange),
                title: const Text('Leave Group', style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  _leaveGroup(group);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _joinGroup(Group group) async {
    String? joinKey;
    
    if (group.isPrivate) {
      // Show dialog to enter join key for private groups
      joinKey = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Join Private Group'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Enter Join Key',
                hintText: 'Join key required for private group',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Join'),
              ),
            ],
          );
        },
      );
      
      if (joinKey == null || joinKey.isEmpty) {
        return; // User cancelled or didn't enter a key
      }
    }

    try {
      await ApiService.joinGroup(group.slug, joinKey: joinKey);
      setState(() {
        _groupsFuture = _fetchGroupsWithDebug();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined the group!')),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        String errorMessage = 'Unable to join group';
        
        // Check if it's a 400 error with invalid join key
        if (e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData.containsKey('error')) {
            final error = errorData['error'].toString();
            if (error.toLowerCase().contains('join key') || 
                error.toLowerCase().contains('invalid')) {
              errorMessage = 'Incorrect join key';
            } else {
              errorMessage = error;
            }
          } else {
            errorMessage = 'Incorrect join key';
          }
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'You do not have permission to join this group';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Group not found';
        } else if (e.type == DioExceptionType.connectionTimeout || 
                   e.type == DioExceptionType.receiveTimeout ||
                   e.type == DioExceptionType.connectionError) {
          errorMessage = 'Network error. Please check your connection.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to join group. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveGroup(Group group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: Text('Are you sure you want to leave "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.leaveGroup(group.slug);
        setState(() {
          _groupsFuture = _fetchGroupsWithDebug();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully left the group')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error leaving group: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _showTabs ? null : 0,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _showTabs ? 1.0 : 0.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Colors.white,
                        unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
                        indicator: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'My Groups'),
                          Tab(text: 'Discover'),
                          Tab(text: 'Joined'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: _searchExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    firstChild: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          setState(() {
                            _searchExpanded = true;
                          });
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: const Icon(Icons.search, color: Colors.grey),
                        ),
                      ),
                    ),
                    secondChild: SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Search groups...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                              IconButton(
                                icon: const Icon(Icons.arrow_back, size: 20),
                                tooltip: 'Close search',
                                onPressed: () {
                                  setState(() {
                                    _searchExpanded = false;
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ],
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Group>>(
            future: _groupsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final allGroups = snapshot.data ?? [];
              
              // Filter groups based on search query
              final groups = _searchQuery.isEmpty
                  ? allGroups
                  : allGroups.where((group) {
                      return group.name.toLowerCase().contains(_searchQuery);
                    }).toList();
              
              if (groups.isEmpty) {
                // Show different empty state messages based on current tab
                if (_searchQuery.isNotEmpty) {
                  // Search returned no results
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No groups found matching "$_searchQuery"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  );
                } else if (_currentTab == 2) {
                  // Joined tab
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'You are not a member of any groups yet.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Switch to Discover tab
                            _tabController.animateTo(1);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple[50],
                            foregroundColor: Colors.purple,
                            elevation: 0,
                          ),
                          child: const Text('Discover Groups'),
                        ),
                      ],
                    ),
                  );
                } else {
                  return const Center(
                    child: Text('No groups found.'),
                  );
                }
              }
              return RefreshIndicator(
                onRefresh: _refreshGroups,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isCreator = _currentUserId != null && group.creatorId == _currentUserId;
                    final isMember = group.isMember ?? false;
                    
                    return ListTile(
                      onTap: () {
                        // Navigate to group chat if user is member or creator
                        if (isMember || isCreator) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupChatScreen(group: group),
                            ),
                          );
                        }
                      },
                      onLongPress: isCreator 
                          ? () => _showGroupOptions(group) 
                          : (isMember && !isCreator) 
                              ? () => _showJoinedGroupOptions(group)
                              : null,
                      leading: group.coverImage != null && group.coverImage!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                group.coverImage!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                              ),
                            )
                          : const Icon(Icons.image, size: 40),
                      title: Text(group.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(group.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${group.membersCount ?? 0} members',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (group.isPrivate) const Icon(Icons.lock),
                          if (isCreator) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Group options',
                              onPressed: () => _showGroupOptions(group),
                            ),
                          ],
                          if (!isMember && !isCreator && _currentTab == 1) ...[
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.group_add, size: 18),
                              label: const Text('Join'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => _joinGroup(group),
                            ),
                          ],
                          if (isMember && !isCreator && _currentTab == 2) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Group options',
                              onPressed: () => _showJoinedGroupOptions(group),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}