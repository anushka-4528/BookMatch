import 'package:flutter/material.dart';
import 'dart:math' as math;

class MatchPopup extends StatefulWidget {
  const MatchPopup({super.key});

  @override
  State<MatchPopup> createState() => _MatchPopupState();
}

class _MatchPopupState extends State<MatchPopup> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<String> _funMessages = [
    "You both have amazing taste in books!",
    "A bookish connection has been made!",
    "Two bookworms, one great read!",
    "Your reading paths have crossed!",
    "Book soulmates - it's official!",
  ];

  late String _randomMessage;

  @override
  void initState() {
    super.initState();

    // Select a random fun message
    final random = math.Random();
    _randomMessage = _funMessages[random.nextInt(_funMessages.length)];

    // Setup animations
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEFE5FD),  // Very light lilac
                Color(0xFFE3D0F5),  // Light lavender
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildConfetti(),
              const SizedBox(height: 16),
              Text(
                '💫 It\'s a Match! 💫',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: Color(0xFF7E57C2),  // Deep purple
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _randomMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF7E57C2),  // Deep purple
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a conversation about this book!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9575CD),  // Medium purple
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 12),  // Add spacing between buttons
                  _buildButton(
                    'Later',
                    Color(0xFFAB47BC),  // Light purple
                    Icons.timer,
                        () => Navigator.of(context).pop(),
                    isSecondary: true,
                  ),
                  SizedBox(width: 12),  // Add spacing between buttons
                  _buildButton(
                    'Chat',
                    Color(0xFF5E35B1),  // Deep violet
                    Icons.chat_bubble_outline,
                        () => Navigator.of(context).pop(),
                  ),
                  SizedBox(width: 12),  // Add spacing between buttons
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() {
    return SizedBox(
      height: 80,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildConfettiEmoji('📚', -0.2),
          _buildConfettiEmoji('✨', 0.2),
          _buildConfettiEmoji('🎉', -0.3),
          _buildConfettiEmoji('📖', 0.1),
          _buildConfettiEmoji('💕', -0.1),
        ],
      ),
    );
  }

  Widget _buildConfettiEmoji(String emoji, double offset) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (math.Random().nextInt(400))),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(value * math.pi * 2) * 10 * offset,
            -30 * value + 15 * math.sin(value * math.pi * 3),
          ),
          child: Opacity(
            opacity: value < 0.8 ? value : 1.0,
            child: Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
          ),
        );
      },
    );
  }

  Widget _buildButton(String text, Color color, IconData icon, VoidCallback onPressed, {bool isSecondary = false}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? Colors.white : color,
        foregroundColor: isSecondary ? color : Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: Size(110, 46),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: isSecondary ? BorderSide(color: color, width: 2) : BorderSide.none,
        ),
        elevation: isSecondary ? 0 : 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}