import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/sound_manager.dart';

class PhraseBar extends StatelessWidget {
  final List<String> phrase;
  final bool isSpeaking;
  final VoidCallback onSpeak;
  final VoidCallback onClear;
  final VoidCallback onRemoveLast;
  final bool isEnabled;

  const PhraseBar({
    Key? key,
    required this.phrase,
    required this.isSpeaking,
    required this.onSpeak,
    required this.onClear,
    required this.onRemoveLast,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final phraseText = phrase.isEmpty
        ? 'Toque nos pictogramas para se comunicar'
        : phrase.join(' ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de frase
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Text(
              phraseText,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: phrase.isEmpty
                    ? AppTheme.textSecondaryColor
                    : AppTheme.textPrimaryColor,
                fontFamily: 'Quicksand',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),

          // Botões de ação
          Row(
            children: [
              // Botão Falar
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isEnabled && phrase.isNotEmpty
                      ? () {
                    SoundManager().playSuccess();
                    onSpeak();
                  }
                      : null,
                  icon: Icon(
                    isSpeaking ? Icons.stop : Icons.volume_up,
                    size: 20,
                  ),
                  label: Text(
                    isSpeaking ? 'Parar' : 'Falar',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Botão Remover Último
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: isEnabled && phrase.isNotEmpty
                      ? () {
                    SoundManager().playError(); // Som de alerta ao remover
                    onRemoveLast();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.backspace, size: 20),
                ),
              ),
              const SizedBox(width: 8),

              // Botão Limpar
              SizedBox(
                width: 50,
                child: ElevatedButton(
                  onPressed: isEnabled && phrase.isNotEmpty
                      ? () {
                    SoundManager().playError();
                    onClear();
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.all(0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.delete, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
