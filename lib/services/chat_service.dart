import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get chat ID between two users
  String getChatId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort(); // Sort to ensure consistent chat ID
    return ids.join('_');
  }

  // Send a message
  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    final String chatId = getChatId(senderId, receiverId);
    final timestamp = Timestamp.now();

    // Create message document
    final messageDoc = Message(
      id: '', // Will be assigned by Firestore
      senderId: senderId,
      receiverId: receiverId,
      text: message,
      timestamp: timestamp,
      type: type,
      metadata: metadata,
    ).toMap();

    // Add message to chat collection
    DocumentReference msgRef = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(messageDoc);

    // Update chat document with last message info
    await _firestore.collection('chats').doc(chatId).set({
      'participantsIds': [senderId, receiverId],
      'lastMessageTime': timestamp,
      'lastMessageText': message,
      'lastMessageSenderId': senderId,
      'active': true,
    }, SetOptions(merge: true));

    // Update unread count for receiver
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount': FieldValue.increment(1),
    });
  }

  // Get messages stream between two users
  Stream<QuerySnapshot> getMessages(String currentUserId, String otherUserId) {
    final String chatId = getChatId(currentUserId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String currentUserId, String otherUserId) async {
    final String chatId = getChatId(currentUserId, otherUserId);

    // Reset unread count
    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount': 0,
    });

    // Mark individual messages as read
    QuerySnapshot unreadMessages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    WriteBatch batch = _firestore.batch();
    for (var doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // Respond to meetup proposal
  Future<void> respondToMeetupProposal({
    required String messageId,
    required String senderId,
    required String receiverId,
    required Map<String, dynamic> response,
  }) async {
    final String chatId = getChatId(senderId, receiverId);

    // Update the original message with response
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'metadata.response': response,
    });

    // Send a notification message about the response
    String notificationText = response['status'] == 'accepted'
        ? 'Meetup proposal accepted!'
        : 'Meetup proposal declined.';

    await sendMessage(
      senderId: senderId,
      receiverId: receiverId,
      message: notificationText,
      type: MessageType.meetupResponse,
      metadata: {'originalMessageId': messageId},
    );
  }

  // Unmatch users (deactivate chat)
  Future<void> unmatchUsers(String currentUserId, String otherUserId) async {
    final String chatId = getChatId(currentUserId, otherUserId);

    await _firestore.collection('chats').doc(chatId).update({
      'active': false,
    });
  }
  // Add this to ChatService
  Stream<QuerySnapshot> getUserMatches(String userId) {
    return _firestore
        .collection('chats')
        .where('participantsIds', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot> getRecentChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participantsIds', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

}