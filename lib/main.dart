import 'package:flutter/material.dart';
import '../screens/home_page.dart';
import '../screens/add_book_screen.dart';
import '../screens/auth/login_page.dart';

void main() {
  runApp(const BookSwipeApp());
}

class BookSwipeApp extends StatelessWidget {
  const BookSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Swipe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF9b59b6), // Deep lilac
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF9b59b6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
