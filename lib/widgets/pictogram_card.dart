// widgets/pictogram_card.dart
import 'package:flutter/material.dart';
import '../models/pictogram_model.dart';

class PictogramCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: categoryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                pictogram.icon,
                size: 32,
                color: categoryColor,
              ),
              const SizedBox(height: 8),
              Text(
                pictogram.label,
                style: TextStyle(
                  fontSize: 12,
                  color: categoryColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}