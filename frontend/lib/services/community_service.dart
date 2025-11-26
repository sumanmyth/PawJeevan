import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../utils/file_utils.dart';
import '../models/community/post_model.dart';
import '../models/user/user_model.dart';
import '../models/community/group_post_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';

class CommunityService {
  final ApiService _api = ApiService();

  Future<List<Post>> getPosts({String? authorId, Map<String, String>? params}) async {
    print('Fetching posts from API...');
    try {
      final queryParams = params ?? {};
      if (authorId != null) {
        queryParams['author'] = authorId;
      }
      
      final resp = await _api.get(ApiConstants.posts, params: queryParams);
      print('Got API response with status: ${resp.statusCode}');
      print('Response data type: ${resp.data.runtimeType}');
      print('Response data: ${resp.data}');
      
      if (resp.statusCode == 200) {
        final data = resp.data;
        List<Post> posts = [];
        
        if (data is Map && data['results'] is List) {
          posts = (data['results'] as List).map((p) => Post.fromJson(p)).toList();
        } else if (data is List) {
          posts = data.map((p) => Post.fromJson(p)).toList();
        }
        
        print('Successfully parsed ${posts.length} posts');
        return posts;
      }
      
      print('Unexpected response: ${resp.statusCode} - ${resp.data}');
      throw Exception('Failed to fetch posts: ${resp.statusCode}');
    } catch (e) {
      print('Error in getPosts: $e');
      rethrow;
    }
  }

  Future<Post> getPostDetail(int postId) async {
    print('Fetching post detail: $postId');
    try {
      final resp = await _api.get('${ApiConstants.posts}$postId/');
      print('Post detail response: ${resp.data}');
      if (resp.statusCode == 200) {
        return Post.fromJson(resp.data);
      }
      throw Exception('Failed to fetch post detail: ${resp.statusCode}');
    } catch (e) {
      print('Error fetching post detail: $e');
      rethrow;
    }
  }

  Future<void> deletePost(int postId) async {
    print('CommunityService: Starting delete operation for post $postId');
    
    try {
      // First verify the post exists
      print('CommunityService: Verifying post exists...');
      try {
        await getPostDetail(postId);
      } catch (e) {
        print('CommunityService: Failed to verify post: $e');
        throw Exception('Post not found or access denied');
      }

      // Construct the endpoint
      final baseEndpoint = ApiConstants.posts.endsWith('/') 
          ? ApiConstants.posts.substring(0, ApiConstants.posts.length - 1) 
          : ApiConstants.posts;
      final endpoint = '$baseEndpoint/$postId/';
      print('CommunityService: Delete endpoint: $endpoint');
      print('CommunityService: Full URL will be: ${ApiConstants.baseUrl}$endpoint');

      // Attempt deletion
      print('CommunityService: Sending delete request...');
      try {
        final response = await _api.delete(endpoint);
        print('CommunityService: Delete response status: ${response.statusCode}');
        print('CommunityService: Delete response data: ${response.data}');
        
        if (response.statusCode != 204 && response.statusCode != 200) {
          throw Exception('Server returned ${response.statusCode}');
        }
      } catch (e) {
        print('CommunityService: Delete request failed: $e');
        rethrow;
      }
    } catch (e) {
      print('CommunityService: Operation failed: $e');
      rethrow;
    }
  }

  Future<Post> updatePost(int postId, String content, {String? imagePath}) async {
    final data = FormData.fromMap({'content': content});
    if (imagePath != null && imagePath.isNotEmpty) {
      if (kIsWeb) {
        final bytes = await _readFileBytes(imagePath);
        final filename = _getProperFilename(imagePath);
        final mp = await multipartFileFromBytes(bytes, filename);
        data.files.add(MapEntry('image', mp));
      } else {
        // Read local file bytes and create MultipartFile with proper content-type
        try {
          final bytes = await File(imagePath).readAsBytes();
          final filename = imagePath.split('/').last;
          final mp = await multipartFileFromBytes(bytes, filename);
          data.files.add(MapEntry('image', mp));
        } catch (e) {
          // If reading bytes fails (rare), try to construct from path which will
          // still attempt to compress but may fall back to uncompressed file.
          final mp = await multipartFileFromPath(imagePath);
          data.files.add(MapEntry('image', mp));
        }
      }
    }
    final resp = await _api.patch('${ApiConstants.posts}$postId/', data: data);
    return Post.fromJson(resp.data);
  }

