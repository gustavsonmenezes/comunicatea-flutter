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
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildImageOrIcon(),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 1,
                child: Text(
                  pictogram.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOrIcon() {
    if (pictogram.assetPath != null) {
      return Image.asset(
        pictogram.assetPath!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback para ícone caso a imagem não seja encontrada no dispositivo
          return Icon(
            pictogram.icon,
            size: 40,
            color: categoryColor,
          );
        },
      );
    } else {
      return Icon(
        pictogram.icon,
        size: 40,
        color: categoryColor,
      );
    }
  }
}