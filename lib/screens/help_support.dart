import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/theme.dart';

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
  
  // App color scheme - keep consistent with the rest of the app
  static const Color primaryColor = Color(0xFF9932CC);
  static const Color lightLilac = Color(0xFFE6D9F2);
  static const Color lilacDark = Color(0xFF4A0873);

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
        const SnackBar(
          content: Text('Your support request has been submitted. We\'ll get back to you soon.'),
          backgroundColor: Colors.green,
        ),
      );

      _subjectController.clear();
      _messageController.clear();

    } catch (e) {
      print('Error submitting support request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch email app.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error launching email app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support', style: AppTheme.headingStyle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.headerGradient,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                gradient: AppTheme.headerGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Need help?', style: AppTheme.headingStyle),
                  const SizedBox(height: 8),
                  Text('We are here to support you.', style: AppTheme.bodyStyle.copyWith(color: Colors.white)),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FAQ section
                  Row(
                    children: [
                      Icon(Icons.question_answer, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: lilacDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ..._faqItems.map((item) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        item['question'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['answer'],
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  )),
                  
                  const SizedBox(height: 24),
                  
                  // Contact Us section
                  Row(
                    children: [
                      Icon(Icons.contact_support, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: lilacDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Send us a message and we\'ll get back to you as soon as possible.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _subjectController,
                              decoration: InputDecoration(
                                labelText: 'Subject',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                labelStyle: TextStyle(color: Colors.grey[700]),
                                prefixIcon: Icon(Icons.subject, color: primaryColor),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Please enter a subject'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                labelText: 'Message',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(color: primaryColor),
                                ),
                                labelStyle: TextStyle(color: Colors.grey[700]),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 5,
                              validator: (value) => value == null || value.trim().isEmpty
                                  ? 'Please enter your message'
                                  : null,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSending ? null : _submitSupportRequest,
                                    icon: _isSending
                                        ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                        : const Icon(Icons.send),
                                    label: Text(_isSending ? 'Sending...' : 'Submit Request'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: lightLilac,
                                  ),
                                  child: IconButton(
                                    icon: Icon(Icons.email_outlined, color: primaryColor),
                                    tooltip: 'Send via Email',
                                    onPressed: _openEmail,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick Links section
                  Row(
                    children: [
                      Icon(Icons.link, color: primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Links',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: lilacDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      _buildQuickLinkCard(
                        title: 'User Guide',
                        icon: Icons.menu_book,
                        onTap: () {},
                      ),
                      _buildQuickLinkCard(
                        title: 'Video Tutorials',
                        icon: Icons.play_circle_outline,
                        onTap: () {},
                      ),
                      _buildQuickLinkCard(
                        title: 'Community',
                        icon: Icons.forum,
                        onTap: () {},
                      ),
                      _buildQuickLinkCard(
                        title: 'Safety Tips',
                        icon: Icons.security,
                        onTap: () {},
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // App Info
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: lightLilac.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BookMatch',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: lilacDark,
                            ),
                          ),
                          Text(
                            'Version $_appVersion',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: const Text('Terms of Service'),
                              ),
                              const Text('•', style: TextStyle(color: Colors.grey)),
                              TextButton(
                                onPressed: () {},
                                child: const Text('Privacy Policy'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickLinkCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: primaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