  Future<Post> createPost(String content, {String? imagePath}) async {
    final data = FormData.fromMap({'content': content});
    if (imagePath != null && imagePath.isNotEmpty) {
      if (kIsWeb) {
        final bytes = await _readFileBytes(imagePath);
        final filename = _getProperFilename(imagePath);
        final mp = await multipartFileFromBytes(bytes, filename);
        data.files.add(MapEntry('image', mp));
      } else {
        try {
          final bytes = await File(imagePath).readAsBytes();
          final filename = imagePath.split('/').last;
          final mp = await multipartFileFromBytes(bytes, filename);
          data.files.add(MapEntry('image', mp));
        } catch (e) {
          final mp = await multipartFileFromPath(imagePath);
          data.files.add(MapEntry('image', mp));
        }
      }
    }
    final resp = await _api.post(ApiConstants.posts, data: data);
    return Post.fromJson(resp.data);
  }

  String _getProperFilename(String path) {
    // On web, path might be a blob URL like "blob:http://..."
    // Extract filename if present, otherwise generate one
    final parts = path.split('/');
    final lastPart = parts.last;
    
    // Check if it has an extension
    if (lastPart.contains('.')) {
      final ext = lastPart.split('.').last.toLowerCase();
      // Verify it's a valid image extension
      if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
        return lastPart;
      }
    }
    
