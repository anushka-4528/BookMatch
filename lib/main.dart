import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'screens/home_page.dart' hide ChatScreen;
import 'screens/add_book_screen.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup.dart';
import 'services/auth_service.dart';
import 'providers/book_provider.dart';
import 'services/chat_service.dart';
import 'services/notification_service.dart';
import 'screens/notifications_screen.dart';
import 'screens/chat_screen.dart';
import 'models/user_model.dart';
import 'dart:convert';
import 'utils/theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize the notification service
  final notificationService = NotificationService();
  
  // Set up notification tap handling
  await _setupNotifications();
  
  runApp(const BookSwipeApp());
}

Future<void> _setupNotifications() async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
      
  // Initialize notification settings
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
  
  // Handle notification taps
  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      // Handle notification tap
      final payload = response.payload;
      if (payload != null) {
        try {
          final data = json.decode(payload) as Map<String, dynamic>;
          _handleNotificationTap(data);
        } catch (e) {
          print('Error parsing notification payload: $e');
        }
      }
    },
  );
  
  // Request permission (for iOS)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
}

void _handleNotificationTap(Map<String, dynamic> data) {
  final type = data['type'];
  final notificationData = data['data'] as Map<String, dynamic>?;
  
  if (notificationData == null) {
    // If no specific data, just go to notifications screen
    Future.delayed(const Duration(milliseconds: 500), () {
      navigatorKey.currentState?.pushNamed('/notifications');
    });
    return;
  }
  
  Future.delayed(const Duration(milliseconds: 500), () {
    if (navigatorKey.currentState != null) {
      switch (type) {
        case 'chat':
          // Navigate to specific chat
          if (notificationData.containsKey('chatId') && 
              notificationData.containsKey('senderId') &&
              notificationData.containsKey('senderName') &&
              notificationData.containsKey('bookTitle')) {
            
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  matchedUser: UserModel(
                    id: notificationData['senderId'],
                    name: notificationData['senderName'],
                    email: '',
                  ),
                  chatId: notificationData['chatId'],
                  bookTitle: notificationData['bookTitle'],
                ),
              ),
            );
          } else {
            navigatorKey.currentState!.pushNamed('/notifications');
          }
          break;
          
        case 'match':
          // Navigate to specific match chat
          if (notificationData.containsKey('chatId') && 
              notificationData.containsKey('matchedUserId') &&
              notificationData.containsKey('matchedUserName') &&
              notificationData.containsKey('bookTitle')) {
            
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  matchedUser: UserModel(
                    id: notificationData['matchedUserId'],
                    name: notificationData['matchedUserName'],
                    email: '',
                  ),
                  chatId: notificationData['chatId'],
                  bookTitle: notificationData['bookTitle'],
                ),
              ),
            );
          } else {
            navigatorKey.currentState!.pushNamed('/notifications');
          }
          break;
          
        case 'trade_completed':
          // Navigate to completed trade chat
          if (notificationData.containsKey('chatId') && 
              notificationData.containsKey('otherUserId') &&
              notificationData.containsKey('otherUserName') &&
              notificationData.containsKey('bookTitle')) {
            
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) => ChatScreen(
                  matchedUser: UserModel(
                    id: notificationData['otherUserId'],
                    name: notificationData['otherUserName'],
                    email: '',
                  ),
                  chatId: notificationData['chatId'],
                  bookTitle: notificationData['bookTitle'],
                ),
              ),
            );
          } else {
            navigatorKey.currentState!.pushNamed('/notifications');
          }
          break;
          
        default:
          // Navigate to notifications screen
          navigatorKey.currentState!.pushNamed('/notifications');
          break;
      }
    }
  });
}

class BookSwipeApp extends StatelessWidget {
  const BookSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        Provider<ChatService>(create: (_) => ChatService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'Book Swipe',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomePage(),
          '/add_book': (context) => const AddBookScreen(),
          '/notifications': (context) => const NotificationsScreen(),
        },
      ),
    );
  }
}