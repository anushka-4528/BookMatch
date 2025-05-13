import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'chat_service.dart';

class MediaService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();

  // Pick an image from the gallery
  Future<File?> pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Upload an image to Firebase Storage and send as message
  Future<void> uploadAndSendImage(String chatId, String receiverId) async {
    final userId = _auth.currentUser!.uid;

    // Pick the image
    final File? image = await pickImage();

    if (image == null) return;

    try {
      // Generate unique file name
      final String fileName = '${const Uuid().v4()}${path.extension(image.path)}';

      // Reference to upload location
      final Reference storageRef = _storage.ref().child('chat_images/$chatId/$fileName');

      // Upload file
      final UploadTask uploadTask = storageRef.putFile(image);

      // Wait for upload to complete and get download URL
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      // Send message with image URL
      await _chatService.sendMessage(
        chatId: chatId,
        text: downloadUrl,
        senderId: userId,
        receiverId: receiverId,
        type: MessageType.image,
      );
    } catch (e) {
      print('Error uploading image: $e');
      // Handle error - perhaps show a snackbar
    }
  }

  // Delete an image from storage (for admin or cleanup purposes)
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Get reference from the URL
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}