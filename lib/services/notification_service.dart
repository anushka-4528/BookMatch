import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Local notifications plugin
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  // For storing notification badges count
  int _unreadCount = 0;
  
  // Stream controller for notifications
  Stream<QuerySnapshot>? _notificationsStream;
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal() {
    _initNotifications();
  }
  
  Future<void> _initNotifications() async {
    // Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }
  
  // Subscribe to notifications for the current user
  Stream<QuerySnapshot> getNotificationsStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.empty();
    }
    
    if (_notificationsStream == null) {
      _notificationsStream = _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
    
    return _notificationsStream!;
  }
  
  // Get unread notifications count
  Future<int> getUnreadCount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return 0;
    }
    
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
          
      _unreadCount = querySnapshot.docs.length;
      return _unreadCount;
    } catch (e) {
      developer.log(
        'Error getting unread notifications count',
        name: 'BookMatch.NotificationService',
        error: e,
        level: 1000,
      );
      return 0;
    }
  }
  
  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
          
      // Update local count
      _unreadCount = (_unreadCount > 0) ? _unreadCount - 1 : 0;
    } catch (e) {
      developer.log(
        'Error marking notification as read',
        name: 'BookMatch.NotificationService',
        error: e,
        level: 1000,
      );
    }
  }
  
  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) {
      return;
    }
    
    try {
      final batch = _firestore.batch();
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .get();
          
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      _unreadCount = 0;
    } catch (e) {
      developer.log(
        'Error marking all notifications as read',
        name: 'BookMatch.NotificationService',
        error: e,
        level: 1000,
      );
    }
  }
  
  // Create a new notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'relatedId': relatedId,
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Show local notification
      await _showLocalNotification(title, body, type: type, data: data);
    } catch (e) {
      developer.log(
        'Error creating notification',
        name: 'BookMatch.NotificationService',
        error: e,
        level: 1000,
      );
    }
  }
  
  // Create a new chat message notification
  Future<void> createChatNotification({
    required String receiverId,
    required String senderId,
    required String senderName,
    required String message,
    required String chatId,
    required String bookTitle,
  }) async {
    final title = 'New message from $senderName';
    final body = message.length > 50 ? '${message.substring(0, 47)}...' : message;
    
    await createNotification(
      userId: receiverId,
      title: title,
      body: body,
      type: 'chat',
      relatedId: chatId,
      data: {
        'senderId': senderId,
        'senderName': senderName,
        'chatId': chatId,
        'bookTitle': bookTitle,
      },
    );
  }
  
  // Create a new match notification
  Future<void> createMatchNotification({
    required String userId,
    required String matchedUserId,
    required String matchedUserName,
    required String bookTitle,
    required String chatId,
  }) async {
    final title = 'New Book Match!';
    final body = 'You matched with $matchedUserName over "$bookTitle"';
    
    await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'match',
      relatedId: chatId,
      data: {
        'matchedUserId': matchedUserId,
        'matchedUserName': matchedUserName,
        'bookTitle': bookTitle,
        'chatId': chatId,
      },
    );
  }
  
  // Create trade completed notification
  Future<void> createTradeCompletedNotification({
    required String userId,
    required String otherUserId,
    required String otherUserName,
    required String bookTitle,
    required String chatId,
  }) async {
    final title = 'Trade Completed!';
    final body = 'Your book swap with $otherUserName for "$bookTitle" has been marked as complete';
    
    await createNotification(
      userId: userId,
      title: title,
      body: body,
      type: 'trade_completed',
      relatedId: chatId,
      data: {
        'otherUserId': otherUserId,
        'otherUserName': otherUserName,
        'bookTitle': bookTitle,
        'chatId': chatId,
      },
    );
  }
  
  // Show local notification
  Future<void> _showLocalNotification(String title, String body, {String? type, Map<String, dynamic>? data}) async {
    const androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'book_match_channel',
      'Book Match Notifications',
      channelDescription: 'Notifications for BookMatch app',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const iOSPlatformChannelSpecifics = DarwinNotificationDetails();
    
    const platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    // Create payload with type and data
    final Map<String, dynamic> payload = {
      'type': type ?? 'general',
      'data': data ?? {},
    };
    
    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: json.encode(payload),
    );
  }
  
  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      developer.log(
        'Error deleting notification',
        name: 'BookMatch.NotificationService',
        error: e,
        level: 1000,
      );
    }
  }
} 