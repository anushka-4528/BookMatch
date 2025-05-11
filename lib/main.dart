import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_page.dart';
import 'screens/add_book_screen.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/signup.dart';
import 'services/auth_service.dart';
import 'providers/book_provider.dart';  // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const BookSwipeApp());
}

class BookSwipeApp extends StatelessWidget {
  const BookSwipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BookProvider()),  // Add BookProvider
      ],
      child: MaterialApp(
        title: 'Book Swipe',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF9b59b6),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9b59b6),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomePage(),
          '/add_book': (context) => const AddBookScreen(),
        },
      ),
    );
  }
}