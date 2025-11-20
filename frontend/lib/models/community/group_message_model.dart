class GroupMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final bool isSystemMessage;
  final DateTime createdAt;

  GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.isSystemMessage = false,
    required this.createdAt,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'],
      senderId: json['sender_id'] ?? json['sender'],
      senderName: json['sender_name'] ?? 'Unknown',
      senderAvatar: json['sender_avatar'],
      content: json['content'],
      isSystemMessage: json['is_system_message'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
