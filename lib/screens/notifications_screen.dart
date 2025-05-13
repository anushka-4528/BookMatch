import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:developer' as developer;

import '../services/notification_service.dart';
import 'chat_screen.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _markAllAsRead();
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _notificationService.markAllAsRead();
    } catch (e) {
      developer.log(
        'Error marking all notifications as read',
        name: 'BookMatch.NotificationsScreen',
        error: e,
        level: 1000,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: AppTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: Colors.white),
            tooltip: 'Mark all as read',
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}', style: AppTheme.bodyStyle),
            );
          }

          final notifications = snapshot.data?.docs ?? [];

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              return _buildNotificationItem(notification, notificationId);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Notifications',
            style: AppTheme.headingStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'You don\'t have any notifications yet',
            style: AppTheme.bodyStyle.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification, String notificationId) {
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final type = notification['type'] ?? 'general';
    final isRead = notification['isRead'] ?? false;
    final timestamp = notification['createdAt'] as Timestamp?;
    final timeAgo = timestamp != null
        ? timeago.format(timestamp.toDate())
        : 'Just now';
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'chat':
        icon = Icons.chat_bubble;
        iconColor = Colors.blue;
        break;
      case 'match':
        icon = Icons.favorite;
        iconColor = Colors.red;
        break;
      case 'trade_completed':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppTheme.primaryColor;
    }
    
    return Dismissible(
      key: Key(notificationId),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        await _notificationService.deleteNotification(notificationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Card(
        elevation: isRead ? 0 : 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: isRead ? Colors.white : AppTheme.lilacLight.withOpacity(0.3),
        shadowColor: AppTheme.primaryColor.withOpacity(0.1),
        child: InkWell(
          onTap: () => _handleNotificationTap(notification, notificationId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withOpacity(0.1),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.subheadingStyle.copyWith(
                                fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                color: isRead ? AppTheme.textColor : Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeAgo,
                            style: AppTheme.captionStyle.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: AppTheme.bodyStyle.copyWith(
                          color: isRead ? AppTheme.textColor : Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'New',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification, String notificationId) async {
    // Mark notification as read
    if (!(notification['isRead'] ?? false)) {
      await _notificationService.markAsRead(notificationId);
    }

    final type = notification['type'] ?? 'general';
    final data = notification['data'] as Map<String, dynamic>? ?? {};

    // Navigate based on notification type
    switch (type) {
      case 'chat':
        _navigateToChat(
          chatId: data['chatId'],
          otherUserId: data['senderId'],
          otherUserName: data['senderName'],
          bookTitle: data['bookTitle'],
        );
        break;
      case 'match':
        _navigateToChat(
          chatId: data['chatId'],
          otherUserId: data['matchedUserId'],
          otherUserName: data['matchedUserName'],
          bookTitle: data['bookTitle'],
        );
        break;
      case 'trade_completed':
        _navigateToChat(
          chatId: data['chatId'],
          otherUserId: data['otherUserId'],
          otherUserName: data['otherUserName'],
          bookTitle: data['bookTitle'],
        );
        break;
      default:
        // No specific action for general notifications
        break;
    }
  }

  void _navigateToChat({
    required String chatId,
    required String otherUserId,
    required String otherUserName,
    required String bookTitle,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchedUser: UserModel(
            id: otherUserId,
            name: otherUserName,
            email: '',
          ),
          chatId: chatId,
          bookTitle: bookTitle,
        ),
      ),
    );
  }
} 