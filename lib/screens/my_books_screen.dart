import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/book.dart';
import 'add_book_screen.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {
  bool _isLoading = true;
  List<BookModel> userBooks = [];

  @override
  void initState() {
    super.initState();
    _loadUserBooks();
  }

  Future<void> _loadUserBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // Query Firestore for books owned by the current user
        final snapshot = await FirebaseFirestore.instance
            .collection('books')
            .where('ownerId', isEqualTo: currentUser.uid)
            .orderBy('createdAt', descending: true)
            .get();

        // Convert to BookModel objects
        final loadedBooks = snapshot.docs.map((doc) => BookModel.fromDocument(doc)).toList();

        setState(() {
          userBooks = loadedBooks;
          _isLoading = false;
        });
      } else {
        // No user is signed in - show sign in prompt or use demo mode
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to view your books'),
            backgroundColor: AppTheme.lilacDark,
          ),
        );

        // For development purposes, still show mock books
        setState(() {
          userBooks = _getMockBooks();
          _isLoading = false;
        });

        // In production, you might want to redirect to login instead
        // Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Handle errors appropriately
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading books: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      print('Error loading user books: $e');
    }
  }

  List<BookModel> _getMockBooks() {
    return [
      BookModel(
        id: '1',
        title: 'The Great Gatsby',
        author: 'F. Scott Fitzgerald',
        ownerId: 'currentUser',
        imageUrl: 'assets/images/gatsby_book.jpeg',
        condition: 'Good',
        genre: 'Classic',
        description: 'The story primarily concerns the young and mysterious millionaire Jay Gatsby and his quixotic passion and obsession with the beautiful former debutante Daisy Buchanan.',
        available: true,
        createdAt: Timestamp.now(),
      ),
      BookModel(
        id: '2',
        title: 'To Kill a Mockingbird',
        author: 'Harper Lee',
        ownerId: 'currentUser',
        imageUrl: 'assets/images/mockingbird_book.jpeg',
        condition: 'Excellent',
        genre: 'Fiction',
        description: 'The unforgettable novel of a childhood in a sleepy Southern town and the crisis of conscience that rocked it.',
        available: false, // This book is not available for matching
        createdAt: Timestamp.now(),
      ),
    ];
  }

  Widget _buildBookCard(BookModel book) {
    return GestureDetector(
      onTap: () => _showBookDetails(book),
      child: Card(
        elevation: 5,
        shadowColor: AppTheme.lilacLight.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book cover image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Book image with fallback
                    book.imageUrl != null && book.imageUrl!.startsWith('http')
                        ? Image.network(
                      book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    )
                        : book.imageUrl != null
                        ? Image.asset(
                      book.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                    )
                        : _buildPlaceholderImage(),

                    // Availability badge
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: book.available ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          book.available ? 'Available' : 'Not Available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Book info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColor.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.lilacLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        book.genre,
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.lilacDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: AppTheme.lilacLight.withOpacity(0.5),
      child: Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: AppTheme.lilacLight.withOpacity(0.7),
        ),
      ),
    );
  }

  void _showBookDetails(BookModel book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close button and actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Row(
                    children: [
                      // Toggle availability button
                      IconButton(
                        icon: Icon(
                          book.available ? Icons.visibility : Icons.visibility_off,
                          color: book.available ? Colors.green : Colors.grey,
                        ),
                        onPressed: () => _toggleBookAvailability(book),
                        tooltip: book.available ? 'Mark as unavailable' : 'Mark as available',
                      ),
                      // Edit button
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppTheme.lilacLight),
                        onPressed: () => _editBook(book),
                        tooltip: 'Edit book',
                      ),
                      // Delete button
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteBook(book),
                        tooltip: 'Delete book',
                      ),
                    ],
                  ),
                ],
              ),

              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    // Book cover
                    Center(
                      child: Container(
                        height: 200,
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: book.imageUrl != null && book.imageUrl!.startsWith('http')
                              ? Image.network(
                            book.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                          )
                              : book.imageUrl != null
                              ? Image.asset(
                            book.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                          )
                              : _buildPlaceholderImage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Book title
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Author
                    Text(
                      'by ${book.author}',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Genre and condition
                    Row(
                      children: [
                        _buildInfoChip(book.genre, Icons.category, AppTheme.lilacLight),
                        const SizedBox(width: 10),
                        _buildInfoChip('Condition: ${book.condition}', Icons.star, Colors.amber),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Created date
                    Text(
                      'Added on ${DateFormat('MMMM d, yyyy').format(book.createdAt.toDate())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textColor.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description header
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description content
                    Text(
                      book.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppTheme.textColor.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Stats section
                    const Text(
                      'Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Example stats (would be actual stats in real app)
                    _buildStatRow('Times shown', '24'),
                    _buildStatRow('Liked by others', '7'),
                    _buildStatRow('In trade requests', '2'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleBookAvailability(BookModel book) async {
    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('books')
          .doc(book.id)
          .update({'available': !book.available});

      // Reload books to reflect change
      _loadUserBooks();

      // Close the bottom sheet
      Navigator.pop(context);

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            book.available
                ? 'Book marked as unavailable'
                : 'Book is now available for matching',
          ),
          backgroundColor: AppTheme.lilacLight,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating book: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _editBook(BookModel book) {
    // Close the bottom sheet first
    Navigator.pop(context);

    // Navigate to edit book screen, passing the book to edit
    Navigator.push(
      context,
      MaterialPageRoute(
        // Fixed this line to use correct parameter name
        builder: (context) => AddBookScreen(book: book),
      ),
    ).then((_) {
      // Refresh the book list when returning
      _loadUserBooks();
    });
  }

  void _confirmDeleteBook(BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: Text('Are you sure you want to delete "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _deleteBook(book);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteBook(BookModel book) async {
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('books')
          .doc(book.id)
          .delete();

      // Close the bottom sheet
      Navigator.pop(context);

      // Reload books to reflect deletion
      _loadUserBooks();

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Book deleted successfully'),
          backgroundColor: AppTheme.lilacLight,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting book: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books', style: AppTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBooksList(),
    );
  }

  Widget _buildBooksList() {
    if (userBooks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.book_outlined,
              size: 80,
              color: AppTheme.lilacLight.withOpacity(0.7),
            ),
            const SizedBox(height: 20),
            Text(
              'No books yet',
              style: TextStyle(
                color: AppTheme.lilacDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'You haven\'t added any books to your collection yet. Tap the + button to add your first book!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textColor.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Your Collection (${userBooks.length})',
              style: TextStyle(
                color: AppTheme.lilacDark,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: userBooks.length,
              itemBuilder: (context, index) {
                final book = userBooks[index];
                return _buildBookCard(book);
              },
            ),
          ),
        ],
      ),
    );
  }
}