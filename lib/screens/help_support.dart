import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({Key? key}) : super(key: key);

  @override
  _HelpSupportPageState createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _appVersion = '';
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSending = false;

  List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How does BookMatch work?',
      'answer': 'BookMatch helps you find and trade books with other users. '
          'Simply add books to your collection, browse available books, and request trades. '
          'When both users agree, you can arrange to exchange books in person or by mail.'
    },
    {
      'question': 'How do I add books to my collection?',
      'answer': 'Go to the "My Books" tab and tap the "+" button. You can add books by '
          'scanning the barcode, searching by title/author, or entering details manually.'
    },
    {
      'question': 'Is BookMatch free to use?',
      'answer': 'Yes! BookMatch is completely free to use. We believe in promoting reading '
          'and building a community of book lovers without any subscription fees.'
    },
    {
      'question': 'How are trades arranged?',
      'answer': 'When you request a trade and it\'s accepted, you\'ll receive contact information '
          'for the other user. You can then arrange to meet in person or mail the books. '
          'BookMatch provides a chat feature to help you coordinate the details.'
    },
    {
      'question': 'What if I have a problem with a trade?',
      'answer': 'If you encounter any issues with a trade, we recommend first trying to resolve it '
          'directly with the other user through our chat feature. If that doesn\'t work, '
          'you can report the issue through our support form on this page.'
    },
    {
      'question': 'Can I trade internationally?',
      'answer': 'BookMatch allows international trades, but keep in mind that shipping costs '
          'and customs may apply. We recommend setting your search preferences to find '
          'users in your local area for easier exchanges.'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      print('Error loading app version: $e');
      setState(() {
        _appVersion = 'Unknown';
      });
    }
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      Map<String, dynamic>? userData;
      if (userDoc.exists) {
        userData = userDoc.data() as Map<String, dynamic>?;
      }

      await _firestore.collection('support_tickets').add({
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'userName': userData?['name'] ?? 'Unknown',
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'open',
        'createdAt': FieldValue.serverTimestamp(),
        'appVersion': _appVersion,
        'deviceInfo': {
          'platform': Theme.of(context).platform.toString(),
        },
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your support request has been submitted. We\'ll get back to you soon.'),
          backgroundColor: Colors.green,
        ),
      );

      _subjectController.clear();
      _messageController.clear();

    } catch (e) {
      print('Error submitting support request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send support request. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _openEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@bookmatch.com',
      queryParameters: {
        'subject': _subjectController.text,
        'body': _messageController.text,
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not launch email app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ..._faqItems.map((item) => ExpansionTile(
              title: Text(item['question']),
              children: [Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(item['answer']),
              )],
            )),
            const Divider(height: 32),
            Text(
              'Need More Help?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Subject',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter a subject'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 5,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Please enter your message'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _submitSupportRequest,
                          icon: _isSending
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.send),
                          label: Text(_isSending ? 'Sending...' : 'Submit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.email_outlined),
                        tooltip: 'Send via Email',
                        onPressed: _openEmail,
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('App Version: $_appVersion', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
