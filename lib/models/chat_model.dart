import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> participantsIds;
  final Timestamp createdAt;
  final Timestamp lastMessageTime;
  final String? lastMessageText;
  final String? lastMessageSenderId;
  final int unreadCount;
  final bool active;

  ChatModel({
    required this.id,
    required this.participantsIds,
    required this.createdAt,
    required this.lastMessageTime,
    this.lastMessageText,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.active,
  });

  factory ChatModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return ChatModel(
      id: doc.id,
      participantsIds: List<String>.from(data['participantsIds'] ?? []),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastMessageTime: data['lastMessageTime'] ?? Timestamp.now(),
      lastMessageText: data['lastMessageText'],
      lastMessageSenderId: data['lastMessageSenderId'],
      unreadCount: data['unreadCount'] ?? 0,
      active: data['active'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participantsIds': participantsIds,
      'createdAt': createdAt,
      'lastMessageTime': lastMessageTime,
      'lastMessageText': lastMessageText,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'active': active,
    };
  }

  ChatModel copyWith({
    List<String>? participantsIds,
    Timestamp? createdAt,
    Timestamp? lastMessageTime,
    String? lastMessageText,
    String? lastMessageSenderId,
    int? unreadCount,
    bool? active,
  }) {
    return ChatModel(
      id: this.id,
      participantsIds: participantsIds ?? this.participantsIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      active: active ?? this.active,
    );
  }
}