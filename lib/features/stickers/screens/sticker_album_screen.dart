// lib/features/stickers/screens/sticker_album_screen.dart
import 'package:flutter/material.dart';
import '../models/sticker_model.dart';  // ← Import do modelo (mesma pasta)
import '../services/sticker_service.dart';  // ← Import do serviço (mesma pasta)
import '../../../services/profile_service.dart';
import '../../../theme/app_theme.dart';

class StickerAlbumScreen extends StatefulWidget {
  const StickerAlbumScreen({super.key});

  @override
  State<StickerAlbumScreen> createState() => _StickerAlbumScreenState();
}

class _StickerAlbumScreenState extends State<StickerAlbumScreen> {
  final StickerService _stickerService = StickerService();
  final ProfileService _profileService = ProfileService();
  List<StickerModel> _stickers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStickers();
  }

  Future<void> _loadStickers() async {
    final currentProfile = _profileService.currentProfile;
    if (currentProfile != null) {
      final stickers = await _stickerService.getStickers(currentProfile.id);
      setState(() {
        _stickers = stickers;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Álbum de Figurinhas'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stickers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma figurinha ainda',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete atividades para ganhar figurinhas!',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _stickers.length,
        itemBuilder: (context, index) {
          final sticker = _stickers[index];
          return Container(
            decoration: BoxDecoration(
              color: sticker.isUnlocked ? Colors.white : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sticker.isUnlocked ? Colors.green : Colors.grey,
                width: 2,
              ),
            ),
            child: sticker.isUnlocked
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 40),
                const SizedBox(height: 4),
                Text(
                  sticker.name,
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            )
                : const Center(
              child: Icon(Icons.lock, size: 30, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}