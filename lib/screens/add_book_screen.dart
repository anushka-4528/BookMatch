import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/book.dart';
import '../providers/book_provider.dart';
import '../services/firebase_service.dart';
import '../utils/constants.dart';
import '../widgets/gradient_button_widget.dart';
import 'package:uuid/uuid.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddBookScreen extends StatefulWidget {
  final BookModel? book; // Example: optional book for editing

  const AddBookScreen({super.key, this.book});
  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> with SingleTickerProviderStateMixin {
  File? _image;
  File? _summaryImage;
  final _titleController = TextEditingController();
  final _authorController = TextEditingController(); // Added author controller
  final _descriptionController = TextEditingController();
  String? _selectedGenre;
  String? _selectedCondition;
  bool _isLoading = false;
  bool _isProcessingImage = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _uploadTaskMessage; // Added to show more detailed loading status

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();

    // Check if user is logged in
    if (FirebaseAuth.instance.currentUser == null) {
      // Handle not logged in state - could navigate to login screen
      Future.delayed(Duration.zero, () {
        _showErrorSnackBar('You need to be logged in to add books');
        Navigator.of(context).pop(); // Return to previous screen
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _authorController.dispose(); // Dispose author controller
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Select Image Source',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9D54C2), // Slightly deeper lilac
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildSourceOption(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    source: ImageSource.camera,
                  ),
                  _buildSourceOption(
                    context,
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    source: ImageSource.gallery,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        )
            .animate()
            .slide(begin: const Offset(0, 1), end: const Offset(0, 0), duration: 300.ms, curve: Curves.easeOutQuad)
            .fadeIn(duration: 200.ms);
      },
    );

    if (source != null) {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        setState(() {
          _image = File(picked.path);
        });
      }
    }
  }

  Future<void> _pickSummaryImage() async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Capture Book Summary',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9D54C2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildSourceOption(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    source: ImageSource.camera,
                  ),
                  _buildSourceOption(
                    context,
                    icon: Icons.photo_library,
                    title: 'Gallery',
                    source: ImageSource.gallery,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        )
            .animate()
            .slide(begin: const Offset(0, 1), end: const Offset(0, 0), duration: 300.ms, curve: Curves.easeOutQuad)
            .fadeIn(duration: 200.ms);
      },
    );

    if (source != null) {
      final picked = await ImagePicker().pickImage(source: source);
      if (picked != null) {
        setState(() {
          _summaryImage = File(picked.path);
          _isProcessingImage = true; // Start processing
        });

        try {
          // Extract text from the image and update the description field
          final extractedText = await extractTextFromSummaryImage(_summaryImage!);
          setState(() {
            _descriptionController.text = extractedText;
            _isProcessingImage = false; // Processing complete
          });
        } catch (e) {
          setState(() {
            _isProcessingImage = false;
            _descriptionController.text = ''; // Reset on error
          });
          _showErrorSnackBar('Failed to extract text: ${e.toString()}');
        }
      }
    }
  }

  Widget _buildSourceOption(
      BuildContext context, {
        required IconData icon,
        required String title,
        required ImageSource source,
      }) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0E6FA), // Very light lilac
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              size: 30,
              color: const Color(0xFF9D54C2), // Deeper lilac
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<String> extractTextFromSummaryImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String extractedText = recognizedText.text;
      return extractedText;
    } finally {
      textRecognizer.close(); // Make sure resources are always released
    }
  }

  Future<void> _submit() async {
    // Validate that the user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showErrorSnackBar('You need to be logged in to add books');
      return;
    }

    // Validate required fields
    if (_image == null) {
      _showErrorSnackBar('Please add a book cover image');
      return;
    }

    if (_titleController.text.isEmpty) {
      _showErrorSnackBar('Please enter the book title');
      return;
    }

    if (_selectedGenre == null) {
      _showErrorSnackBar('Please select a genre');
      return;
    }

    if (_selectedCondition == null) {
      _showErrorSnackBar('Please select the book condition');
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadTaskMessage = 'Preparing to upload...';
    });

    try {
      // Upload the main book image
      setState(() {
        _uploadTaskMessage = 'Uploading book cover...';
      });
      final imageUrl = await FirebaseService.uploadImage(_image!);

      String? summaryImageUrl;
      // Upload the summary image if it exists
      if (_summaryImage != null) {
        setState(() {
          _uploadTaskMessage = 'Uploading summary image...';
        });
        summaryImageUrl = await FirebaseService.uploadImage(_summaryImage!);
      }

      // Create a unique ID for the book
      final id = const Uuid().v4();

      setState(() {
        _uploadTaskMessage = 'Saving book data...';
      });

      // Create the book model with all fields
      final book = BookModel(
        id: id,
        title: _titleController.text.trim(),
        imageUrl: imageUrl,
        author: _authorController.text.trim(), // Use the author controller
        ownerId: currentUser.uid, // Use the actual user ID
        summaryImageUrl: summaryImageUrl,
        genre: _selectedGenre!,
        condition: _selectedCondition!,
        description: _descriptionController.text,
        createdAt: Timestamp.now(),
      );

      // Save the book to Firestore via the provider
      await Provider.of<BookProvider>(context, listen: false).addBook(book);

      _showSuccessSnackBar();

      // Reset the form
      _titleController.clear();
      _authorController.clear();
      _descriptionController.clear();
      setState(() {
        _image = null;
        _summaryImage = null;
        _selectedGenre = null;
        _selectedCondition = null;
      });
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
        _uploadTaskMessage = null;
      });
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Text('Book Added Successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF9D54C2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // Fix for the layout overflow in AddBookScreen.dart

// Replace the _buildOptionButtons method with this improved version:
  Widget _buildOptionButtons(List<String> options, String? selected, void Function(String) onSelected) {
    return Wrap(
      spacing: 8, // Reduced spacing
      runSpacing: 8, // Reduced spacing
      children: options.map((option) {
        final isSelected = selected == option;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ChoiceChip(
            label: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF4A235A),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13, // Slightly smaller font
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            selectedColor: const Color(0xFF9D54C2),
            backgroundColor: const Color(0xFFF0E6FA),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0), // Reduced padding
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? const Color(0xFF9D54C2) : Colors.transparent,
                width: 2,
              ),
            ),
            elevation: isSelected ? 2 : 0, // Reduced elevation
            shadowColor: isSelected ? const Color(0xFF9D54C2).withOpacity(0.4) : Colors.transparent,
          ),
        )
            .animate(target: isSelected ? 1 : 0)
            .scaleXY(begin: 1, end: 1.05, duration: 200.ms)
            .then(delay: 50.ms)
            .shimmer(duration: 600.ms, color: Colors.white.withOpacity(0.3));
      }).toList(),
    );
  }

