class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      // Ensure server timestamps are interpreted in UTC then converted to local time
      // so relative-time displays and scheduling align with the device timezone.
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      // Convert to UTC string when sending back to the server
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_read': isRead,
    };
  }
}