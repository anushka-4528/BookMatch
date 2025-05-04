import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';



class ChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFFD8CCEE), // Light lilac
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
      ),
      home: ChatScreen(),
    );
  }
}

class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageType type;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.type = MessageType.text,
  });
}

enum MessageType { text, bookSuggestion, meetupProposal }

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  late AnimationController _backgroundAnimationController;
  late Animation<Color?> _backgroundColorAnimation;

  @override
  void initState() {
    super.initState();
    _loadInitialMessages();

    _backgroundAnimationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat(reverse: true);

    _backgroundColorAnimation = ColorTween(
      begin: Color(0xFFD8CCEE),  // Light lilac
      end: Color(0xFFE8E0FA),    // Even lighter lilac
    ).animate(_backgroundAnimationController);

    _backgroundAnimationController.forward();
  }

  void _loadInitialMessages() {
    // Sample conversation
    _messages.add(Message(
      text: "Hi there! I loved your taste in magical realism. I see you're interested in trading 'One Hundred Years of Solitude'?",
      isMe: false,
      timestamp: DateTime.now().subtract(Duration(days: 1, hours: 2)),
    ));

    _messages.add(Message(
      text: "Yes! I've read it twice and thought someone else might enjoy it. I see you have 'The Wind-Up Bird Chronicle' by Murakami?",
      isMe: true,
      timestamp: DateTime.now().subtract(Duration(days: 1, hours: 1, minutes: 45)),
    ));

    _messages.add(Message(
      text: "I do! It's one of my favorites. Would you be interested in trading?",
      isMe: false,
      timestamp: DateTime.now().subtract(Duration(days: 1, hours: 1, minutes: 30)),
    ));

    _messages.add(Message(
      text: "Absolutely! I've been wanting to read more Murakami.",
      isMe: true,
      timestamp: DateTime.now().subtract(Duration(days: 1, hours: 1)),
    ));

    _messages.add(Message(
      text: "Since we both live in Brooklyn, would you be interested in meeting at Prose & Poems Café this weekend for the exchange?",
      isMe: false,
      timestamp: DateTime.now().subtract(Duration(hours: 23)),
      type: MessageType.meetupProposal,
    ));

    _messages.add(Message(
      text: "That sounds perfect! How about Saturday around 2pm?",
      isMe: true,
      timestamp: DateTime.now().subtract(Duration(hours: 22)),
    ));

    _messages.add(Message(
      text: "Saturday at 2pm works for me! I'll bring the book in good condition with a little surprise bookmark I made.",
      isMe: false,
      timestamp: DateTime.now().subtract(Duration(hours: 21)),
    ));

    _messages.add(Message(
      text: "If you enjoy Magical Realism, you might also like 'The House of the Spirits' by Isabel Allende. I have a copy I could bring to show you.",
      isMe: false,
      timestamp: DateTime.now().subtract(Duration(hours: 20)),
      type: MessageType.bookSuggestion,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _backgroundAnimationController.dispose();
    super.dispose();
  }

  void _handleSubmitted(String text) {
    if (text.isEmpty) return;

    _textController.clear();
    setState(() {
      _isComposing = false;
      _messages.add(Message(
        text: text,
        isMe: true,
        timestamp: DateTime.now(),
      ));
    });

    // Simulate receiving a response - for demo purposes only
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(Message(
            text: "That sounds wonderful! I'm looking forward to our book exchange on Saturday. Do you have any other favorite authors?",
            isMe: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          return Scaffold(
            backgroundColor: _backgroundColorAnimation.value,
            appBar: _buildAppBar(),
            body: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      child: _buildMessageList(),
                    ),
                  ),
                ),
                _buildComposer(),
              ],
            ),
          );
        }
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: Colors.black87),
        onPressed: () {},
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=37'),
          ),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emma Wright',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Online',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.book_outlined, color: Colors.black87),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.more_vert, color: Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showTimestamp = index == 0 ||
            _messages[index].timestamp.day != _messages[index - 1].timestamp.day;

        return Column(
          children: [
            if (showTimestamp)
              _buildDateSeparator(message.timestamp),
            _buildMessageItem(message),
          ],
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime timestamp) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _formatDateSeparator(timestamp),
        style: TextStyle(
          color: Colors.black54,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDateSeparator(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(timestamp);
    }
  }

  Widget _buildMessageItem(Message message) {
    final isBookSuggestion = message.type == MessageType.bookSuggestion;
    final isMeetupProposal = message.type == MessageType.meetupProposal;

    Widget messageContent;

    if (isBookSuggestion) {
      messageContent = _buildBookSuggestion(message);
    } else if (isMeetupProposal) {
      messageContent = _buildMeetupProposal(message);
    } else {
      messageContent = _buildTextMessage(message);
    }

    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: message.isMe ? 50 : 0,
          right: message.isMe ? 0 : 50,
        ),
        child: Column(
          crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            messageContent,
            SizedBox(height: 2),
            Padding(
              padding: EdgeInsets.only(
                left: message.isMe ? 0 : 12,
                right: message.isMe ? 12 : 0,
              ),
              child: Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextMessage(Message message) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isMe
            ? Color(0xFFD8CCEE) // Light lilac for sent messages
            : Color(0xFFF2F2F7), // Light gray for received messages
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomRight: message.isMe ? Radius.circular(5) : Radius.circular(20),
          bottomLeft: message.isMe ? Radius.circular(20) : Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        message.text,
        style: TextStyle(
          color: Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _buildBookSuggestion(Message message) {
    return Container(
      width: 250,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: message.isMe ? Radius.circular(20) : Radius.circular(5),
          bottomRight: message.isMe ? Radius.circular(5) : Radius.circular(20),
        ),
        border: Border.all(color: Color(0xFFD8CCEE), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Book Suggestion",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF6A4EA1),
            ),
          ),
          SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: DecorationImage(
                    image: NetworkImage('https://i.pravatar.cc/150?img=3'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "The House of the Spirits",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Isabel Allende",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      message.text.replaceAll("The House of the Spirits", "").replaceAll("Isabel Allende", ""),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMeetupProposal(Message message) {
    return Container(
      width: 260,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE6DDFA), Color(0xFFD0C5ED)],
        ),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: message.isMe ? Radius.circular(20) : Radius.circular(5),
          bottomRight: message.isMe ? Radius.circular(5) : Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: 18,
                color: Color(0xFF6A4EA1),
              ),
              SizedBox(width: 4),
              Text(
                "Meetup Proposal",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF6A4EA1),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6A4EA1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    "Accept",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFF6A4EA1),
                    side: BorderSide(color: Color(0xFF6A4EA1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 10),
                  ),
                  child: Text(
                    "Reschedule",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: Color(0xFF6A4EA1)),
              onPressed: () {},
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(color: Colors.black45),
                    border: InputBorder.none,
                  ),
                  minLines: 1,
                  maxLines: 5,
                  onChanged: (text) {
                    setState(() {
                      _isComposing = text.isNotEmpty;
                    });
                  },
                ),
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Color(0xFF6A4EA1),
              radius: 22,
              child: IconButton(
                icon: Icon(
                  _isComposing ? Icons.send_rounded : Icons.mic_rounded,
                  color: Colors.white,
                ),
                onPressed: _isComposing
                    ? () => _handleSubmitted(_textController.text)
                    : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}