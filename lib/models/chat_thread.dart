import '../main.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final UserRole senderRole;
  final String text;
  final DateTime timestamp;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.timestamp,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    UserRole? senderRole,
    String? text,
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

class ChatThread {
  final String id;
  final String requestId;
  final String elderId;
  final String volunteerId;
  final List<ChatMessage> messages;
  final DateTime updatedAt;

  const ChatThread({
    required this.id,
    required this.requestId,
    required this.elderId,
    required this.volunteerId,
    required this.messages,
    required this.updatedAt,
  });

  ChatThread copyWith({
    String? id,
    String? requestId,
    String? elderId,
    String? volunteerId,
    List<ChatMessage>? messages,
    DateTime? updatedAt,
  }) {
    return ChatThread(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      elderId: elderId ?? this.elderId,
      volunteerId: volunteerId ?? this.volunteerId,
      messages: (messages ?? this.messages)
          .map((message) => message.copyWith())
          .toList(),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
