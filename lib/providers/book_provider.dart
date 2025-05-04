import 'package:flutter/material.dart';
import '../models/book.dart';
import '../services/firebase_service.dart';

class BookProvider with ChangeNotifier {
  Future<void> addBook(Book book) async {
    await FirebaseService.uploadBook(book);
    notifyListeners();
  }
}
