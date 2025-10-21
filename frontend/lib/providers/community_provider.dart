import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/community_service.dart';
import '../services/auth_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _service = CommunityService();

  List<Post> _posts = [];
  final Map<int, Post> _postDetails = {};
  final Map<int, User> _users = {};
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Post? postDetail(int id) => _postDetails[id];

  User? user(int id) => _users[id];

  Future<void> fetchPosts() async {
    if (_isLoading) return; // Prevent multiple simultaneous fetches
    
    final previousPosts = List<Post>.from(_posts); // Keep a copy of current posts
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('Fetching posts...');
      final newPosts = await _service.getPosts();
      print('Fetched ${newPosts.length} posts');
      if (newPosts.isEmpty && _posts.isNotEmpty) {
        print('Warning: Received empty posts list while we had existing posts');
      }
      _posts = newPosts;
      _error = null;
    } catch (e) {
      print('Error fetching posts: $e');
      _error = e.toString();
      // Restore previous posts on error
      _posts = previousPosts;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Post?> getPostDetail(int postId, {bool force = false}) async {
    if (!force && _postDetails.containsKey(postId)) return _postDetails[postId];
    try {
      final post = await _service.getPostDetail(postId);
      _postDetails[postId] = post;
      notifyListeners();
      return post;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  final Map<int, List<Post>> _userPosts = {};
  
  Future<User?> getUser(int userId, {bool force = false}) async {
    if (!force && _users.containsKey(userId)) return _users[userId];
    try {
      final user = await _service.getUser(userId);
      _users[userId] = user;
      notifyListeners();
      return user;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<List<Post>> getUserPosts(int userId, {bool force = false}) async {
    if (!force && _userPosts.containsKey(userId)) return _userPosts[userId]!;
    try {
      final posts = await _service.getUserPosts(userId);
      _userPosts[userId] = posts;
      notifyListeners();
      return posts;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  List<Post> cachedUserPosts(int userId) => _userPosts[userId] ?? [];

  Future<void> followUser(int userId, {bool unfollow = false}) async {
    try {
      if (unfollow) {
        await _service.unfollowUser(userId);
      } else {
        await _service.followUser(userId);
      }
      
      // Clear user cache to force a fresh fetch
      _users.remove(userId);
      
      // Refetch both the target user and current user to update counts
      await getUser(userId, force: true);
      final authService = AuthService();
      final currentUser = await authService.getProfile();
      // Update current user in cache
      _users[currentUser.id] = currentUser;
      
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Method to refresh current user's profile (for updating following count)
  Future<User?> refreshCurrentUser() async {
    try {
      final authService = AuthService();
      final currentUser = await authService.getProfile();
      // Update current user in cache
      _users[currentUser.id] = currentUser;
      notifyListeners();
      return currentUser;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<bool> createPost(String content, {String? imagePath}) async {
    try {
      final newPost = await _service.createPost(content, imagePath: imagePath);
      
      // Update main posts list
      _posts.insert(0, newPost);
      
      // Update user's posts list if we have it cached
      if (_userPosts.containsKey(newPost.author)) {
        _userPosts[newPost.author] = [newPost, ...(_userPosts[newPost.author] ?? [])];
      }
      
      // Get updated user info to refresh post count
      await getUser(newPost.author, force: true);
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePost(int postId, String content, {String? imagePath}) async {
    try {
      final updatedPost = await _service.updatePost(postId, content, imagePath: imagePath);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        _posts[index] = updatedPost;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePost(int postId) async {
    print('Provider: Starting delete operation for post $postId');
    _error = null;  // Reset any previous error
    try {
      print('Provider: Calling community service deletePost');
      try {
        await _service.deletePost(postId);
        print('Provider: API call completed successfully');
      } catch (serviceError) {
        print('Provider: Service error during delete: $serviceError');
        _error = serviceError.toString();
        notifyListeners();
        return false;
      }
      
      print('Provider: Updating local state');
      try {
        final beforeCount = _posts.length;
        _posts.removeWhere((p) => p.id == postId);
        final afterCount = _posts.length;
        print('Provider: Posts count before: $beforeCount, after: $afterCount');
        
        if (beforeCount == afterCount) {
          print('Provider: Warning - post was not found in list');
        }
        
        if (_postDetails.containsKey(postId)) {
          _postDetails.remove(postId);
          print('Provider: Removed from details cache');
        }
        
        print('Provider: Notifying listeners of state change');
        notifyListeners();
        return true;
      } catch (stateError) {
        print('Provider: Error updating state: $stateError');
        _error = 'Post deleted but UI update failed: $stateError';
        notifyListeners();
        return true; // Still return true as delete succeeded
      }
    } catch (e) {
      print('Provider: Unexpected error: $e');
      _error = 'Unexpected error: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleLike(int postId) async {
    // Update in main posts list
    final index = _posts.indexWhere((p) => p.id == postId);
    Post? post;
    
    if (index != -1) {
      post = _posts[index];
    } else if (_postDetails.containsKey(postId)) {
      post = _postDetails[postId];
    }
    
    if (post == null) return;
    
    final liked = post.isLiked;
    final updatedPost = post.copyWith(
      isLiked: !liked,
      likesCount: liked ? post.likesCount - 1 : post.likesCount + 1,
      comments: post.comments, // Preserve existing comments
    );

    // Update both main list and detail cache
    if (index != -1) {
      _posts[index] = updatedPost;
    }
    if (_postDetails.containsKey(postId)) {
      // Preserve all existing post details while updating like status
      final existingPostDetail = _postDetails[postId]!;
      _postDetails[postId] = existingPostDetail.copyWith(
        isLiked: !liked,
        likesCount: liked ? existingPostDetail.likesCount - 1 : existingPostDetail.likesCount + 1,
      );
    }
    notifyListeners();

    try {
      await _service.likePost(postId);
    } catch (e) {
      // Revert on error
      if (index != -1) {
        _posts[index] = post;
      }
      if (_postDetails.containsKey(postId)) {
        _postDetails[postId] = post;
      }
      notifyListeners();
    }
  }

  Future<Comment?> addComment(int postId, String content) async {
    try {
      final newComment = await _service.addComment(postId, content);
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) {
        final post = _posts[index];
        _posts[index] = post.copyWith(
          comments: [...(post.comments ?? []), newComment],
          commentsCount: post.commentsCount + 1,
        );
        notifyListeners();
      }
      return newComment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Cache for followers and following lists
  final Map<int, List<User>> _followers = {};
  final Map<int, List<User>> _following = {};

  Future<List<User>> getFollowers(int userId, {bool force = false}) async {
    if (!force && _followers.containsKey(userId)) return _followers[userId]!;
    
    try {
      final followers = await _service.getFollowers(userId);
      _followers[userId] = followers;
      notifyListeners();
      return followers;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<User>> getFollowing(int userId, {bool force = false}) async {
    if (!force && _following.containsKey(userId)) return _following[userId]!;
    
    try {
      final following = await _service.getFollowing(userId);
      _following[userId] = following;
      notifyListeners();
      return following;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<bool> deleteComment(int postId, int commentId) async {
    print('Attempting to delete comment $commentId from post $postId');
    try {
      await _service.deleteComment(postId, commentId);
      
      // Update post in posts list if it exists
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = post.copyWith(
          comments: post.comments?.where((c) => c.id != commentId).toList(),
          commentsCount: post.commentsCount - 1,
        );
      }

      // Update post in post details if it exists
      if (_postDetails.containsKey(postId)) {
        final post = _postDetails[postId]!;
        _postDetails[postId] = post.copyWith(
          comments: post.comments?.where((c) => c.id != commentId).toList(),
          commentsCount: post.commentsCount - 1,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
