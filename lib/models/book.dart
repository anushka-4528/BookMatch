import 'package:cloud_firestore/cloud_firestore.dart';

class BookModel {
  final String id;
  final String title;
  final String author;
  final String ownerId;
  final String? imageUrl;
  final String? summaryImageUrl;
  final String condition;
  final String genre;
  final String description;
  final bool available;
  final Timestamp createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.ownerId,
    this.imageUrl,
    this.summaryImageUrl,
    required this.condition,
    required this.genre,
    required this.description,
    this.available = true,
    required this.createdAt,
  });

  factory BookModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BookModel(
      id: doc.id,
      title: data['title'] ?? '',
      author: data['author'] ?? '',
      ownerId: data['ownerId'] ?? '',
      imageUrl: data['imageUrl'],
      summaryImageUrl: data['summaryImageUrl'],
      condition: data['condition'] ?? 'Good',
      genre: data['genre'] ?? 'Unknown',
      description: data['description'] ?? 'No description available.',
      available: data['available'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'ownerId': ownerId,
      'imageUrl': imageUrl,
      'summaryImageUrl':summaryImageUrl,
      'condition': condition,
      'genre': genre,
      'description': description,
      'available': available,
      'createdAt': createdAt,
    };
  }
}
