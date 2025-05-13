import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onNope;
  final VoidCallback onLike;
  final VoidCallback onSuperLike;

  const ActionButtons({
    super.key,
    required this.onNope,
    required this.onLike,
    required this.onSuperLike,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            onPressed: onNope,
            icon: Icons.close,
            color: Colors.red,
            size: 60,
          ),
          _buildActionButton(
            onPressed: onSuperLike,
            icon: Icons.star,
            color: Colors.blue,
            size: 48,
          ),
          _buildActionButton(
            onPressed: onLike,
            icon: Icons.favorite,
            color: Colors.green,
            size: 60,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Padding(
            padding: EdgeInsets.all(size * 0.2),
            child: Icon(
              icon,
              size: size * 0.5,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
