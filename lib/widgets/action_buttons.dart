import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onLike;
  final VoidCallback onInfo;

  const ActionButtons({
    Key? key,
    required this.onSkip,
    required this.onLike,
    required this.onInfo,
  }) : super(key: key);

  static const Color lilacPrimary = Color(0xFF9D54C2);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCircleButton(
            onTap: onSkip,
            icon: Icons.close,
            color: Colors.red,
            size: 64,
            iconSize: 30,
          ),
          _buildCircleButton(
            onTap: onInfo,
            icon: Icons.info_outline,
            color: Colors.blue,
            size: 48,
            iconSize: 24,
          ),
          _buildCircleButton(
            onTap: onLike,
            icon: Icons.favorite,
            color: lilacPrimary,
            size: 64,
            iconSize: 30,
          ),
        ],
      ),
    );
  }

  // Custom circle button builder to avoid code duplication
  Widget _buildCircleButton({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: color,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
