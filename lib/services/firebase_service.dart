import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Future<String> uploadImage(File imageFile) async {
    String fileId = const Uuid().v4();
    final ref = _storage.ref().child('book_images').child('$fileId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  static Future<void> uploadBook(Book book) async {
    await _firestore.collection('books').doc(book.id).set(book.toMap());
  }
}
