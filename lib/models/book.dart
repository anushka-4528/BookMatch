class Book {
  final String id;
  final String title;
  final String imageUrl;
  final String condition;
  final String genre;
  final String description;

  Book({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.condition,
    required this.genre,
    required this.description,
  });

  // Convert Book to Map (for Firebase or storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'condition': condition,
      'genre': genre,
      'description': description,
    };
  }

  // Create Book from Map (e.g., from Firestore)
  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      condition: map['condition'] ?? '',
      genre: map['genre'] ?? '',
      description: map['description'] ?? '',
    );
  }
}
