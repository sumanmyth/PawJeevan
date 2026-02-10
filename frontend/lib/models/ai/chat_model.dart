/// Models for AI chat functionality

class ChatSession {
  final int id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;
  final int messagesCount;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
    this.messagesCount = 0,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'] ?? 'New Chat',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      messages: (json['messages'] as List?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
      messagesCount: json['messages_count'] ?? 0,
    );
  }
}

class ChatMessage {
  final int? id;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime? createdAt;
  final double? responseTime;

  ChatMessage({
    this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.responseTime,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      createdAt:
          json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      responseTime: json['response_time']?.toDouble(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}
