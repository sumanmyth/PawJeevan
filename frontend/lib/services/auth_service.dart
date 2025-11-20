import '../models/user/user_model.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'package:dio/dio.dart';

class AuthService {
  final ApiService _api = ApiService();

  Future<User> register({
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
      final user = User.fromJson(data['user']);
      final access = data['tokens']?['access']?.toString();
      final refresh = data['tokens']?['refresh']?.toString();

      if (access != null) {
        await _api.saveToken(access, refreshToken: refresh);
      }
      return user;
    }

    throw Exception('Registration failed');
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
    String? firstName,
    String? lastName,
    String? phone,
    String? bio,
    String? location,
  }) async {
    final data = <String, dynamic>{};
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

    final form = FormData.fromMap({
      if (imageBytes != null)
        'avatar': MultipartFile.fromBytes(imageBytes, filename: fileName ?? 'avatar.jpg')
      else
        'avatar': await MultipartFile.fromFile(imagePath!, filename: imagePath.split('/').last),
    });

    final resp = await _api.patch(ApiConstants.profile, data: form);
    if (resp.statusCode == 200) {
      return User.fromJson(resp.data);
    }
    throw Exception('Failed to update avatar');
  }

  Future<void> logout() async {
    await _api.clearTokens();
  }
}