// Include these lists in your constants.dart file or in the AddBookScreen class:
// Make sure these are defined elsewhere if not already in the class
  final List<String> genres = [
    'Fiction',
    'Non-Fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Romance',
    'Biography',
    'History',
    'Self-Help',
    'Business',
    'Children',
    'Young Adult',
    'Poetry',
    'Comics',
    'Cooking',
    'Art',
    'Travel',
    'Religion',
    'Other'
  ];

  final List<String> conditions = [
    'Like New',
    'Very Good',
    'Good',
    'Fair',
    'Poor'
  ];

  Widget _buildSummaryPictureWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.description, color: Color(0xFF9D54C2)),
            const SizedBox(width: 10),
            const Text(
              'Book Summary Image',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF4A235A),
              ),
            ),
            const Spacer(),
            if (_summaryImage != null)
              TextButton.icon(
                onPressed: _pickSummaryImage,
                icon: const Icon(Icons.edit, size: 16, color: Color(0xFF9D54C2)),
                label: const Text(
                  'Change',
                  style: TextStyle(color: Color(0xFF9D54C2)),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickSummaryImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0E6FA),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              image: _summaryImage != null
                  ? DecorationImage(
                image: FileImage(_summaryImage!),
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: _summaryImage == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  size: 54,
                  color: const Color(0xFF9D54C2).withOpacity(0.7),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .fadeIn(duration: 900.ms)
                    .then(delay: 200.ms)
                    .fadeOut(duration: 900.ms),
                const SizedBox(height: 12),
                const Text(
                  'Capture book summary or blurb',
                  style: TextStyle(
                    color: Color(0xFF9D54C2),
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to take a picture',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            )
                : Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 24,
                      color: Color(0xFF9D54C2),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Show the loading indicator while processing the image
        if (_isProcessingImage)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF9D54C2),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Extracting text...',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        // Add the text field for the extracted description
        if (_summaryImage != null && !_isProcessingImage)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note, color: Color(0xFF9D54C2), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Book Description (Edit if needed)',
                      style: TextStyle(
                        color: Color(0xFF4A235A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    hintText: 'Book description will appear here',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D54C2), width: 2),
                    ),
                  ),
                  maxLines: 5,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOut),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 350.ms)
        .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 350.ms, curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add a Book',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF9D54C2)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF9D54C2),
              backgroundColor: Color(0xFFF0E6FA),
            ),
            const SizedBox(height: 16),
            Text(
              _uploadTaskMessage ?? 'Adding your book...',
              style: const TextStyle(
                color: Color(0xFF9D54C2),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )
          : ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const Text(
            'Share Your Book',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4A235A),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: 6),
          const Text(
            'Add details about the book you want to trade',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .slideX(begin: -0.2, end: 0, duration: 400.ms, delay: 100.ms, curve: Curves.easeOut),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6FA), // Very light lilac
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
                image: _image != null
                    ? DecorationImage(
                  image: FileImage(_image!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: _image == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 60,
                    color: const Color(0xFF9D54C2).withOpacity(0.7),
                  )
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .fadeIn(duration: 900.ms)
                      .then(delay: 200.ms)
                      .fadeOut(duration: 900.ms),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap to add book cover',
                    style: TextStyle(
                      color: Color(0xFF9D54C2),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              )
                  : Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 24,
                        color: Color(0xFF9D54C2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms, delay: 200.ms)
              .scaleXY(begin: 0.9, end: 1, duration: 500.ms, delay: 200.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 24),

          // Book Title Field
          Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),

                padding: const EdgeInsets.all(4),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Book Title',
                    floatingLabelStyle: const TextStyle(color: Color(0xFF9D54C2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter the title of your book',
                    prefixIcon: const Icon(Icons.book, color: Color(0xFF9D54C2)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D54C2), width: 2),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 300.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 300.ms, curve: Curves.easeOut),
              const SizedBox(height: 24),
