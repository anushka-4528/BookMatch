import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({Key? key}) : super(key: key);

  @override
  _TradesScreenState createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  bool _isLoading = true;

  List<Map<String, dynamic>> _outgoingTrades = [];
  List<Map<String, dynamic>> _incomingTrades = [];
  List<Map<String, dynamic>> _completedTrades = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTradeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTradeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load outgoing trade requests
      QuerySnapshot outgoingSnapshot = await _firestore
          .collection('trades')
          .where('requesterId', isEqualTo: currentUser.uid)
          .orderBy('requestDate', descending: true)
          .get();

      // Load incoming trade requests
      QuerySnapshot incomingSnapshot = await _firestore
          .collection('trades')
          .where('ownerId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .orderBy('requestDate', descending: true)
          .get();

      // Load completed trades
      QuerySnapshot completedSnapshot = await _firestore
          .collection('trades')
          .where('participants', arrayContains: currentUser.uid)
          .where('status', whereIn: ['completed', 'rejected', 'canceled'])
          .orderBy('lastUpdated', descending: true)
          .get();

      List<Map<String, dynamic>> outgoing = [];
      List<Map<String, dynamic>> incoming = [];
      List<Map<String, dynamic>> completed = [];

      // Process outgoing trades
      for (var doc in outgoingSnapshot.docs) {
        Map<String, dynamic> trade = doc.data() as Map<String, dynamic>;
        trade['id'] = doc.id;

        // Get book details
        if (trade['bookOfferedId'] != null) {
          DocumentSnapshot bookOffered = await _firestore
              .collection('books')
              .doc(trade['bookOfferedId'])
              .get();

          if (bookOffered.exists) {
            trade['bookOffered'] = bookOffered.data();
          }
        }

        if (trade['bookRequestedId'] != null) {
          DocumentSnapshot bookRequested = await _firestore
              .collection('books')
              .doc(trade['bookRequestedId'])
              .get();

          if (bookRequested.exists) {
            trade['bookRequested'] = bookRequested.data();
          }
        }

        // Get other user's details
        DocumentSnapshot otherUser = await _firestore
            .collection('users')
            .doc(trade['ownerId'])
            .get();

        if (otherUser.exists) {
          trade['otherUser'] = otherUser.data();
        }

        if (trade['status'] == 'pending') {
          outgoing.add(trade);
        } else {
          completed.add(trade);
        }
      }

      // Process incoming trades
      for (var doc in incomingSnapshot.docs) {
        Map<String, dynamic> trade = doc.data() as Map<String, dynamic>;
        trade['id'] = doc.id;

        // Get book details
        if (trade['bookOfferedId'] != null) {
          DocumentSnapshot bookOffered = await _firestore
              .collection('books')
              .doc(trade['bookOfferedId'])
              .get();

          if (bookOffered.exists) {
            trade['bookOffered'] = bookOffered.data();
          }
        }

        if (trade['bookRequestedId'] != null) {
          DocumentSnapshot bookRequested = await _firestore
              .collection('books')
              .doc(trade['bookRequestedId'])
              .get();

          if (bookRequested.exists) {
            trade['bookRequested'] = bookRequested.data();
          }
        }

        // Get other user's details
        DocumentSnapshot otherUser = await _firestore
            .collection('users')
            .doc(trade['requesterId'])
            .get();

        if (otherUser.exists) {
          trade['otherUser'] = otherUser.data();
        }

        incoming.add(trade);
      }

      // Process any remaining completed trades
      for (var doc in completedSnapshot.docs) {
        // Skip if we've already processed this trade
        if (completed.any((element) => element['id'] == doc.id)) {
          continue;
        }

        Map<String, dynamic> trade = doc.data() as Map<String, dynamic>;
        trade['id'] = doc.id;

        // Get book details
        if (trade['bookOfferedId'] != null) {
          DocumentSnapshot bookOffered = await _firestore
              .collection('books')
              .doc(trade['bookOfferedId'])
              .get();

          if (bookOffered.exists) {
            trade['bookOffered'] = bookOffered.data();
          }
        }

        if (trade['bookRequestedId'] != null) {
          DocumentSnapshot bookRequested = await _firestore
              .collection('books')
              .doc(trade['bookRequestedId'])
              .get();

          if (bookRequested.exists) {
            trade['bookRequested'] = bookRequested.data();
          }
        }

        // Get other user's details
        String otherUserId = trade['requesterId'] == currentUser.uid
            ? trade['ownerId']
            : trade['requesterId'];

        DocumentSnapshot otherUser = await _firestore
            .collection('users')
            .doc(otherUserId)
            .get();

        if (otherUser.exists) {
          trade['otherUser'] = otherUser.data();
        }

        completed.add(trade);
      }

      setState(() {
        _outgoingTrades = outgoing;
        _incomingTrades = incoming;
        _completedTrades = completed;
        _isLoading = false;
      });

    } catch (e) {
      print('Error loading trade data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToTradeRequest(String tradeId, String response) async {
    try {
      await _firestore.collection('trades').doc(tradeId).update({
        'status': response,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (response == 'accepted') {
        // Handle book ownership transfer logic here
        DocumentSnapshot tradeDoc = await _firestore
            .collection('trades')
            .doc(tradeId)
            .get();

        if (tradeDoc.exists) {
          Map<String, dynamic> tradeData = tradeDoc.data() as Map<String, dynamic>;

          // Update book ownerships
          if (tradeData['bookOfferedId'] != null) {
            await _firestore.collection('books').doc(tradeData['bookOfferedId']).update({
              'ownerId': tradeData['ownerId'],
              'availableForTrade': false,
            });
          }

          if (tradeData['bookRequestedId'] != null) {
            await _firestore.collection('books').doc(tradeData['bookRequestedId']).update({
              'ownerId': tradeData['requesterId'],
              'availableForTrade': false,
            });
          }

          // Create notifications for both users
          await _firestore.collection('notifications').add({
            'userId': tradeData['requesterId'],
            'type': 'trade_accepted',
            'tradeId': tradeId,
            'message': 'Your trade request has been accepted!',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          await _firestore.collection('notifications').add({
            'userId': tradeData['ownerId'],
            'type': 'trade_completed',
            'tradeId': tradeId,
            'message': 'Trade completed successfully!',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else if (response == 'rejected') {
        // Create notification for requester
        DocumentSnapshot tradeDoc = await _firestore
            .collection('trades')
            .doc(tradeId)
            .get();

        if (tradeDoc.exists) {
          Map<String, dynamic> tradeData = tradeDoc.data() as Map<String, dynamic>;

          await _firestore.collection('notifications').add({
            'userId': tradeData['requesterId'],
            'type': 'trade_rejected',
            'tradeId': tradeId,
            'message': 'Your trade request has been declined.',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      // Reload trade data
      _loadTradeData();

    } catch (e) {
      print('Error responding to trade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process trade response. Please try again.'))
      );
    }
  }

  Future<void> _cancelTradeRequest(String tradeId) async {
    try {
      await _firestore.collection('trades').doc(tradeId).update({
        'status': 'canceled',
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Create notification for owner
      DocumentSnapshot tradeDoc = await _firestore
          .collection('trades')
          .doc(tradeId)
          .get();

      if (tradeDoc.exists) {
        Map<String, dynamic> tradeData = tradeDoc.data() as Map<String, dynamic>;

        await _firestore.collection('notifications').add({
          'userId': tradeData['ownerId'],
          'type': 'trade_canceled',
          'tradeId': tradeId,
          'message': 'A trade request has been canceled.',
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Reload trade data
      _loadTradeData();

    } catch (e) {
      print('Error canceling trade: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel trade request. Please try again.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Trades'),
        backgroundColor: Colors.purple,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Incoming (${_incomingTrades.length})'),
            Tab(text: 'Outgoing (${_outgoingTrades.length})'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple))
          : RefreshIndicator(
        onRefresh: _loadTradeData,
        color: Colors.purple,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Incoming Trades Tab
            _incomingTrades.isEmpty
                ? _buildEmptyState('No incoming trade requests')
                : _buildTradeList(_incomingTrades, 'incoming'),

            // Outgoing Trades Tab
            _outgoingTrades.isEmpty
                ? _buildEmptyState('No outgoing trade requests')
                : _buildTradeList(_outgoingTrades, 'outgoing'),

            // History Tab
            _completedTrades.isEmpty
                ? _buildEmptyState('No trade history')
                : _buildTradeList(_completedTrades, 'completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/explore');
        },
        backgroundColor: Colors.purple,
        child: Icon(Icons.swap_horiz),
        tooltip: 'Find books to trade',
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book, size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          if (message.contains('outgoing') || message.contains('incoming'))
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/explore');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Find Books to Trade'),
            ),
        ],
      ),
    );
  }

  Widget _buildTradeList(List<Map<String, dynamic>> trades, String type) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        final otherUser = trade['otherUser'] as Map<String, dynamic>?;
        final bookOffered = trade['bookOffered'] as Map<String, dynamic>?;
        final bookRequested = trade['bookRequested'] as Map<String, dynamic>?;

        String formattedDate = 'Unknown date';
        if (trade['requestDate'] != null) {
          Timestamp timestamp = trade['requestDate'] as Timestamp;
          formattedDate = DateFormat('MMM d, yyyy').format(timestamp.toDate());
        }

        return Card(
          elevation: 3,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Trade header with status
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _getStatusColor(trade['status']),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getStatusText(trade['status']),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Trade details
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.purple[100],
                          child: Text(
                            otherUser?['name']?.substring(0, 1).toUpperCase() ?? '?',
                            style: TextStyle(
                              color: Colors.purple[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherUser?['name'] ?? 'Unknown User',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              type == 'incoming'
                                  ? 'Wants to trade with you'
                                  : type == 'outgoing'
                                  ? 'You requested a trade'
                                  : 'Trade ${trade['status']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Divider(height: 32),

                    // Books being traded
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Book offered
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                type == 'incoming' ? 'Their Book' : 'Your Book',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: bookOffered?['imageUrl'] != null
                                      ? DecorationImage(
                                    image: NetworkImage(bookOffered!['imageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                ),
                                child: bookOffered?['imageUrl'] == null
                                    ? Center(child: Icon(Icons.book, size: 48, color: Colors.grey))
                                    : null,
                              ),
                              SizedBox(height: 8),
                              Text(
                                bookOffered?['title'] ?? 'Unknown Book',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                bookOffered?['author'] ?? 'Unknown Author',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Exchange icon
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 40),
                          child: Icon(
                            Icons.swap_horiz,
                            color: Colors.purple,
                            size: 32,
                          ),
                        ),

                        // Book requested
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                type == 'incoming' ? 'Your Book' : 'Their Book',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  image: bookRequested?['imageUrl'] != null
                                      ? DecorationImage(
                                    image: NetworkImage(bookRequested!['imageUrl']),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                ),
                                child: bookRequested?['imageUrl'] == null
                                    ? Center(child: Icon(Icons.book, size: 48, color: Colors.grey))
                                    : null,
                              ),
                              SizedBox(height: 8),
                              Text(
                                bookRequested?['title'] ?? 'Unknown Book',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                bookRequested?['author'] ?? 'Unknown Author',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Trade message if any
                    if (trade['message'] != null && trade['message'].toString().isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                trade['message'],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Action buttons for pending trades
                    if (type == 'incoming' && trade['status'] == 'pending')
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _respondToTradeRequest(trade['id'], 'accepted'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: Text('Accept'),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _respondToTradeRequest(trade['id'], 'rejected'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text('Decline'),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (type == 'outgoing' && trade['status'] == 'pending')
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _cancelTradeRequest(trade['id']),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: Text('Cancel Request'),
                          ),
                        ),
                      ),

                    // Contact info for accepted trades
                    if (trade['status'] == 'accepted')
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple[100]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.email, size: 18, color: Colors.purple[700]),
                                      SizedBox(width: 8),
                                      Text(
                                        otherUser?['email'] ?? 'Email not available',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  if (otherUser?['phone'] != null)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Row(
                                        children: [
                                          Icon(Icons.phone, size: 18, color: Colors.purple[700]),
                                          SizedBox(width: 8),
                                          Text(
                                            otherUser!['phone'],
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/chat',
                                    arguments: {
                                      'userId': otherUser?['id'],
                                      'userName': otherUser?['name'],
                                      'tradeId': trade['id'],
                                    },
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                icon: Icon(Icons.chat),
                                label: Text('Open Chat'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'canceled':
        return Colors. grey;
      default:
        return Colors.purple;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Declined';
      case 'canceled':
        return 'Canceled';
      default:
        return 'Unknown';
    }
  }
}