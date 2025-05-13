import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:developer' as developer;

import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../services/notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();

  // Get or create a chat document between two users
  Future<String> getChatId(String userId1, String userId2) async {
    // Sort user IDs to ensure consistent chat ID
    final List<String> sortedIds = [userId1, userId2]..sort();
    final String chatId = sortedIds.join('_');

    // Check if chat document exists, if not create it
    final chatDoc = await _firestore.collection('chats').doc(chatId).get();

    if (!chatDoc.exists) {
      await _firestore.collection('chats').doc(chatId).set({
        'participants': sortedIds,
        'createdAt': Timestamp.now(),
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
        'tradeCompleted': false,
      });
    }

    return chatId;
  }

  // Send a message to a chat
  Future<void> sendMessage({
    required String chatId,
    required String text,
    required String senderId,
    required String receiverId,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Skip notification for system or suggestion messages
      bool shouldNotify = senderId != 'system' && senderId != 'suggestion';
      
      // Create message document
      final message = MessageModel(
        id: '', // Firestore will generate ID
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        timestamp: Timestamp.now(),
        type: type,
        metadata: metadata,
        isRead: false,
      );

      // Add message to collection
      DocumentReference docRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());

      // Update chat document with last message info
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': text,
        'lastMessageTime': Timestamp.now(),
        'lastMessageType': type.toString(),
        'lastSenderId': senderId,
      });

      // Update unread counts for receiver
      await updateUnreadCount(chatId, receiverId);
      
      // Send a notification for the message (if not a system message)
      if (shouldNotify && receiverId != 'all') {
        // Get sender name
        String senderName = "User";
        try {
          final senderDoc = await _firestore.collection('users').doc(senderId).get();
          if (senderDoc.exists) {
            senderName = senderDoc.data()?['name'] ?? "User";
          }
        } catch (e) {
          developer.log('Error getting sender name', name: 'ChatService', error: e);
        }
        
        // Get book title
        String bookTitle = "";
        try {
          final chatDoc = await _firestore.collection('chats').doc(chatId).get();
          if (chatDoc.exists) {
            bookTitle = chatDoc.data()?['bookTitle'] ?? "";
          }
        } catch (e) {
          developer.log('Error getting book title', name: 'ChatService', error: e);
        }
        
        // Send notification
        await _notificationService.createChatNotification(
          receiverId: receiverId,
          senderId: senderId,
          senderName: senderName,
          message: text,
          chatId: chatId,
          bookTitle: bookTitle,
        );
      }
    } catch (e) {
      developer.log('Error sending message', name: 'ChatService', error: e);
      rethrow;
    }
  }

  // Get stream of messages for a chat
  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromDocument(doc))
        .toList());
  }

  // Update typing status
  Future<void> updateTypingStatus(String chatId, String userId, bool isTyping) async {
    await _firestore.collection('chats').doc(chatId).update({
      'typingUsers': isTyping
          ? FieldValue.arrayUnion([userId])
          : FieldValue.arrayRemove([userId]),
    });
  }

  // Get stream for typing status
  Stream<bool> getTypingStatus(String chatId, String userId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['typing_$userId'] ?? false);
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String currentUserId) async {
    final messagesQuery = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();

    for (var doc in messagesQuery.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();

    // Reset unread count for current user
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .doc(chatId)
        .update({'unreadCount': 0});
  }

  // Update unread count for a user
  Future<void> updateUnreadCount(String chatId, String userId) async {
    // Skip for system or non-user receivers
    if (userId == 'system' || userId == 'all' || userId == 'suggestion') {
      return;
    }
    
    // Get reference to the user's chat document
    final userChatRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId);

    // Get current document or create it if it doesn't exist
    final docSnapshot = await userChatRef.get();

    if (docSnapshot.exists) {
      await userChatRef.update({
        'unreadCount': FieldValue.increment(1),
        'lastUpdated': Timestamp.now(),
      });
    } else {
      await userChatRef.set({
        'chatId': chatId,
        'unreadCount': 1,
        'lastUpdated': Timestamp.now(),
      });
    }
  }

  // Get all chats for current user
  Stream<List<DocumentSnapshot>> getUserChats() {
    final currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Mark a trade as completed
  Future<void> markTradeAsCompleted(String chatId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'tradeCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Get chat info to send notifications
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();
      
      if (chatData != null) {
        final List<dynamic> participants = chatData['participants'] ?? [];
        final String bookTitle = chatData['bookTitle'] ?? 'Unknown Book';
        
        if (participants.length < 2) return;
        
        // Get user information
        final user1Doc = await _firestore.collection('users').doc(participants[0]).get();
        final user2Doc = await _firestore.collection('users').doc(participants[1]).get();
        
        final String user1Name = user1Doc.data()?['name'] ?? 'User';
        final String user2Name = user2Doc.data()?['name'] ?? 'User';
        
        // Send notification to both users
        await _notificationService.createTradeCompletedNotification(
          userId: participants[0],
          otherUserId: participants[1],
          otherUserName: user2Name,
          bookTitle: bookTitle,
          chatId: chatId,
        );
        
        await _notificationService.createTradeCompletedNotification(
          userId: participants[1],
          otherUserId: participants[0],
          otherUserName: user1Name,
          bookTitle: bookTitle,
          chatId: chatId,
        );
      }
    } catch (e) {
      developer.log('Error marking trade as completed', name: 'ChatService', error: e);
      rethrow;
    }
  }

  // Check if a trade is completed
  Future<bool> isTradeCompleted(String chatId) async {
    final doc = await _firestore.collection('chats').doc(chatId).get();
    return doc.data()?['tradeCompleted'] ?? false;
  }

  // Respond to a meetup request
  Future<void> respondToMeetup(String chatId, String messageId, String status) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'metadata.status': status,
    });
  }

  // Get chats with unread messages
  Stream<int> getTotalUnreadCount() {
    final currentUserId = _auth.currentUser!.uid;

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('chats')
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        count += (doc.data()['unreadCount'] ?? 0) as int;
      }
      return count;
    });
  }

  // Delete a chat (for testing purposes)
  Future<void> deleteChat(String chatId) async {
    // Delete all messages in the chat
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .get();

    final batch = _firestore.batch();

    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat document
    batch.delete(_firestore.collection('chats').doc(chatId));

    await batch.commit();

    // Clean up user references
    final participants = await _firestore
        .collection('users')
        .where('chats', arrayContains: chatId)
        .get();

    for (var user in participants.docs) {
      await _firestore
          .collection('users')
          .doc(user.id)
          .collection('chats')
          .doc(chatId)
          .delete();
    }
  }

  // Create a new chat or update existing one
  Future<void> createOrUpdateChat(ChatModel chat) async {
    try {
      final chatRef = _firestore.collection('chats').doc(chat.chatId);
      final chatDoc = await chatRef.get();
      
      if (chatDoc.exists) {
        // Update existing chat
        await chatRef.update({
          'lastMessage': chat.lastMessage,
          'lastMessageTime': Timestamp.fromDate(chat.lastMessageTime),
          'bookTitle': chat.bookTitle,
        });
      } else {
        // Create new chat
        await chatRef.set({
          'chatId': chat.chatId,
          'participants': chat.participants,
          'lastMessage': chat.lastMessage,
          'lastMessageTime': Timestamp.fromDate(chat.lastMessageTime),
          'bookTitle': chat.bookTitle,
          'createdAt': Timestamp.now(),
          'isCompleted': false,
        });
        
        // Add initial system message
        await sendMessage(
          chatId: chat.chatId,
          text: "You've connected over \"${chat.bookTitle}\"! Start chatting to arrange a book swap.",
          senderId: "system",
          receiverId: "all",
          type: MessageType.system,
        );
      }
    } catch (e) {
      developer.log('Error creating/updating chat', name: 'ChatService', error: e);
      rethrow;
    }
  }

  // Create a new chat and return the chat ID
  Future<String> createChat({
    required String currentUserId,
    required String matchedUserId,
    required String bookId,
  }) async {
    final chatId = 'chat_${currentUserId}_${matchedUserId}_$bookId';

    // Get the matched user's data
    final matchedUserDoc = await _firestore.collection('users').doc(matchedUserId).get();
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final bookDoc = await _firestore.collection('books').doc(bookId).get();

    if (!matchedUserDoc.exists || !currentUserDoc.exists || !bookDoc.exists) {
      throw Exception('Required data not found');
    }

    final chat = ChatModel(
      chatId: chatId,
      participants: [currentUserId, matchedUserId],
      lastMessage: 'Started a chat about ${bookDoc['title']}',
      lastMessageTime: DateTime.now(),
      bookTitle: bookDoc['title'],
      otherUserId: matchedUserId,
      otherUserName: matchedUserDoc['name'],
    );

    await createOrUpdateChat(chat);
    return chatId;
  }

  // Get messages stream for a chat
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get active chats for a user
  Future<List<ChatModel>> getActiveChatsForUser(String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .get();

    return snapshot.docs.map((doc) => ChatModel.fromDocument(doc)).toList();
  }
}