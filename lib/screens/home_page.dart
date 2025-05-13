import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer; // Import for more detailed logging
import 'dart:async'; // Import for StreamSubscription
import '../models/book.dart';
import '../models/message_model.dart';
import 'match_popup.dart';
import '../widgets/gradient_background.dart';
import '../widgets/action_buttons.dart';
import '../widgets/gradient_button_widget.dart';
import 'matches_screen.dart';
import 'add_book_screen.dart';
import 'my_books_screen.dart';
import 'trades_screen.dart';
import 'settings.dart';
import 'help_support.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import '../models/chat_model.dart';
import '../utils/theme.dart';
import '../services/chat_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/notification_service.dart';
import 'notifications_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExpanded = false;
  int _currentIndex = 0;
  late AnimationController _animationController;
  bool _showSwipeView = true;
  bool _isLoading = true;
  String _errorMessage = '';
  List<BookModel> books = [];
  var _matchedUser; // Allow reassignment
  final ChatService _chatService = ChatService();
  final NotificationService _notificationService = NotificationService();
  int _unreadNotifications = 0;
  StreamSubscription? _notificationSubscription;

  // Define the deep lilac color palette
  static const Color primaryColor = Color(0xFF9932CC);
  static const Color lilacLight = Color(0xFFE6D9F2);
  static const Color lilacDark = Color(0xFF4A0873);
  static const Color accentColor = Color(0xFFFF8FB1); // Light pink accent
  static const Color textColor = Color(0xFF2E1A47);

  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Load books with retry mechanism
    _loadBooksWithRetry();
    
    // Check for unread notifications
    _checkUnreadNotifications();
  }

  Future<void> _loadBooksWithRetry({int retryCount = 3}) async {
    for (int i = 0; i < retryCount; i++) {
      try {
        await _loadBooks();
        return;
      } catch (e) {
        if (i == retryCount - 1) {
          _handleError(e);
        } else {
          // Wait before retrying
          await Future.delayed(Duration(seconds: i + 1));
        }
      }
    }
  }

  void _handleError(dynamic error) {
    developer.log(
      'Error in HomePage',
      name: 'BookMatch.HomePage',
      error: error,
      level: 1000,
    );

    String errorMsg = 'Unable to load books. Please check your connection.';

    if (error is FirebaseException) {
      errorMsg = 'Firebase Error: ${error.message ?? 'Unknown error'}';
    } else if (error is TimeoutException) {
      errorMsg = 'Connection timed out. Please check your internet connection.';
    }

    setState(() {
      _isLoading = false;
      _errorMessage = errorMsg;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _loadBooksWithRetry(),
          ),
        ),
      );
    }
  }

  Future<void> _loadBooks() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      developer.log(
        'Fetching books for user: ${currentUser.uid}',
        name: 'BookMatch.HomePage',
        level: 500,
      );

      final snapshot = await FirebaseFirestore.instance
          .collection('books')
          .where('available', isEqualTo: true)
          .where('ownerId', isNotEqualTo: currentUser.uid)
          .orderBy('ownerId')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Connection timed out while fetching books'),
      );

      if (!mounted) return;

      final loadedBooks = snapshot.docs.map((doc) => BookModel.fromDocument(doc)).toList();

      setState(() {
        books = loadedBooks;
        _isLoading = false;
      });

      developer.log(
        'Successfully loaded ${books.length} books',
        name: 'BookMatch.HomePage',
        level: 500,
      );
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final count = await _notificationService.getUnreadCount();
      setState(() {
        _unreadNotifications = count;
      });
      
      // Set up listener for notifications
      _notificationSubscription = _notificationService
          .getNotificationsStream()
          .listen((_) async {
        final newCount = await _notificationService.getUnreadCount();
        setState(() {
          _unreadNotifications = newCount;
        });
      });
    } catch (e) {
      developer.log(
        'Error checking notifications',
        name: 'BookMatch.HomePage',
        error: e,
        level: 1000,
      );
    }
  }
  
  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    ).then((_) {
      // Refresh count when returning from notifications
      _checkUnreadNotifications();
    });
  }

  Future<void> _handleMatch(BookModel swipedBook) async {
    try {
      if (!mounted) return;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Found a match!'),
          duration: Duration(seconds: 1),
          backgroundColor: primaryColor,
        ),
      );

      // Get matched user name first
      String matchedUserName = 'Book Owner'; // Default name if we can't fetch
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(swipedBook.ownerId)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['name'] != null) {
            matchedUserName = userData['name'];
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching matched user name',
          name: 'BookMatch.HomePage',
          error: e,
          level: 1000,
        );
      }

      // Create a UserModel for the matched user
      final matchedUser = UserModel(
        id: swipedBook.ownerId,
        name: matchedUserName,
        email: '',
      );
      
      setState(() {
        _matchedUser = matchedUser;
      });

      // Generate a simple chat ID
      final currentUser = FirebaseAuth.instance.currentUser!;
      final chatId = 'chat_${currentUser.uid}_${matchedUser.id}_${swipedBook.id}';
      
      // Create chat document if it doesn't exist
      await _chatService.createOrUpdateChat(
        ChatModel(
          chatId: chatId,
          participants: [currentUser.uid, matchedUser.id],
          lastMessage: 'Started a chat about ${swipedBook.title}',
          lastMessageTime: DateTime.now(),
          bookTitle: swipedBook.title,
          otherUserId: matchedUser.id,
          otherUserName: matchedUser.name,
        ),
      );
      
      // Get current user name
      String currentUserName = "User";
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
            
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['name'] != null) {
            currentUserName = userData['name'];
          }
        }
      } catch (e) {
        developer.log(
          'Error fetching current user name',
          name: 'BookMatch.HomePage',
          error: e,
          level: 1000,
        );
      }
      
      // Send match notification to matched user
      await _notificationService.createMatchNotification(
        userId: matchedUser.id,
        matchedUserId: currentUser.uid,
        matchedUserName: currentUserName,
        bookTitle: swipedBook.title,
        chatId: chatId,
      );
      
      // Send match notification to current user
      await _notificationService.createMatchNotification(
        userId: currentUser.uid,
        matchedUserId: matchedUser.id,
        matchedUserName: matchedUser.name,
        bookTitle: swipedBook.title,
        chatId: chatId,
      );

      if (!mounted) return;

      // Show match popup
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MatchPopup(
          matchedUser: matchedUser,
          matchedBook: swipedBook,
          onChatNow: () {
            Navigator.pop(context);
            _navigateToChat(matchedUser, chatId, swipedBook.title);
          },
          onDismiss: () {
            Navigator.pop(context);
          },
        ),
      );
    } catch (e) {
      developer.log(
        'Error in simplified match: $e',
        name: 'BookMatch.HomePage',
        error: e,
        level: 1000,
      );

      if (!mounted) return;

      // Skip error message to user since we're going to simplify
      _navigateToChat(
        UserModel(
          id: swipedBook.ownerId, 
          name: 'Book Owner',
          email: ''
        ), 
        'chat_${FirebaseAuth.instance.currentUser!.uid}_${swipedBook.ownerId}_${swipedBook.id}', 
        swipedBook.title
      );
    }
  }

  void _navigateToChat(UserModel matchedUser, String chatId, String bookTitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          matchedUser: matchedUser,
          chatId: chatId,
          bookTitle: bookTitle,
        ),
      ),
    );
  }

  Future<bool> _onSwipe(int previousIndex, CardSwiperDirection direction) async {
    if (previousIndex >= books.length) return false;

    setState(() {
      _currentIndex = previousIndex;
      _isExpanded = false;
    });

    if (direction == CardSwiperDirection.right) {
      await _handleMatch(books[previousIndex]);
    }

    return true;
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _showSwipeView = index == 0;
    });

    // Navigate to matches screen when chat tab is selected
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const MatchesScreen(),
        ),
      );
    }
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: lilacLight.withOpacity(0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                Text(
                  'Hey there, book lover 📚',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A4FCF),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Ready to swap stories today?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A84B7),
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.home, 'Home', () {
            Navigator.pop(context);
          }),
          _buildDrawerItem(Icons.favorite, 'My Matches', () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const MatchesScreen(),
              ),
            );
          }),
          _buildDrawerItem(Icons.book, 'My Books', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyBooksScreen()),
            );
          }),
          _buildDrawerItem(Icons.swap_horiz, 'My Trades', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TradesScreen()),
            );
          }),
          const Divider(color: Color(0xFFEEE6FF)),
          _buildDrawerItem(Icons.settings, 'Settings', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          }),
          _buildDrawerItem(Icons.help_outline, 'Help & Support', () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportPage()),
            );
          }),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close drawer
              await FirebaseAuth.instance.signOut(); // Sign out
              Navigator.of(context).pushReplacementNamed('/login'); // Navigate to login page
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: primaryColor.withOpacity(0.8)),
      title: Text(
        title,
        style: TextStyle(
          color: textColor.withOpacity(0.85),
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      hoverColor: lilacLight.withOpacity(0.25),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.menu, color: primaryColor, size: 24),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [primaryColor, lilacDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'BookMatch',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.notifications, color: primaryColor, size: 22),
                ),
                onPressed: _navigateToNotifications,
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      _unreadNotifications > 9 ? '9+' : '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: primaryColor, size: 24),
            ),
            onPressed: () {
              // Navigate to profile screen
              Navigator.pushNamed(context, '/profile');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: _isLoading
                        ? Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ).animate()
                          .scale(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      ),
                    )
                        : _buildSwipeView(),
                  ),
                ],
              ),
              if (_showSwipeView && !_isLoading && books.isNotEmpty)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: ActionButtons(
                    onNope: () => controller.swipe(CardSwiperDirection.left),
                    onLike: () => controller.swipe(CardSwiperDirection.right),
                    onSuperLike: () => controller.swipe(CardSwiperDirection.top),
                  ).animate()
                      .fadeIn(duration: const Duration(milliseconds: 500))
                      .slideY(begin: 0.2, end: 0),
                ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8F5FF)],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Swipe',
              activeIcon: Icon(Icons.swap_horiz, size: 28),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              label: 'Chat',
              activeIcon: Icon(Icons.chat_bubble, size: 28),
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 14,
          unselectedFontSize: 12,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSwipeView() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorState();
    }

    if (books.isEmpty) {
      developer.log('No books available to swipe', name: 'BookMatch.HomePage', level: 500);
      return _buildEmptyState();
    }

    return Column(
      children: [
        const SizedBox(height: 10),
        Expanded(
          child: CardSwiper(
            controller: controller,
            cardsCount: books.length,
            onSwipe: (previousIndex, currentIndex, direction) async {
              if (previousIndex < 0 || previousIndex >= books.length) {
                return false;
              }

              setState(() {
                _currentIndex = previousIndex;
                _isExpanded = false;
              });

              // Handle right swipe for matching
              if (direction == CardSwiperDirection.right) {
                await _handleMatch(books[previousIndex]);
              }

              return true;
            },
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
              // Return empty container if index is invalid
              if (index < 0 || index >= books.length) {
                return const SizedBox.shrink();
              }
              return _buildBookCard(books[index]);
            },
          ),
        ),
        if (!_isExpanded) ...[
          const SizedBox(height: 20),
          ActionButtons(
            onNope: () {
              if (books.isNotEmpty && _currentIndex < books.length) {
                controller.swipe(CardSwiperDirection.left);
              }
            },
            onLike: () {
              if (books.isNotEmpty && _currentIndex < books.length) {
                controller.swipe(CardSwiperDirection.right);
              }
            },
            onSuperLike: () {
              if (books.isNotEmpty && _currentIndex < books.length) {
                controller.swipe(CardSwiperDirection.top);
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildBookCard(BookModel book) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Book Image
              Positioned.fill(
                child: Hero(
                  tag: 'book_${book.id}',
                  child: book.imageUrl != null && book.imageUrl!.startsWith('http')
                      ? CachedNetworkImage(
                    imageUrl: book.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        color: primaryColor,
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/default_book.jpg',
                      fit: BoxFit.cover,
                    ),
                  )
                      : book.imageUrl != null
                      ? Image.asset(
                    book.imageUrl!,
                    fit: BoxFit.cover,
                  )
                      : Icon(
                    Icons.book,
                    size: 80,
                    color: primaryColor,
                  ),
                ),
              ),
              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.author,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (book.genre != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            book.genre!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Expanded description
              if (_isExpanded)
                Positioned.fill(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.author,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                            ),
                          ),
                          if (book.genre != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                book.genre!,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            book.description ?? 'No description available',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_outlined,
            size: 80,
            color: primaryColor.withOpacity(0.7),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
          const SizedBox(height: 20),
          Text(
            'No Books Available',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          const Text(
            'Check back later for new books to swap!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadBooksWithRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red.withOpacity(0.7),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)),
          const SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .slideY(begin: 0.2, end: 0),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadBooksWithRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ).animate()
              .fadeIn(duration: const Duration(milliseconds: 500))
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    _notificationSubscription?.cancel();
    super.dispose();
  }
}

// Add a floating action button that appears at the bottom of the screen
class AddBookFAB extends StatelessWidget {
  final VoidCallback onPressed;

  const AddBookFAB({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: _HomePageState.primaryColor,
        elevation: 8,
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

// Add the necessary classes for the remaining screen imports that were referenced

// MatchesScreen implementation
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<ChatModel> _chats = [];
  bool _isLoading = true;
  final ChatService _chatService = ChatService();

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Fetch active chats for the current user
      final chats = await _chatService.getActiveChatsForUser(currentUser.uid);

      setState(() {
        _chats = chats;
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error loading chats',
          name: 'BookMatch.MatchesScreen',
          error: e,
          level: 1000 // ERROR level
      );

      setState(() {
        _chats = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load matches: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
        backgroundColor: _HomePageState.primaryColor,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chats.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        itemCount: _chats.length,
        itemBuilder: (context, index) {
          final chat = _chats[index];
          return _buildChatItem(chat);
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
            Icons.people_outline,
            size: 80,
            color: _HomePageState.primaryColor.withOpacity(0.7),
          ),
          const SizedBox(height: 20),
          Text(
            'No matches yet',
            style: TextStyle(
              color: _HomePageState.lilacDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start swiping on books to find book lovers with similar interests!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _HomePageState.textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatModel chat) {
    return Dismissible(
      key: Key(chat.chatId),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Unmatch',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ],
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unmatch Confirmation'),
            content: Text(
              'Are you sure you want to unmatch with ${chat.otherUserName}?'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Unmatch'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        // Remove from local list
        setState(() {
          _chats.removeWhere((c) => c.chatId == chat.chatId);
        });
        // Here you would call a service to unmatch in the database
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unmatched with ${chat.otherUserName}'),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _HomePageState.lilacLight,
          child: Text(
            chat.otherUserName.isNotEmpty ? chat.otherUserName[0].toUpperCase() : "?",
            style: TextStyle(
              color: _HomePageState.lilacDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(chat.otherUserName),
        subtitle: Text('About: ${chat.bookTitle}'),
        trailing: Text(
          _formatTimestamp(chat.lastMessageTime),
          style: TextStyle(
            color: _HomePageState.textColor.withOpacity(0.6),
            fontSize: 12,
          ),
        ),
        onTap: () {
          // Navigate to chat screen with this user
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                matchedUser: UserModel(
                  id: chat.otherUserId,
                  name: chat.otherUserName,
                  email: '', // Email may not be available from chat model
                ),
                chatId: chat.chatId,
                bookTitle: chat.bookTitle,
              ),
            ),
          ).then((_) {
            // Refresh the list when returning from chat
            _loadChats();
          });
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// Add a placeholder implementation for the ChatScreen
class ChatScreen extends StatefulWidget {
  final UserModel matchedUser;
  final String chatId;
  final String bookTitle;

  const ChatScreen({
    super.key,
    required this.matchedUser,
    required this.chatId,
    required this.bookTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  late Stream<QuerySnapshot> _messagesStream;
  final currentUser = FirebaseAuth.instance.currentUser;
  bool _tradeCompleted = false;
  
  // Use the same color as the app theme
  final Color primaryColor = _HomePageState.primaryColor;

  @override
  void initState() {
    super.initState();
    _initChat();
    _messagesStream = _chatService.getMessagesStream(widget.chatId);
    _checkTradeStatus();
  }

  Future<void> _initChat() async {
    if (currentUser == null) {
      return;
    }

    // Create or update chat document
    await _chatService.createOrUpdateChat(
      ChatModel(
        chatId: widget.chatId,
        participants: [currentUser!.uid, widget.matchedUser.id],
        lastMessage: 'Started a chat about ${widget.bookTitle}',
        lastMessageTime: DateTime.now(),
        bookTitle: widget.bookTitle,
        otherUserId: widget.matchedUser.id,
        otherUserName: widget.matchedUser.name,
      ),
    );
  }
  
  Future<void> _checkTradeStatus() async {
    try {
      // Check if trade is marked as completed
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();
          
      if (chatDoc.exists && chatDoc.data()!.containsKey('isCompleted')) {
        setState(() {
          _tradeCompleted = chatDoc.data()!['isCompleted'] ?? false;
        });
      }
    } catch (e) {
      developer.log('Error checking trade status',
          name: 'BookMatch.ChatScreen',
          error: e,
          level: 1000
      );
    }
  }
  
  Future<void> _markTradeAsCompleted() async {
    try {
      // Update chat document to mark as completed
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'isCompleted': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Add system message
      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: "🎉 Trade marked as completed! Book swap successful.",
        senderId: "system",
        receiverId: "all",
        type: MessageType.system,
      );
      
      setState(() {
        _tradeCompleted = true;
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trade has been marked as completed!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Show rating dialog
      Future.delayed(const Duration(milliseconds: 500), _showRatingDialog);
      
    } catch (e) {
      developer.log('Error marking trade as completed',
          name: 'BookMatch.ChatScreen',
          error: e,
          level: 1000
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to mark trade as completed. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showTradeCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Trade as Complete?'),
        content: Text(
          'Confirm that you have successfully exchanged "${widget.bookTitle}" with ${widget.matchedUser.name}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markTradeAsCompleted();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm Trade'),
          ),
        ],
      ),
    );
  }
  
  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How was your experience?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate your trading experience:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    // Here you would save the rating
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMeetupOptions() {
    final locations = [
      'Local Library',
      'Campus Coffee Shop',
      'Bookstore',
      'City Park',
      'Community Center',
    ];
    
    String selectedLocation = locations.first;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Schedule Meetup',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLocation,
                    decoration: InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: locations.map((location) {
                      return DropdownMenuItem(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedLocation = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 30)),
                            );
                            if (date != null) {
                              setState(() {
                                selectedDate = date;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) {
                              setState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          
                          // Send meetup suggestion as a message
                          final message = 'Let\'s meet at $selectedLocation on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} at ${selectedTime.format(context)} for the book exchange.';
                          
                          _messageController.text = message;
                        },
                        child: const Text('Suggest Meetup'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || currentUser == null) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: message,
        senderId: currentUser!.uid,
        receiverId: widget.matchedUser.id,
        type: MessageType.text,
      );

      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      developer.log('Error sending message',
          name: 'BookMatch.ChatScreen',
          error: e,
          level: 1000 // ERROR level
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.matchedUser.name),
            Text(
              'Book: ${widget.bookTitle}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: primaryColor,
        elevation: 2,
        actions: [
          // Add calendar icon for meetup scheduling
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Schedule Meetup',
            onPressed: _showMeetupOptions,
          ),
          // Add complete trade icon
          IconButton(
            icon: Icon(
              Icons.check_circle, 
              color: _tradeCompleted ? Colors.green : Colors.white,
            ),
            tooltip: 'Mark as Complete',
            onPressed: _tradeCompleted ? null : _showTradeCompletionDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Completed trade indicator
          if (_tradeCompleted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.green.shade50,
              width: double.infinity,
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Trade Completed! 🎉',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          // Messages area
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: _HomePageState.lilacLight,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(
                            color: _HomePageState.lilacDark,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation about "${widget.bookTitle}"',
                          style: TextStyle(
                            color: _HomePageState.textColor.withOpacity(0.7),
                            fontSize: 14,
                          ),
                        ),
                        // Quick suggestions
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildSuggestionChip("Hi! When can we meet for the book swap?"),
                            _buildSuggestionChip("Is the book still available?"),
                            _buildSuggestionChip("I'm excited to trade this book!"),
                          ],
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom on load
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == currentUser?.uid;
                    final isSystem = message['senderId'] == 'system';

                    if (isSystem) {
                      return _buildSystemMessage(message['text']);
                    }

                    return _buildMessageBubble(
                      message['text'],
                      isMe,
                      DateTime.fromMillisecondsSinceEpoch(
                        message['timestamp'].millisecondsSinceEpoch,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Message input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                // Quick responses button
                IconButton(
                  icon: Icon(Icons.format_quote, color: primaryColor),
                  onPressed: _showQuickResponses,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _HomePageState.lilacLight.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      maxLines: null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [_HomePageState.primaryColor, _HomePageState.lilacDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _HomePageState.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: _HomePageState.lilacLight,
      onPressed: () {
        _messageController.text = text;
      },
    );
  }
  
  Widget _buildSystemMessage(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _HomePageState.textColor.withOpacity(0.7),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
  
  void _showQuickResponses() {
    final suggestions = [
      'Hi! When would be a good time to meet?',
      'Would you prefer to meet at a library or coffee shop?',
      'How about meeting this weekend?',
      'Is the book still in good condition?',
      'I can meet on campus if that works for you',
      'Looking forward to our book exchange!',
    ];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(suggestions[index]),
            onTap: () {
              Navigator.pop(context);
              _messageController.text = suggestions[index];
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isMe, DateTime timestamp) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: _HomePageState.lilacLight,
              radius: 16,
              child: Text(
                widget.matchedUser.name != null && widget.matchedUser.name.isNotEmpty
                    ? widget.matchedUser.name[0].toUpperCase()
                    : "?",
                style: TextStyle(
                  color: _HomePageState.lilacDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe
                  ? primaryColor
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: isMe ? Colors.white : _HomePageState.textColor,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(timestamp),
                      style: TextStyle(
                        color: isMe
                            ? Colors.white.withOpacity(0.7)
                            : _HomePageState.textColor.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}