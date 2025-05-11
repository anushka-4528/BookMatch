import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../services/firebase_service.dart';

class BookProvider with ChangeNotifier {
  List<BookModel> _books = [];
  bool _isLoading = false;
  String? _error;

  List<BookModel> get books => _books;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Add a new book
  Future<void> addBook(BookModel book) async {
    _setLoading(true);

    try {
      // First, upload the book to Firestore
      await FirebaseService.addBookToFirestore(book);

      // Add to local list
      _books.add(book);

      // Clear any previous errors
      _error = null;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error in BookProvider.addBook: $_error');
      throw e; // Re-throw to allow handling in UI
    } finally {
      _setLoading(false);
    }
  }

  // Load all books
  Future<void> loadBooks() async {
    _setLoading(true);

    try {
      // Use a Future with the stream first value for initial load
      final snapshot = await FirebaseService.booksCollection.get();
      _books = snapshot.docs.map((doc) => BookModel.fromDocument(doc)).toList();

      // Clear any previous errors
      _error = null;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error in BookProvider.loadBooks: $_error');
    } finally {
      _setLoading(false);
    }
  }

  // Update existing book
  Future<void> updateBook(BookModel updatedBook) async {
    _setLoading(true);

    try {
      await FirebaseService.updateBook(updatedBook);

      // Update in local list
      final index = _books.indexWhere((book) => book.id == updatedBook.id);
      if (index != -1) {
        _books[index] = updatedBook;
      }

      // Clear any previous errors
      _error = null;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error in BookProvider.updateBook: $_error');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Delete a book
  Future<void> deleteBook(String bookId) async {
    _setLoading(true);

    try {
      await FirebaseService.deleteBook(bookId);

      // Remove from local list
      _books.removeWhere((book) => book.id == bookId);

      // Clear any previous errors
      _error = null;

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('Error in BookProvider.deleteBook: $_error');
      throw e;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}