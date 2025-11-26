import '../models/user/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';

import '../utils/file_utils.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? firstName,
    String? lastName,
    String? phone,
  }) async {
    final resp = await _api.post(
      ApiConstants.register,
      data: {
        'username': username,
        'email': email,
        'password': password,
        'password2': password,
        'first_name': firstName ?? '',
        'last_name': lastName ?? '',
        'phone': phone ?? '',
      },
    );

    if (resp.statusCode == 201 || resp.statusCode == 200) {
      final data = resp.data;
      final user = data['user'] != null ? User.fromJson(data['user']) : null;
      final access = data['tokens']?['access']?.toString();
      final refresh = data['tokens']?['refresh']?.toString();

      final result = <String, dynamic>{
        'user': user,
        'requires_verification': data['requires_verification'] ?? false,
        // backend may return pending_id when account is not yet created
        'pending_id': data['pending_id'] ?? data['user_id'],
        'tokens': data['tokens'],
      };

      // If backend issued tokens (rare on registration when verification required), save them now
      if (access != null) {
        await _api.saveToken(access, refreshToken: refresh);
      }

      return result;
    }

    // Non-2xx: try to extract a helpful error message from response body
    final body = resp.data;
    String message = 'Registration failed';
    try {
      if (body is Map) {
        if (body.containsKey('detail')) {
          message = body['detail'].toString();
        } else if (body.keys.isNotEmpty) {
          final firstKey = body.keys.first;
          final val = body[firstKey];
          if (val is List && val.isNotEmpty) {
            message = val.first.toString();
          } else {
            message = val.toString();
          }
        }
      } else if (body is String) {
        message = body;
      }
    } catch (_) {}

    throw Exception(message);
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final resp = await _api.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
      },
    );

    if (resp.statusCode == 200) {
      final data = resp.data;
      final user = User.fromJson(data['user']);
      final access = data['tokens']?['access']?.toString();
      final refresh = data['tokens']?['refresh']?.toString();

      if (access != null) {
        await _api.saveToken(access, refreshToken: refresh);
      }
      return user;
    }

    throw Exception('Login failed');
  }

  Future<User> socialLoginGoogle({required String idToken}) async {
    final resp = await _api.post(
      ApiConstants.socialLogin,
      data: {
        'provider': 'google',
        'id_token': idToken,
      },
    );

    if (resp.statusCode == 200) {
      final data = resp.data;
      final user = User.fromJson(data['user']);
      final access = data['tokens']?['access']?.toString();
      final refresh = data['tokens']?['refresh']?.toString();

      if (access != null) {
        await _api.saveToken(access, refreshToken: refresh);
      }
      return user;
    }

    throw Exception('Social login failed');
  }

  Future<User> getProfile() async {
    final resp = await _api.get(ApiConstants.profile);
    if (resp.statusCode == 200) {
      return User.fromJson(resp.data);
    }
    throw Exception('Failed to fetch profile');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final resp = await _api.post(
      ApiConstants.changePassword,
      data: {
        'old_password': currentPassword,
        'new_password': newPassword,
      },
    );
    if (resp.statusCode != 200) {
      throw Exception(resp.data?['message'] ?? 'Failed to change password');
    }
  }

  Future<User> updateProfile({
    String? username,
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? location,
  }) async {
    final data = <String, dynamic>{};
    if (username != null) data['username'] = username.trim();
    if (firstName != null) data['first_name'] = firstName.trim();
    if (lastName != null) data['last_name'] = lastName.trim();
    if (phone != null) data['phone'] = phone.trim();
    if (bio != null) data['bio'] = bio.trim();
    if (location != null) data['location'] = location.trim();

    final resp = await _api.patch(ApiConstants.profile, data: data);
    if (resp.statusCode == 200) {
      return User.fromJson(resp.data);
    }
    throw Exception('Failed to update profile');
  }

  Future<User> updateAvatar({
    String? imagePath,
    List<int>? imageBytes,
    String? fileName,
  }) async {
    if (imageBytes == null && (imagePath == null || imagePath.isEmpty)) {
      throw Exception('No image provided');
    }

    final data = <String, dynamic>{};
    if (imageBytes != null) {
      final mp = await multipartFileFromBytes(imageBytes, fileName ?? 'avatar.jpg');
      data['avatar'] = mp;
    } else {
      final mp = await multipartFileFromPath(imagePath!);
      data['avatar'] = mp;
    }
    final form = FormData.fromMap(data);

    final resp = await _api.patch(ApiConstants.profile, data: form);
    if (resp.statusCode == 200) {
      return User.fromJson(resp.data);
    }
    throw Exception('Failed to update avatar');
  }

  Future<void> sendOtp({String? email, int? userId}) async {
    final data = <String, dynamic>{};
    if (email != null) data['email'] = email;
    if (userId != null) data['user_id'] = userId;
    final resp = await _api.post(ApiConstants.sendOtp, data: data);
    if (resp.statusCode != 200 && resp.statusCode != 201) {
      throw Exception('Failed to send OTP');
    }
  }

  /// Reset password for a user (used after OTP verification which issues tokens).
  /// Backend is expected to accept this request for an authenticated user.
  Future<void> resetPassword({required String newPassword}) async {
    final resp = await _api.post(
      ApiConstants.resetPassword,
      data: {'new_password': newPassword},
    );
    if (resp.statusCode != 200 && resp.statusCode != 204) {
      throw Exception(resp.data?['message'] ?? 'Failed to reset password');
    }
  }

  Future<User> verifyOtp({String? email, int? userId, required String code}) async {
    final data = <String, dynamic>{'code': code};
    if (email != null) data['email'] = email;
    if (userId != null) data['user_id'] = userId;

    final resp = await _api.post(ApiConstants.verifyOtp, data: data);
    if (resp.statusCode == 200) {
      final data = resp.data;
      final user = User.fromJson(data['user']);
      final access = data['tokens']?['access']?.toString();
      final refresh = data['tokens']?['refresh']?.toString();

      if (access != null) {
        await _api.saveToken(access, refreshToken: refresh);
      }
      return user;
    }
    throw Exception('OTP verification failed');
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }
}