    // Generate a filename with timestamp and default to .jpg
    return 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }

  Future<List<int>> _readFileBytes(String path) async {
    if (kIsWeb) {
      // On web, the path from image_picker is actually a blob URL or network URL
      // We need to fetch it
      final response = await Dio().get<List<int>>(
        path,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } else {
      // This shouldn't be called on non-web platforms
      throw UnsupportedError('_readFileBytes should only be called on web');
    }
  }

  Future<void> likePost(int postId) async {
    await _api.post('${ApiConstants.posts}$postId/like/');
  }

  Future<void> likeComment(int commentId) async {
    print('CommunityService: likeComment called for commentId: $commentId');
    final endpoint = '${ApiConstants.comments}$commentId/like/';
    print('CommunityService: Endpoint: $endpoint');
    try {
      final response = await _api.post(endpoint);
      print('CommunityService: Response status: ${response.statusCode}');
      print('CommunityService: Response data: ${response.data}');
    } catch (e) {
      print('CommunityService: Error liking comment: $e');
      rethrow;
    }
  }

  Future<User> getUser(int userId) async {
    final resp = await _api.get('${ApiConstants.users}$userId/');
    return User.fromJson(resp.data);
  }

  Future<List<Post>> getUserPosts(int userId) async {
    try {
      final resp = await _api.get(ApiConstants.posts, params: {'author': userId.toString()});
      if (resp.statusCode == 200) {
        if (resp.data is Map && resp.data['results'] is List) {
          return (resp.data['results'] as List).map((p) => Post.fromJson(p)).toList();
        } else if (resp.data is List) {
          return (resp.data as List).map((p) => Post.fromJson(p)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching user posts: $e');
      return [];
    }
  }

  Future<void> deleteComment(int postId, int commentId) async {
    print('Making API call to delete comment $commentId from post $postId');
    try {
      // Fix: Use /api/community/comments/{commentId}/ endpoint format from DRF DefaultRouter
      final endpoint = '${ApiConstants.comments}$commentId/';
      print('CommunityService: Delete comment endpoint: $endpoint');
      print('CommunityService: Full URL will be: ${ApiConstants.baseUrl}$endpoint');
      
      final resp = await _api.delete(endpoint);
      print('Delete comment response: ${resp.statusCode}');
      
      if (resp.statusCode != 204) {
        throw Exception('Unexpected status code: ${resp.statusCode}');
      }
    } catch (e) {
      print('Error deleting comment: $e');
      rethrow;
    }
  }

  Future<void> followUser(int userId) async {
    await _api.post('${ApiConstants.users}$userId/follow/');
  }

  Future<void> unfollowUser(int userId) async {
    await _api.post('${ApiConstants.users}$userId/unfollow/');
  }

  Future<Comment> addComment(int postId, String content) async {
    final resp = await _api.post(
      '${ApiConstants.posts}$postId/comment/',
      data: {'content': content},
    );
    return Comment.fromJson(resp.data);
  }

  Future<List<User>> getFollowers(int userId) async {
    try {
      print('Fetching followers for user $userId');
      final endpoint = '${ApiConstants.users}$userId/followers/';
      print('Endpoint: $endpoint');
      
      final resp = await _api.get(endpoint);
      print('Followers response: ${resp.data}');
      
      if (resp.statusCode == 200) {
        if (resp.data is Map && resp.data['results'] is List) {
          final results = resp.data['results'] as List;
          print('Found ${results.length} followers');
          return results.map((u) => User.fromJson(u)).toList();
        } else if (resp.data is List) {
          print('Found ${resp.data.length} followers (direct list)');
          return (resp.data as List).map((u) => User.fromJson(u)).toList();
        }
      }
      print('Unexpected followers response: Status ${resp.statusCode}, Data: ${resp.data}');
      return [];
    } catch (e) {
      print('Error fetching followers: $e');
      rethrow;
    }
  }

  Future<List<User>> getFollowing(int userId) async {
    try {
      print('Fetching following for user $userId');
      final endpoint = '${ApiConstants.users}$userId/following/';
      print('Endpoint: $endpoint');
      
      final resp = await _api.get(endpoint);
      print('Following response: ${resp.data}');
      
      if (resp.statusCode == 200) {
        if (resp.data is Map && resp.data['results'] is List) {
          final results = resp.data['results'] as List;
          print('Found ${results.length} following');
          return results.map((u) => User.fromJson(u)).toList();
        } else if (resp.data is List) {
          print('Found ${resp.data.length} following (direct list)');
          return (resp.data as List).map((u) => User.fromJson(u)).toList();
        }
      }
      print('Unexpected following response: Status ${resp.statusCode}, Data: ${resp.data}');
      return [];
    } catch (e) {
      print('Error fetching following: $e');
      rethrow;
    }
  }

  // Group Post Methods
  Future<List<GroupPost>> getGroupPosts(int groupId) async {
    print('Fetching group posts for group $groupId');
    try {
      final resp = await _api.get(
        ApiConstants.groupPosts,
        params: {'group': groupId.toString()},
      );
      print('Group posts response: ${resp.data}');
      
      if (resp.statusCode == 200) {
        final data = resp.data;
        List<GroupPost> posts = [];
        
        if (data is Map && data['results'] is List) {
          posts = (data['results'] as List)
              .map((p) => GroupPost.fromJson(p))
              .toList();
        } else if (data is List) {
          posts = data.map((p) => GroupPost.fromJson(p)).toList();
        }
        
        print('Successfully parsed ${posts.length} group posts');
        return posts;
      }
      
      print('Unexpected response: ${resp.statusCode} - ${resp.data}');
      throw Exception('Failed to fetch group posts: ${resp.statusCode}');
    } catch (e) {
      print('Error fetching group posts: $e');
      rethrow;
    }
  }

  Future<GroupPost> createGroupPost({
    required int groupId,
    required String content,
    XFile? imageFile,
  }) async {
    print('Creating group post for group $groupId');
    try {
      FormData formData = FormData.fromMap({
        'group': groupId,
        'content': content,
      });

      if (imageFile != null) {
        final mp = await multipartFileFromXFile(imageFile);
        formData.files.add(MapEntry('image', mp));
      }

      final resp = await _api.post(ApiConstants.groupPosts, data: formData);
      print('Create group post response: ${resp.data}');
      
      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return GroupPost.fromJson(resp.data);
      }
      
      throw Exception('Failed to create group post: ${resp.statusCode}');
    } catch (e) {
      print('Error creating group post: $e');
      rethrow;
    }
  }

  Future<void> deleteGroupPost(int postId) async {
    print('Deleting group post $postId');
    try {
      final resp = await _api.delete('${ApiConstants.groupPosts}$postId/');
      print('Delete group post response: ${resp.statusCode}');
      
      if (resp.statusCode == 204 || resp.statusCode == 200) {
        return;
      }
      
      throw Exception('Failed to delete group post: ${resp.statusCode}');
    } catch (e) {
      print('Error deleting group post: $e');
      rethrow;
    }
  }

  Future<bool> togglePinGroupPost(int postId) async {
    print('Toggling pin for group post $postId');
    try {
      final resp = await _api.post('${ApiConstants.groupPosts}$postId/pin/');
      print('Toggle pin response: ${resp.data}');
      
      if (resp.statusCode == 200) {
        return resp.data['is_pinned'] ?? false;
      }
      
      throw Exception('Failed to toggle pin: ${resp.statusCode}');
    } catch (e) {
      print('Error toggling pin: $e');
      rethrow;
    }
  }
}
