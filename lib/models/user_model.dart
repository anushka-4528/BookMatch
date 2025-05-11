import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String? photoUrl;
  final List<String> bookGenres;
  final bool isOnline;

  UserModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.bookGenres,
    required this.isOnline,
  });

  // Convert a DocumentSnapshot into a UserModel
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
      bookGenres: List<String>.from(data['bookGenres'] ?? []),
      isOnline: data['isOnline'] ?? false,
    );
  }
}
