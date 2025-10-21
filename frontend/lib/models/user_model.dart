import '../utils/constants.dart';

class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? avatar;     // raw value from backend (may be relative)
  final String? bio;
  final String? location;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.avatar,
    this.bio,
    this.location,
    this.isVerified = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? created;
    if (json['created_at'] != null) {
      try {
        created = DateTime.tryParse(json['created_at'].toString());
      } catch (_) {
        created = null;
      }
    }

    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      phone: json['phone'],
      avatar: json['avatar']?.toString(), // may be relative
      bio: json['bio'],
      location: json['location'],
      isVerified: json['is_verified'] ?? false,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
      createdAt: created,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'avatar': avatar,
      'bio': bio,
      'location': location,
      'is_verified': isVerified,
      'followers_count': followersCount,
      'following_count': followingCount,
      'is_following': isFollowing,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get displayName {
    final fn = (firstName ?? '').trim();
    final ln = (lastName ?? '').trim();
    final full = '$fn $ln'.trim();
    return full.isEmpty ? username : full;
  }

  // Normalized absolute URL to use in UI
  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    final a = avatar!;
    if (a.startsWith('http://') || a.startsWith('https://')) return a;
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
    if (a.startsWith('/')) return '$base$a';
    return '$base/$a';
  }
}
