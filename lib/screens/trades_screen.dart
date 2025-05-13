import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as developer;
import '../models/chat_model.dart';
import '../models/user_model.dart';
import 'chat_screen.dart';
import '../utils/theme.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  bool _isLoading = true;
  List<ChatModel> _completedTrades = [];
  List<ChatModel> _pendingTrades = [];
  
  @override
  void initState() {
    super.initState();
    _loadTrades();
  }
  
  Future<void> _loadTrades() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('No user logged in');
      
      // Query all chats where the current user is a participant
      final querySnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: currentUser.uid)
          .get();
      
      final completed = <ChatModel>[];
      final pending = <ChatModel>[];
      
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        
        // Check if this is the current user's document
        final isCompleted = data['isCompleted'] == true;
        
        // Determine the other user
        final List<dynamic> participants = data['participants'] ?? [];
        String otherUserId = '';
        
        for (var userId in participants) {
          if (userId != currentUser.uid) {
            otherUserId = userId;
            break;
          }
        }
        
        // Get other user details (simplified version)
        String otherUserName = data['otherUserName'] ?? 'User';
        if (otherUserName.isEmpty) otherUserName = 'User';
        
        final chatModel = ChatModel(
          chatId: doc.id,
          participants: List<String>.from(participants),
          lastMessage: data['lastMessage'] ?? '',
          lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          bookTitle: data['bookTitle'] ?? 'Unknown Book',
          otherUserId: otherUserId,
          otherUserName: otherUserName,
        );
        
        if (isCompleted) {
          completed.add(chatModel);
        } else {
          pending.add(chatModel);
        }
      }
      
      setState(() {
        _completedTrades = completed;
        _pendingTrades = pending;
        _isLoading = false;
      });
      
    } catch (e) {
      developer.log(
        'Error loading trades',
        name: 'BookMatch.TradesScreen',
        error: e,
        level: 1000,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load trades: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trades', style: AppTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTradesList(),
    );
  }
  
  Widget _buildTradesList() {
    // ... update all cards and text to use AppTheme styles/colors ...
    // This is a placeholder for the actual implementation
    return ListView();
  }
}