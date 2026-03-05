import 'package:audioplayers/audioplayers.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  final AudioPlayer _player = AudioPlayer();

  /// Reproduz o som de sucesso (ex: ao tocar num pictograma)
  Future<void> playSuccess() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('Erro ao reproduzir som de sucesso: $e');
    }
  }

  /// Reproduz o som de erro/alerta (ex: ao apagar algo)
  Future<void> playError() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      print('Erro ao reproduzir som de erro: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}