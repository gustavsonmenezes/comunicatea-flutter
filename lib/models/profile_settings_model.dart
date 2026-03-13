// models/profile_settings_model.dart
class ProfileSettings {
  double voiceRate; // Velocidade da voz (0.1 a 1.0)
  double voicePitch; // Tom da voz
  bool highContrast; // Alto contraste para acessibilidade
  String selectedVoice; // Nome da voz selecionada

  ProfileSettings({
    this.voiceRate = 0.5,
    this.voicePitch = 1.0,
    this.highContrast = false,
    this.selectedVoice = "pt-br-x-abd-local",
  });
}