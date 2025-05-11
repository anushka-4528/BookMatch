import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  meetupProposal,
  meetupResponse,
}

class Message {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final Timestamp timestamp;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
    required this.type,
    this.metadata,
    this.isRead = false,
  });

  factory Message.fromMap(Map<String, dynamic> map, String id) {
    return Message(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      type: _getMessageTypeFromString(map['type'] ?? 'text'),
      metadata: map['metadata'],
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': timestamp,
      'type': type.toString().split('.').last,
      'metadata': metadata,
      'isRead': isRead,
    };
  }

  static MessageType _getMessageTypeFromString(String typeStr) {
    switch (typeStr) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'meetupProposal':
        return MessageType.meetupProposal;
      case 'meetupResponse':
        return MessageType.meetupResponse;
      default:
        return MessageType.text;
    }
  }
}