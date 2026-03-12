// features/profiles/widgets/profile_avatar.dart
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String emoji;
  final double size;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const ProfileAvatar({
    Key? key,
    required this.emoji,
    this.size = 60,
    this.backgroundColor = Colors.transparent,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            emoji,
            style: TextStyle(fontSize: size * 0.6),
          ),
        ),
      ),
    );
  }
}