// Author Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: TextField(
                  controller: _authorController,
                  decoration: InputDecoration(
                    labelText: 'Author',
                    floatingLabelStyle: const TextStyle(color: Color(0xFF9D54C2)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Enter the author\'s name',
                    prefixIcon: const Icon(Icons.person, color: Color(0xFF9D54C2)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF9D54C2), width: 2),
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 350.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 350.ms, curve: Curves.easeOut),
              const SizedBox(height: 24),

              // Here we add the Summary Picture Widget
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _buildSummaryPictureWidget(),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category, color: Color(0xFF9D54C2)),
                        const SizedBox(width: 10),
                        const Text(
                          'Select Genre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4A235A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildOptionButtons(genres, _selectedGenre, (value) {
                      setState(() {
                        _selectedGenre = value;
                      });
                    }),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 400.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 400.ms, curve: Curves.easeOut),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF9D54C2)),
                        const SizedBox(width: 10),
                        const Text(
                          'Select Condition',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF4A235A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildOptionButtons(conditions, _selectedCondition, (value) {
                      setState(() {
                        _selectedCondition = value;
                      });
                    }),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 500.ms, delay: 500.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 500.ms, curve: Curves.easeOut),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: GradientButton(
                  onPressed: _submit,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9D54C2), Color(0xFFAA68D5)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.bookmark_add, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        'Add Book',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 600.ms)
                  .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 600.ms, curve: Curves.easeOut),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}