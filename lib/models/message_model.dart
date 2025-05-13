import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  system,
  meetupResponse,
  suggestion,
  // Add other types as needed
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.type,
    this.metadata,
    this.isRead = false,
  });

  // Convert MessageType string to enum
  static MessageType _stringToMessageType(String type) {
    switch (type) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'system':
        return MessageType.system;
      case 'meetupResponse':
        return MessageType.meetupResponse;
        case 'suggestion':
        return MessageType.suggestion;
      default:
        return MessageType.text;
    }
  }

  // Convert MessageType enum to string
  static String _messageTypeToString(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'text';
      case MessageType.image:
        return 'image';
      case MessageType.system:
        return 'system';
      case MessageType.meetupResponse:
        return 'meetupResponse';
      case MessageType.suggestion:
        return 'suggestion';
      default:
        return 'text';
    }
  }

  // Create a MessageModel from a Firestore document
  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      receiverId: data['receiverId'] ?? '',
      text: data['text'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      type: _stringToMessageType(data['type'] ?? 'text'),
      metadata: data['metadata'],
      isRead: data['isRead'] ?? false,
    );
  }

  // Convert the MessageModel to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'type': _messageTypeToString(type),
      'metadata': metadata,
      'isRead': isRead,
    };
  }
}