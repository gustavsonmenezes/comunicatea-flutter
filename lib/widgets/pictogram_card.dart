// widgets/pictogram_card.dart
import 'package:flutter/material.dart';
import '../models/pictogram_model.dart';

class PictogramCard extends StatefulWidget {
  final Pictogram pictogram;
  final VoidCallback onTap;
  final Color categoryColor;

  const PictogramCard({
    Key? key,
    required this.pictogram,
    required this.onTap,
    required this.categoryColor,
  }) : super(key: key);

  @override
  State<PictogramCard> createState() => _PictogramCardState();
}

class _PictogramCardState extends State<PictogramCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: widget.categoryColor.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: _isPressed ? 4 : 12,
              offset: _isPressed ? const Offset(0, 2) : const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: _buildImageOrIcon(),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: widget.categoryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Text(
                widget.pictogram.label,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.categoryColor,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Quicksand',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOrIcon() {
    if (widget.pictogram.assetPath != null) {
      return Image.asset(
        widget.pictogram.assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            widget.pictogram.icon,
            size: 40,
            color: widget.categoryColor,
          );
        },
      );
    } else {
      return Icon(
        widget.pictogram.icon,
        size: 40,
        color: widget.categoryColor,
      );
    }
  }
}