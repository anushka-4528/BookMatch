BookMatch
BookMatch is a modern Flutter app for book lovers to swap, match, and trade books with others. It features a beautiful, unified lilac-themed UI, real-time notifications, chat, and a robust book management system.
Features
User Authentication: Secure sign up and login with Firebase Auth.
Book Swapping & Matching: Swipe through available books, match with other users, and propose trades.
Personal Library: Add, edit, and manage your own book collection.
Real-Time Chat: Chat with users after matching to arrange swaps.
Notification System: Receive local and push notifications for matches, messages, and trade updates.
Trade Management: View, accept, or decline trade requests.
Modern UI/UX: Unified lilac color palette, gradients, and creative, accessible design.
Help & Support: Access FAQs and contact support from within the app.
Getting Started
Prerequisites
Flutter SDK (3.7.2 or higher)
Firebase Project
Android Studio or VS Code
Installation
Project Structure
lib/main.dart - App entry point and theme setup.
lib/screens/ - All UI screens (Home, Auth, Books, Trades, Chat, Notifications, etc.).
lib/services/ - Business logic and integrations (auth, notifications, chat, etc.).
lib/models/ - Data models (Book, User, Chat, Message).
lib/utils/theme.dart - Centralized theme and color palette.
assets/images/ - Book cover images and other assets.

Theming
BookMatch uses a unified lilac color palette for a modern, accessible look. All screens use the centralized theme in lib/utils/theme.dart:
Primary Color: !#9932CC #9932CC
Lilac Light: !#E6D9F2 #E6D9F2
Lilac Dark: !#4A0873 #4A0873
Accent Color: !#FF8FB1 #FF8FB1
Text Color: !#2E1A47 #2E1A47

User Guide
1. Sign Up / Login
   Launch the app and sign up with your email and password.
   Log in to access your personalized book swapping experience.
2. Home (Book Swiping)
   Swipe through available books from other users.
   Tap a book for details or to propose a match.
3. My Books
   View your personal library.
   Add new books with cover images, genre, and description.
   Edit or delete your books at any time.
4. Matches
   See users who have matched with you for a book swap.
   Start a chat or propose a trade.
5. Trades
   View all your trade requests.
   Accept, decline, or complete trades.
6. Chat
   Real-time chat with matched users.
   Receive notifications for new messages.
7. Notifications
   Get notified about new matches, messages, and trade updates.
   Swipe to delete notifications or mark all as read.
8. Help & Support
   Access FAQs and contact support for assistance.
   Notifications
   Types: Chat, Match, Trade Completed, General.
   Badge: Unread notification count is shown on the HomePage.
   Actions: Tap to navigate, swipe to delete, or mark all as read.

Credits
Built with Flutter
Uses Firebase for backend services
