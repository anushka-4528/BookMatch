import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';

import '../services/chat_service.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/theme.dart';

class ChatScreen extends StatefulWidget {
  final UserModel matchedUser;
  final String chatId;
  final String bookTitle; // The book being traded

  const ChatScreen({
    Key? key,
    required this.matchedUser,
    required this.chatId,
    required this.bookTitle,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isTyping = false;
  Timer? _typingTimer;
  bool _showMeetupOptions = false;
  bool _tradeCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkTradeStatus();
    _markMessagesAsRead();

    // Listen for new messages to scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
      
      // Check if this is a new conversation (no messages) and show welcome message
      _showWelcomeMessageIfNeeded();
    });
  }

  void _checkTradeStatus() async {
    bool isCompleted = await _chatService.isTradeCompleted(widget.chatId);
    setState(() {
      _tradeCompleted = isCompleted;
    });
  }

  void _markMessagesAsRead() {
    _chatService.markMessagesAsRead(widget.chatId, currentUserId);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _setTypingStatus(bool isTyping) {
    _chatService.updateTypingStatus(widget.chatId, currentUserId, isTyping);
    _typingTimer?.cancel();

    if (isTyping) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatService.updateTypingStatus(widget.chatId, currentUserId, false);
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    // Send message
    await _chatService.sendMessage(
      chatId: widget.chatId,
      text: _messageController.text.trim(),
      senderId: currentUserId,
      receiverId: widget.matchedUser.id,
      type: MessageType.text,
    );

    // Clear typing status and input
    _setTypingStatus(false);
    _messageController.clear();

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _sendSystemMessage(String message) async {
    await _chatService.sendMessage(
      chatId: widget.chatId,
      text: message,
      senderId: "system",
      receiverId: "all",
      type: MessageType.system,
    );
  }

  void _markTradeAsCompleted() async {
    await _chatService.markTradeAsCompleted(widget.chatId);
    _sendSystemMessage("Trade marked as completed! 📚");
    setState(() {
      _tradeCompleted = true;
    });
  }

  void _proposeMeetup() async {
    setState(() {
      _showMeetupOptions = true;
    });
  }

  void _sendMeetupRequest(String location, DateTime time) async {
    final formattedDate = DateFormat('MMMM d, yyyy').format(time);
    final formattedTime = DateFormat('h:mm a').format(time);

    Map<String, dynamic> meetupData = {
      'location': location,
      'date': formattedDate,
      'time': formattedTime,
      'status': 'pending'
    };

    await _chatService.sendMessage(
      chatId: widget.chatId,
      text: "Let's meet at $location on $formattedDate at $formattedTime to exchange '${widget.bookTitle}'",
      senderId: currentUserId,
      receiverId: widget.matchedUser.id,
      type: MessageType.meetupResponse,
      metadata: meetupData,
    );

    setState(() {
      _showMeetupOptions = false;
    });
  }

  // Check if conversation is new and show welcome/suggestion messages
  void _showWelcomeMessageIfNeeded() async {
    final messages = await _chatService.getMessages(widget.chatId).first;
    
    if (messages.isEmpty) {
      // Add welcome message if conversation is new
      await _chatService.sendMessage(
        chatId: widget.chatId,
        text: "You've connected over \"${widget.bookTitle}\"! Start chatting to arrange a book swap.",
        senderId: "system",
        receiverId: "all",
        type: MessageType.system,
      );
      
      // Add suggestion messages
      Future.delayed(const Duration(milliseconds: 800), () async {
        await _chatService.sendMessage(
          chatId: widget.chatId,
          text: "Suggested: Hi! I'm interested in swapping \"${widget.bookTitle}\". When would be a good time to meet?",
          senderId: "suggestion",
          receiverId: currentUserId,
          type: MessageType.suggestion,
        );
      });
      
      Future.delayed(const Duration(milliseconds: 1500), () async {
        await _chatService.sendMessage(
          chatId: widget.chatId,
          text: "Tip: Use the calendar button to propose a meetup time and location.",
          senderId: "system",
          receiverId: "all",
          type: MessageType.system,
        );
      });
    }
  }

  Widget _buildMessageList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _chatService.getMessages(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              "Start your conversation about '${widget.bookTitle}'",
              style: TextStyle(color: Colors.grey[600]),
            ),
          );
        }

        List<MessageModel> messages = snapshot.data!;

        // Scroll to bottom when new messages arrive
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return ListView.builder(
          controller: _scrollController,
          itemCount: messages.length,
          padding: const EdgeInsets.symmetric(vertical: 15),
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(MessageModel message) {
    final bool isCurrentUser = message.senderId == currentUserId;
    final bool isSystemMessage = message.type == MessageType.system;
    final bool isSuggestion = message.type == MessageType.suggestion;

    if (isSystemMessage) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 12,
          ),
        ),
      );
    }
    
    if (isSuggestion) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Suggested message:',
                style: TextStyle(
                  color: Color(0xFF6A0DAD),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.text,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    _messageController.text = message.text.replaceAll("Suggested: ", "");
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Use this',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        margin: EdgeInsets.only(
          bottom: 8,
          left: isCurrentUser ? 64 : 16,
          right: isCurrentUser ? 16 : 64,
          top: 4,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(message.timestamp.toDate()),
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white70 : Colors.black54,
                    fontSize: 11,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeetupOptionsDialog() {
    final locations = [
      'Local Library',
      'City Park',
      'Campus Coffee Shop',
      'Bookstore',
      'Community Center',
    ];

    String selectedLocation = locations.first;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Schedule a Meetup',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedLocation,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: locations.map((location) {
                    return DropdownMenuItem(
                      value: location,
                      child: Text(location),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedLocation = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 30)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('MMM d, yyyy').format(selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: selectedTime,
                          );
                          if (time != null) {
                            setState(() {
                              selectedTime = time;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Icon(Icons.access_time),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        this.setState(() {
                          _showMeetupOptions = false;
                        });
                      },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        // Combine date and time
                        final meetupDateTime = DateTime(
                          selectedDate.year,
                          selectedDate.month,
                          selectedDate.day,
                          selectedTime.hour,
                          selectedTime.minute,
                        );

                        Navigator.pop(context);
                        _sendMeetupRequest(selectedLocation, meetupDateTime);
                      },
                      child: const Text('Send Request'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<bool>(
      stream: _chatService.getTypingStatus(widget.chatId, widget.matchedUser.id),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  '${widget.matchedUser.name} is typing',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Set typing status to false when leaving
    _chatService.updateTypingStatus(widget.chatId, currentUserId, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showMeetupOptions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (context) => _buildMeetupOptionsDialog(),
        );
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.matchedUser.name, style: AppTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Schedule Meetup',
            onPressed: _proposeMeetup,
          ),
          IconButton(
            icon: Icon(
              Icons.check_circle,
              color: _tradeCompleted ? Colors.green : Colors.white,
            ),
            tooltip: 'Mark as Complete',
            onPressed: _tradeCompleted 
                ? null 
                : () => _showCompletionDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_tradeCompleted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Trade Completed! 🎉',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
              ),
              child: _buildMessageList(),
            ),
          ),
          _buildTypingIndicator(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppTheme.primaryColor,
                    onPressed: _showQuickResponses,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _sendMessage,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: !_tradeCompleted ? FloatingActionButton.extended(
        onPressed: _showCompletionDialog,
        backgroundColor: Colors.green,
        icon: const Icon(Icons.check_circle),
        label: const Text('Mark Complete'),
      ) : null,
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark Trade as Complete?'),
        content: Text(
          'Confirm that you have successfully exchanged "${widget.bookTitle}" with ${widget.matchedUser.name}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _markTradeAsCompleted();
              
              // Show a rating dialog
              Future.delayed(const Duration(milliseconds: 500), () {
                _showRatingDialog();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm Trade'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How was the trading experience?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Rate your book swap experience:'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Thank you for your feedback!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.star,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickResponses() {
    final suggestions = [
      'Hi! When would be a good time to meet for the book swap?',
      'Would you prefer to meet at a library or coffee shop?',
      'How about meeting this weekend?',
      'Is the book still in good condition?',
      'I can meet on campus if that works for you',
    ];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView.separated(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        itemCount: suggestions.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(suggestions[index]),
            onTap: () {
              Navigator.pop(context);
              _messageController.text = suggestions[index];
              // Focus the text field
              FocusScope.of(context).requestFocus(FocusNode());
            },
          );
        },
      ),
    );
  }
}