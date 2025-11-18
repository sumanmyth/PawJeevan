import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../widgets/user_list_tile.dart';
import '../../screens/profile/user_profile_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final _userService = UserService();
  final _searchController = TextEditingController();
  List<User>? _searchResults;
  bool _isLoading = false;
  String? _error;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _userService.searchUsers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search users by name or username',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
          ),
          onChanged: (value) => _performSearch(value),
          autofocus: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _searchResults == null
                  ? const Center(
                      child: Text('Enter a name or username to search'),
                    )
                  : _searchResults!.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          itemCount: _searchResults!.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults![index];
                            return UserListTile(
                              user: user,
                              onTap: () {
                                // Navigate to user profile
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => UserProfileScreen(userId: user.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
    );
  }
}