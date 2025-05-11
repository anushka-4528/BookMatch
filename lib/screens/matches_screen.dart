import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/chat_service.dart';
import '../utils/theme.dart';
import 'chat_screen.dart';
import '../models/message_model.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Your Matches',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'All Matches'),
            Tab(text: 'Recent Chats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Matches Tab
          StreamBuilder<QuerySnapshot>(
            stream: _chatService.getUserMatches(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No matches yet', 'Find book lovers with similar interests and start trading!');
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final UserModel user = UserModel.fromDocument(doc);
                  return _buildUserListTile(user, currentUserId);
                },
              );
            },
          ),

          // Recent Chats Tab
          StreamBuilder<QuerySnapshot>(
            stream: _chatService.getRecentChats(currentUserId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState('No recent chats', 'Start messaging your matches to see them here!');
              }

              final chats = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 10),
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  final chatData = chats[index].data() as Map<String, dynamic>;
                  final String otherUserId = chatData['users'].firstWhere((id) => id != currentUserId);
                  final String lastMessage = chatData['lastMessage'] ?? '';
                  final Timestamp lastMessageTime = chatData['lastMessageTime'] ?? Timestamp.now();

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const ListTile(title: Text('Loading...'));
                      }

                      final UserModel user = UserModel.fromDocument(userSnapshot.data!); // ✅ pass DocumentSnapshot

                      return _buildChatListTile(
                        user,
                        currentUserId,
                        lastMessage,
                        lastMessageTime.toDate(),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserListTile(UserModel user, String currentUserId) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 28,
          backgroundImage: user.photoUrl?.isNotEmpty == true
              ? NetworkImage(user.photoUrl!)
              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
        ),
        title: Text(
          user.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Book interests: ${user.bookGenres.take(2).join(", ")}' +
                  (user.bookGenres.length > 2 ? '...' : ''),
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.chat_bubble_outline,
                color: AppTheme.primaryColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      receiverId: user.id,
                      receiverName: user.name,
                      receiverPhotoUrl: user.photoUrl ?? '',
                    ),
                  ),
                );
              },
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'unmatch',
                  child: Row(
                    children: const [
                      Icon(Icons.close, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Unmatch'),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'unmatch') {
                  // Show confirmation dialog
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Unmatch User'),
                      content: Text('Are you sure you want to unmatch with ${user.name}? This action cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'UNMATCH',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (result == true) {
                    await _chatService.unmatchUsers(currentUserId, user.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unmatched with ${user.name}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                receiverId: user.id,
                receiverName: user.name,
                receiverPhotoUrl: user.photoUrl ?? '',
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatListTile(UserModel user, String currentUserId, String lastMessage, DateTime lastMessageTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(lastMessageTime.year, lastMessageTime.month, lastMessageTime.day);

    String timeString;
    if (today == messageDate) {
      timeString = '${lastMessageTime.hour.toString().padLeft(2, '0')}:${lastMessageTime.minute.toString().padLeft(2, '0')}';
    } else if (today.difference(messageDate).inDays == 1) {
      timeString = 'Yesterday';
    } else {
      timeString = '${lastMessageTime.day}/${lastMessageTime.month}/${lastMessageTime.year}';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user.photoUrl?.isNotEmpty == true
                  ? NetworkImage(user.photoUrl!)
                  : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
            ),
            if (user.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              timeString,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Text(
          lastMessage.length > 40 ? lastMessage.substring(0, 40) + '...' : lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[700]),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                receiverId: user.id,
                receiverName: user.name,
                receiverPhotoUrl: user.photoUrl ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}
