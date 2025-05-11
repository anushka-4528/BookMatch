import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _profileImageUrl;
  File? _imageFile;

  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _shareLocation = true;
  String _privacyLevel = 'public';
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPreferences();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

          setState(() {
            _nameController.text = userData['name'] ?? '';
            _bioController.text = userData['bio'] ?? '';
            _locationController.text = userData['location'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _profileImageUrl = userData['profileImageUrl'];
            _emailNotifications = userData['preferences']?['emailNotifications'] ?? true;
            _pushNotifications = userData['preferences']?['pushNotifications'] ?? true;
            _shareLocation = userData['preferences']?['shareLocation'] ?? true;
            _privacyLevel = userData['preferences']?['privacyLevel'] ?? 'public';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user data. Please try again.'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
      });
    } catch (e) {
      print('Error loading preferences: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('themeMode', _themeMode.index);
    } catch (e) {
      print('Error saving preferences: $e');
    }
  }

  Future<void> _saveUserData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        return;
      }

      // Upload image if selected
      String? imageUrl = _profileImageUrl;
      if (_imageFile != null) {
        String fileName = path.basename(_imageFile!.path);
        final storageRef = _storage.ref().child('profile_images/${currentUser.uid}/$fileName');

        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      // Update user data
      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _locationController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
        'preferences': {
          'emailNotifications': _emailNotifications,
          'pushNotifications': _pushNotifications,
          'shareLocation': _shareLocation,
          'privacyLevel': _privacyLevel,
        },
      });

      // Save local preferences
      await _savePreferences();

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully'))
      );

    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile. Please try again.'))
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image. Please try again.'))
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign out. Please try again.'))
      );
    }
  }

  Future<void> _deleteAccount() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
            'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show confirmation dialog with password
              _confirmDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm with Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Enter your password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.of(context).pop();

                setState(() {
                  _isLoading = true;
                });

                User? currentUser = _auth.currentUser;
                if (currentUser == null) {
                  return;
                }

                // Reauthenticate user
                AuthCredential credential = EmailAuthProvider.credential(
                  email: currentUser.email!,
                  password: passwordController.text,
                );

                await currentUser.reauthenticateWithCredential(credential);

                // Delete user data from Firestore
                await _firestore.collection('users').doc(currentUser.uid).delete();

                // Delete user books
                QuerySnapshot booksSnapshot = await _firestore
                    .collection('books')
                    .where('ownerId', isEqualTo: currentUser.uid)
                    .get();

                for (var doc in booksSnapshot.docs) {
                  await doc.reference.delete();
                }

                // Delete user trades
                QuerySnapshot tradesSnapshot = await _firestore
                    .collection('trades')
                    .where('participants', arrayContains: currentUser.uid)
                    .get();

                for (var doc in tradesSnapshot.docs) {
                  await doc.reference.delete();
                }

                // Delete user from Authentication
                await currentUser.delete();

                // Navigate to login
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);

              } catch (e) {
                setState(() {
                  _isLoading = false;
                });

                print('Error deleting account: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete account. Please check your password and try again.'))
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.purple,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.purple))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!) as ImageProvider
                              : _profileImageUrl != null
                              ? NetworkImage(_profileImageUrl!) as ImageProvider
                              : null,
                          child: _profileImageUrl == null && _imageFile == null
                              ? Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickImage,
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.purple,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _auth.currentUser?.email ?? '',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),
              Text(
                'Profile Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Bio field
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Location field
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),

              SizedBox(height: 32),
              Text(
                'Notification Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Email notifications
              SwitchListTile(
                title: Text('Email Notifications'),
                subtitle: Text('Receive updates and notifications via email'),
                value: _emailNotifications,
                activeColor: Colors.purple,
                onChanged: (value) {
                  setState(() {
                    _emailNotifications = value;
                  });
                },
              ),

              // Push notifications
              SwitchListTile(
                title: Text('Push Notifications'),
                subtitle: Text('Receive notifications on your device'),
                value: _pushNotifications,
                activeColor: Colors.purple,
                onChanged: (value) {
                  setState(() {
                    _pushNotifications = value;
                  });
                },
              ),

              Divider(),

              // Privacy settings
              SizedBox(height: 32),
              Text(
                'Privacy Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Share location
              SwitchListTile(
                title: Text('Share Location'),
                subtitle: Text('Allow others to see your approximate location'),
                value: _shareLocation,
                activeColor: Colors.purple,
                onChanged: (value) {
                  setState(() {
                    _shareLocation = value;
                  });
                },
              ),

              // Privacy level
              ListTile(
                title: Text('Privacy Level'),
                subtitle: Text('Control who can see your profile and books'),
                trailing: DropdownButton<String>(
                  value: _privacyLevel,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _privacyLevel = newValue;
                      });
                    }
                  },
                  items: <String>['public', 'friends', 'private']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value.capitalize()),
                    );
                  }).toList(),
                ),
              ),

              Divider(),

              // App settings
              SizedBox(height: 32),
              Text(
                'App Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Theme mode
              ListTile(
                title: Text('Theme'),
                subtitle: Text('Change app appearance'),
                trailing: DropdownButton<ThemeMode>(
                  value: _themeMode,
                  onChanged: (ThemeMode? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _themeMode = newValue;
                      });
                    }
                  },
                  items: <ThemeMode>[ThemeMode.system, ThemeMode.light, ThemeMode.dark]
                      .map<DropdownMenuItem<ThemeMode>>((ThemeMode value) {
                    return DropdownMenuItem<ThemeMode>(
                      value: value,
                      child: Text(value == ThemeMode.system
                          ? 'System'
                          : value == ThemeMode.light
                          ? 'Light'
                          : 'Dark'),
                    );
                  }).toList(),
                ),
              ),

              SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveUserData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSaving
                      ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text('Save Changes'),
                ),
              ),

              SizedBox(height: 24),

              // Account actions
              Text(
                'Account Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),

              // Sign out button
              OutlinedButton.icon(
                onPressed: _signOut,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                ),
                icon: Icon(Icons.logout),
                label: Text('Sign Out'),
              ),

              SizedBox(height: 16),

              // Delete account button
              OutlinedButton.icon(
                onPressed: _deleteAccount,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  minimumSize: Size(double.infinity, 50),
                ),
                icon: Icon(Icons.delete_forever),
                label: Text('Delete Account'),
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}