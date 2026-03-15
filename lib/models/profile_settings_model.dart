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

  // Factory method para criar a partir de JSON
  factory ProfileSettings.fromJson(Map<String, dynamic> json) {
    return ProfileSettings(
      voiceRate: json['voiceRate']?.toDouble() ?? 0.5,
      voicePitch: json['voicePitch']?.toDouble() ?? 1.0,
      highContrast: json['highContrast'] ?? false,
      selectedVoice: json['selectedVoice'] ?? "pt-br-x-abd-local",
    );
  }

  // Método para converter para JSON
  Map<String, dynamic> toJson() {
    return {
      'voiceRate': voiceRate,
      'voicePitch': voicePitch,
      'highContrast': highContrast,
      'selectedVoice': selectedVoice,
    };
  }

  // Método copyWith para criar uma cópia com alterações
  ProfileSettings copyWith({
    double? voiceRate,
    double? voicePitch,
    bool? highContrast,
    String? selectedVoice,
  }) {
    return ProfileSettings(
      voiceRate: voiceRate ?? this.voiceRate,
      voicePitch: voicePitch ?? this.voicePitch,
      highContrast: highContrast ?? this.highContrast,
      selectedVoice: selectedVoice ?? this.selectedVoice,
    );
  }
}