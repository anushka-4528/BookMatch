import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;
import '../models/book.dart';

class FirebaseService {
  // Constants
  static const String BOOKS_COLLECTION = 'books';

  // Firebase instances
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  static final CollectionReference _usersCollection = _firestore.collection('users');
  static final CollectionReference _chatsCollection = _firestore.collection('chats');
  static final CollectionReference _messagesCollection = _firestore.collection('messages');
  static final CollectionReference _booksCollection = _firestore.collection(BOOKS_COLLECTION);

  // Upload image to Firebase Storage with improved error handling
  static Future<String> uploadImage(File imageFile) async {
    try {
      // Ensure user is logged in
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated. Please log in to upload images.');
      }

      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist at path: ${imageFile.path}');
      }

      // Create a unique filename with sanitized values
      final String fileExtension = path.extension(imageFile.path).toLowerCase();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final userId = currentUser.uid;
      final String fileName = 'book-$timestamp$fileExtension';

      // IMPORTANT: Create the directory structure first
      // Use a reference with a more explicit path structure
      final storageRef = _storage.ref().child('users').child(userId).child('book_images').child(fileName);

      // Log for debugging
      print('Uploading file: ${imageFile.path}');
      print('To storage path: ${storageRef.fullPath}');
      print('File size: ${await imageFile.length()} bytes');

      // Include proper content type in metadata
      String contentType;
      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.gif':
          contentType = 'image/gif';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg'; // Default fallback
      }

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedBy': userId,
          'timestamp': timestamp,
          'appVersion': '1.0.0', // Include app version for tracking
        },
      );

      // Create an upload task with proper options and metadata
      final uploadTask = storageRef.putFile(imageFile, metadata);

      // Monitor upload state (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (error) {
        print('Upload task error: $error');
      });

      // Wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() => print('Upload completed'));

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      print('Firebase Storage error: ${e.code} - ${e.message}');

      // Provide more specific error messages based on Firebase error codes
      switch (e.code) {
        case 'storage/object-not-found':
          throw Exception('The storage location does not exist. Check your Firebase Storage rules.');
        case 'storage/unauthorized':
          throw Exception('You do not have permission to access this storage location. Check your Firebase Storage rules.');
        case 'storage/canceled':
          throw Exception('The upload was canceled.');
        case 'storage/retry-limit-exceeded':
          throw Exception('The maximum time limit on an operation was exceeded. Try again later.');
        case 'storage/invalid-checksum':
          throw Exception('File on the client does not match the checksum of the file received by the server.');
        default:
          throw Exception('Firebase Storage error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // Debug method to verify storage connectivity and create necessary folders
  static Future<bool> ensureStorageSetup() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('Warning: No authenticated user for storage setup');
        return false;
      }

      // Try to list items to verify connection and existence
      final String userId = currentUser.uid;
      final String testPath = 'users/$userId/book_images';

      try {
        // This will throw an error if the path doesn't exist, but that's okay
        final ListResult result = await _storage.ref().child(testPath).list();
        print('Storage path exists: $testPath - Found ${result.items.length} items');
      } catch (e) {
        // Path likely doesn't exist, which is normal for a new user
        print('Storage path may need to be created: $testPath');

        // We can't actually create empty folders in Firebase Storage,
        // they're created implicitly when files are uploaded
      }

      return true;
    } catch (e) {
      print('Storage setup check failed: $e');
      return false;
    }
  }

  // Add book to Firestore
  static Future<void> addBookToFirestore(BookModel book) async {
    try {
      await _booksCollection.doc(book.id).set(book.toMap());
    } catch (e) {
      throw Exception('Failed to add book to Firestore: $e');
    }
  }

  // Get all books from Firestore
  static Stream<List<BookModel>> getBooks() {
    return _booksCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => BookModel.fromDocument(doc)).toList());
  }

  // Get book by ID
  static Future<BookModel?> getBookById(String id) async {
    final doc = await _booksCollection.doc(id).get();
    if (doc.exists) {
      return BookModel.fromDocument(doc);
    }
    return null;
  }

  // Update book in Firestore
  static Future<void> updateBook(BookModel book) async {
    try {
      await _booksCollection.doc(book.id).update(book.toMap());
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  // Delete book from Firestore
  static Future<void> deleteBook(String bookId) async {
    try {
      await _booksCollection.doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Getters
  static FirebaseFirestore get firestore => _firestore;
  static FirebaseAuth get auth => _auth;
  static FirebaseStorage get storage => _storage;
  static CollectionReference get usersCollection => _usersCollection;
  static CollectionReference get chatsCollection => _chatsCollection;
  static CollectionReference get messagesCollection => _messagesCollection;
  static CollectionReference get booksCollection => _booksCollection;

  // Current user
  static User? get currentUser => _auth.currentUser;
  static String get currentUserId => currentUser?.uid ?? '';
  static bool get isUserLoggedIn => currentUser != null;

  // Timestamps
  static Timestamp get timestamp => Timestamp.now();
}