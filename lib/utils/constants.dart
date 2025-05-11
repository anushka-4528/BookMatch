import 'package:flutter/material.dart';

const List<String> genres = [
  'Fiction',
  'Non-Fiction',
  'Science',
  'History',
  'Biography',
  'Fantasy',
  'Mystery',
];

const List<String> conditions = [
  'New',
  'Very Good',
  'Good',
  'Fair',
  'Poor',
];

const lilacColor = Color(0xFFC8A2C8);


class Constants {
  // Routes
  static const String matchesRoute = '/matches';
  static const String chatRoute = '/chat';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String booksCollection = 'books';

  // Message Types
  static const Map<int, String> messageTypeLabels = {
    0: 'Text',
    1: 'Book Suggestion',
    2: 'Meetup Proposal'
  };

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 16.0;
  static const double defaultRadius = 20.0;
  static const double avatarRadius = 24.0;

  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Placeholder image
  static const String placeholderAvatarUrl = 'https://i.pravatar.cc/150';
  static const String placeholderBookImageUrl = 'https://via.placeholder.com/150x220?text=Book+Cover';

  // Snackbar messages
  static const String chatCreatedMessage = 'Chat created successfully';
  static const String messageSentMessage = 'Message sent';
  static const String errorMessage = 'Something went wrong. Please try again.';
  static const String unmatchSuccessMessage = 'User unmatched successfully';

  // Error messages
  static const String noUserFoundError = 'No user found with the provided ID';
  static const String chatNotFoundError = 'Chat not found';
  static const String connectionError = 'Connection error. Please check your internet connection.';

  // Empty states
  static const String emptyChatsMessage = 'No chats yet. Start matching with readers!';
  static const String emptyMessagesMessage = 'No messages yet. Say hello!';
}