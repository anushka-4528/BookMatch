import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'book_card.dart';
import '../models/book.dart';
import 'match_popup.dart';
import '../widgets/gradient_background.dart';
import '../widgets/action_buttons.dart';
import '../widgets/gradient_button_widget.dart';

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

  // Define the deep lilac color palette
  static const Color lilacPrimary = Color(0xFF6A0DAD); // Deeper lilac
  static const Color lilacLight = Color(0xFFE6D9F2);
  static const Color lilacDark = Color(0xFF4A0873);
  static const Color accentColor = Color(0xFFFF8FB1); // Light pink accent
  static const Color textColor = Color(0xFF2E1A47);

  final List<Book> books = [
    Book(
      id: '1',
      title: 'Dune',
      imageUrl: 'assets/images/dune_book.jpeg',
      condition: 'Good',
      genre: 'Science Fiction',
      description: 'Set on the desert planet Arrakis, Dune is the story of the boy Paul Atreides, heir to a noble family tasked with ruling an inhospitable world where the only thing of value is the "spice" melange, a drug capable of extending life and enhancing consciousness. When his family is betrayed, the destruction of Pauls family sets him on a journey toward a destiny greater than he could ever have imagined. Dune tackles complex themes of politics, religion, ecology, technology, and human emotion as the fate of characters are decided against a backdrop of a harsh and merciless universe.',
    ),
    Book(
      id: '2',
      title: 'Gone Girl',
      imageUrl: 'assets/images/gone_girl_book.webp',
      condition: 'Excellent',
      genre: 'Mystery',
      description: 'On a warm summer morning in North Carthage, Missouri, it is Nick and Amy Dunnes fifth wedding anniversary. Presents are being wrapped and reservations are being made when Nicks clever and beautiful wife disappears. Under mounting pressure from the police and the media—as well as Amys fiercely doting parents—the town golden boy parades an endless series of lies, deceits, and inappropriate behavior. Nick is oddly evasive, and hes definitely bitter—but is he really a killer? As the cops close in, every couple in town is soon wondering how well they know the one that they love.',
    ),
    Book(
      id: '3',
      title: 'The Hobbit',
      imageUrl: 'assets/images/hobbit_book.jpeg',
      condition: 'Fair',
      genre: 'Fantasy',
      description: 'Bilbo Baggins is a hobbit who enjoys a comfortable, unambitious life, rarely traveling any farther than his pantry or cellar. But his contentment is disturbed when the wizard Gandalf and a company of dwarves arrive on his doorstep one day to whisk him away on an adventure. They have launched a plot to raid the treasure hoard guarded by Smaug the Magnificent, a large and very dangerous dragon. Bilbo reluctantly joins their quest, unaware that on his journey to the Lonely Mountain he will encounter both a magic ring and a frightening creature known as Gollum.',
    ),
  ];

  final CardSwiperController controller = CardSwiperController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onSwipe(int index, int? previousIndex, CardSwiperDirection direction) async {
    // Update current index
    if (previousIndex != null && index < books.length) {
      setState(() {
        _currentIndex = index;
        _isExpanded = false;
      });
    }

    if (direction == CardSwiperDirection.right) {
      // simulate a match if user swipes right
      showDialog(
        context: context,
        builder: (context) => const MatchPopup(),
      );
    }
    return true; // allow the swipe to happen
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
  }

  // Enhanced drawer with lighter colors
  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF9F5FF)],  // Lighter background
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lilacPrimary.withOpacity(0.85),  // Lighter lilac primary
                    lilacDark.withOpacity(0.85),     // Lighter lilac dark
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.white, Colors.white],  // Brighter white
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
                    const SizedBox(height: 10),
                    const Text(
                      'Hello, Book Lover!\nFind your next favorite book',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,  // Pure white for better visibility
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(Icons.home, 'Home', () {
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.favorite, 'My Matches', () {
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.book, 'My Books', () {
                    Navigator.pop(context);
                    // Navigate to My Books page if needed
                  }),
                  const Divider(color: Color(0xFFE9DDFF)),  // Lighter divider color
                  _buildDrawerItem(Icons.settings, 'Settings', () {
                    Navigator.pop(context);
                  }),
                  _buildDrawerItem(Icons.help_outline, 'Help & Support', () {
                    Navigator.pop(context);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create consistent drawer items with a lighter feel
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: lilacPrimary.withOpacity(0.85)),  // Slightly lighter icon
      title: Text(
        title,
        style: TextStyle(
          color: textColor.withOpacity(0.9),  // Slightly lighter text
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),  // More padding
      hoverColor: lilacLight.withOpacity(0.3),  // Lighter hover effect
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: _buildDrawer(),
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
                    color: lilacPrimary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.menu, color: lilacPrimary, size: 24),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [lilacPrimary, lilacDark],
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
          IconButton(
            icon: const Icon(Icons.chat, color: lilacPrimary),
            onPressed: () {
              // handle action
            },
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: _showSwipeView ? _buildSwipeView() : _buildChatView(),
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: lilacPrimary.withOpacity(0.2),
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
          selectedItemColor: lilacPrimary,
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
    return Column(
      children: [
        const SizedBox(height: 10),
        // Status indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Book ${_currentIndex + 1} of ${books.length}',
                style: const TextStyle(
                  color: lilacDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: List.generate(
                  books.length,
                      (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex ? lilacPrimary : lilacLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Card swiper
        Expanded(
          child: Stack(
            children: [
              CardSwiper(
                controller: controller,
                cardsCount: books.length,
                onSwipe: _onSwipe,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  return _buildBookCard(books[index], index);
                },
              ),
              // Bottom controls removed
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookCard(Book book, int index) {
    // Check if this is the current card
    bool isCurrentCard = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          // Toggle expanded state when tapped
          _isExpanded = !_isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: lilacPrimary.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Book image area
            Expanded(
              flex: _isExpanded && isCurrentCard ? 3 : 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      book.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                          stops: const [0.6, 1.0],
                        ),
                      ),
                    ),
                    // Book title and genre
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 3,
                                  color: Colors.black45,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: lilacPrimary.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              book.genre,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
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
            // Book details area - Always show expanded when tapped
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isExpanded && _currentIndex == index ? 300 : 100,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: lilacLight.withOpacity(0.5),
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: lilacLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Condition: ${book.condition}',
                          style: TextStyle(
                            color: lilacDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: AnimatedRotation(
                          turns: _isExpanded && _currentIndex == index ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_down,
                            color: lilacDark,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isExpanded && _currentIndex == index)
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About this book:',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              book.description,
                              style: TextStyle(
                                color: textColor.withOpacity(0.8),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_isExpanded || _currentIndex != index)
                    Text(
                      'Tap to read more',
                      style: TextStyle(
                        color: lilacPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: lilacLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: lilacPrimary.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: lilacPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Your Chats',
            style: TextStyle(
              color: lilacDark,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'No chats yet! Start swiping to find matches and begin conversations about books you love.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedIndex = 0;
                _showSwipeView = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: lilacPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 5,
              shadowColor: lilacPrimary.withOpacity(0.5),
            ),
            child: const Text(
              'Start Swiping',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}