class Comment {
  final int id;
  final int author;
  final String authorUsername;
  final String? authorAvatar;
  final String content;
  final DateTime createdAt;
  final List<Comment>? replies;
  final bool isCurrentUserAuthor;
  final int likesCount;
  final bool isLiked;

  Comment({
    required this.id,
    required this.author,
    required this.authorUsername,
    this.authorAvatar,
    required this.content,
    required this.createdAt,
    this.replies,
    this.isCurrentUserAuthor = false,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] ?? 0,
      author: json['author'] ?? 0,
      authorUsername: json['author_username'] ?? 'User',
      authorAvatar: json['author_avatar'],
      content: json['content'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isCurrentUserAuthor: json['is_current_user_author'] ?? false,
      likesCount: json['likes_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      replies: json['replies'] != null
          ? (json['replies'] as List).map((r) => Comment.fromJson(r)).toList()
          : [],
    );
  }

  Comment copyWith({
    bool? isLiked,
    int? likesCount,
  }) {
    return Comment(
      id: id,
      author: author,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      content: content,
      createdAt: createdAt,
      replies: replies,
      isCurrentUserAuthor: isCurrentUserAuthor,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }
}

class Post {
  final int id;
  final int author;
  final String authorUsername;
  final String? authorAvatar;
  final String content;
  final String? image;
  final String? video;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final DateTime createdAt;
  final List<Comment>? comments;
  final bool isCurrentUserAuthor;

  Post({
    required this.id,
    this.isCurrentUserAuthor = false,
    required this.author,
    required this.authorUsername,
    this.authorAvatar,
    required this.content,
    this.image,
    this.video,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
    required this.createdAt,
    this.comments,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? 0,
      author: json['author'] ?? 0,
      authorUsername: json['author_username'] ?? 'User',
      authorAvatar: json['author_avatar'],
      content: json['content'] ?? '',
      image: json['image'],
      video: json['video'],
      likesCount: json['likes_count'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      isCurrentUserAuthor: json['is_current_user_author'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      comments: json['comments'] != null
          ? (json['comments'] as List).map((c) => Comment.fromJson(c)).toList()
          : [],
    );
  }

  factory Post.empty() {
    return Post(
      id: 0,
      author: 0,
      authorUsername: '',
      content: '',
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
      isCurrentUserAuthor: false,
      createdAt: DateTime.now(),
    );
  }

  Post copyWith({
    bool? isLiked,
    int? likesCount,
    int? commentsCount,
    List<Comment>? comments,
  }) {
    return Post(
      id: id,
      author: author,
      authorUsername: authorUsername,
      authorAvatar: authorAvatar,
      content: content,
      image: image,
      video: video,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isCurrentUserAuthor: isCurrentUserAuthor,
      createdAt: createdAt,
      comments: comments ?? this.comments,
    );
  }
}
