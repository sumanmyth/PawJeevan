class GroupPost {
  final int id;
  final int group;
  final int author;
  final String authorUsername;
  final String? authorAvatar;
  final int? groupCreatorId;
  final String content;
  final String? image;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupPost({
    required this.id,
    required this.group,
    required this.author,
    required this.authorUsername,
    this.authorAvatar,
    this.groupCreatorId,
    required this.content,
    this.image,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupPost.fromJson(Map<String, dynamic> json) {
    return GroupPost(
      id: json['id'] ?? 0,
      group: json['group'] ?? 0,
      author: json['author_id'] ?? json['author'] ?? 0,
      authorUsername: json['author_username'] ?? 'User',
      authorAvatar: json['author_avatar'],
      groupCreatorId: json['group_creator_id'],
      content: json['content'] ?? '',
      image: json['image'],
      isPinned: json['is_pinned'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group': group,
      'author': author,
      'author_username': authorUsername,
      'author_avatar': authorAvatar,
      'group_creator_id': groupCreatorId,
      'content': content,
      'image': image,
      'is_pinned': isPinned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
