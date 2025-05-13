import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String bookTitle;
  final String otherUserId;
  final String otherUserName;
  final bool tradeCompleted;
  final DateTime? completedAt;
  final List<String> typingUsers;

  ChatModel({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.bookTitle,
    required this.otherUserId,
    required this.otherUserName,
    this.tradeCompleted = false,
    this.completedAt,
    this.typingUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'chatId': chatId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'bookTitle': bookTitle,
      'otherUserId': otherUserId,
      'otherUserName': otherUserName,
      'tradeCompleted': tradeCompleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'typingUsers': typingUsers,
    };
  }

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      chatId: data['chatId'] ?? doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookTitle: data['bookTitle'] ?? '',
      otherUserId: data['otherUserId'] ?? '',
      otherUserName: data['otherUserName'] ?? '',
      tradeCompleted: data['tradeCompleted'] ?? false,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      typingUsers: List<String>.from(data['typingUsers'] ?? []),
    );
  }

  ChatModel copyWith({
    String? chatId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? bookTitle,
    String? otherUserId,
    String? otherUserName,
    bool? tradeCompleted,
    DateTime? completedAt,
    List<String>? typingUsers,
  }) {
    return ChatModel(
      chatId: chatId ?? this.chatId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      bookTitle: bookTitle ?? this.bookTitle,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      tradeCompleted: tradeCompleted ?? this.tradeCompleted,
      completedAt: completedAt ?? this.completedAt,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }
}