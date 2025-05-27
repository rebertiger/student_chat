import 'package:equatable/equatable.dart';

// Model representing a single chat message
class ChatMessageModel extends Equatable {
  final int messageId;
  final int roomId;
  final int? senderId; // Nullable if sender can be deleted
  final String? senderFullName; // Included from backend query
  final String messageType; // 'text', 'image', 'pdf'
  final String? messageText;
  final String? fileUrl;
  final DateTime sentAt;
  final bool isEdited; // Currently unused, but part of schema

  const ChatMessageModel({
    required this.messageId,
    required this.roomId,
    this.senderId,
    this.senderFullName,
    required this.messageType,
    this.messageText,
    this.fileUrl,
    required this.sentAt,
    required this.isEdited,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    // Helper to safely extract nested properties
    T? safeGet<T>(Map<String, dynamic>? obj, String key) {
      return obj != null && obj.containsKey(key) ? obj[key] as T? : null;
    }

    // Helper to safely convert to int
    int? toInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final messageId = toInt(json['message_id']);
    final roomId = toInt(json['room_id']);
    if (messageId == null || roomId == null) {
      throw FormatException(
          'Invalid message_id or room_id format in JSON: $json');
    }

    // Try to get senderFullName from multiple possible locations
    String? senderFullName = json['sender_full_name'] as String? ??
        json['senderFullName'] as String? ??
        safeGet<String>(json['sender'] as Map<String, dynamic>?, 'full_name');

    return ChatMessageModel(
      messageId: messageId,
      roomId: roomId,
      senderId: toInt(json['sender_id']),
      senderFullName: senderFullName,
      messageType: json['message_type'] as String? ?? 'text',
      messageText: json['message_text'] as String?,
      fileUrl: json['file_url'] as String?,
      sentAt: DateTime.parse(
          json['sent_at'] as String? ?? DateTime.now().toIso8601String()),
      isEdited: json['is_edited'] as bool? ?? false,
    );
  }

  // toJson might be useful for sending a message structure via WebSocket if needed
  Map<String, dynamic> toJson() {
    return {
      'message_id': messageId,
      'room_id': roomId,
      'sender_id': senderId,
      'sender_full_name': senderFullName, // Include if needed by receiver
      'message_type': messageType,
      'message_text': messageText,
      'file_url': fileUrl,
      'sent_at': sentAt.toIso8601String(),
      'is_edited': isEdited,
    };
  }

  @override
  List<Object?> get props => [
        messageId,
        roomId,
        senderId,
        senderFullName,
        messageType,
        messageText,
        fileUrl,
        sentAt,
        isEdited,
      ];
}
