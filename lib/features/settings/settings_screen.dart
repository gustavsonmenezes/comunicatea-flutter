import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _highContrast = false;
  bool _autoSpeak = true;
  bool _hapticFeedback = true;
  double _voiceSpeed = 0.5;
  double _pictogramSize = 100;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          // Seção de Acessibilidade
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Acessibilidade',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              title: const Text('Modo de alto contraste'),
              subtitle: const Text(
                'Melhor visualização para crianças com sensibilidade visual',
              ),
              value: _highContrast,
              onChanged: (value) {
                setState(() {
                  _highContrast = value;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _highContrast
                          ? 'Modo de alto contraste ativado'
                          : 'Modo de alto contraste desativado',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),

          // Seção de Áudio
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'Áudio',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              title: const Text('Síntese de voz'),
              subtitle: const Text(
                'Ativar fala automática ao selecionar pictogramas',
              ),
              value: _autoSpeak,
              onChanged: (value) {
                setState(() {
                  _autoSpeak = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Velocidade da voz',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getSpeedLabel(_voiceSpeed),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _voiceSpeed,
                    min: 0.3,
                    max: 1.0,
                    divisions: 7,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: AppTheme.borderColor,
                    onChanged: (value) {
                      setState(() {
                        _voiceSpeed = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Lento',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Rápido',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Seção de Interface
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'Interface',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tamanho dos pictogramas',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getSizeLabel(_pictogramSize),
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _pictogramSize,
                    min: 80,
                    max: 140,
                    divisions: 6,
                    activeColor: AppTheme.primaryColor,
                    inactiveColor: AppTheme.borderColor,
                    onChanged: (value) {
                      setState(() {
                        _pictogramSize = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pequeno',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Grande',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SwitchListTile(
              title: const Text('Feedback tátil'),
              subtitle: const Text('Vibração ao tocar nos botões'),
              value: _hapticFeedback,
              onChanged: (value) {
                setState(() {
                  _hapticFeedback = value;
                });
              },
              activeColor: AppTheme.primaryColor,
            ),
          ),

          // Seção de Informações
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Text(
              'Informações',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: const Text('Sobre o COMUNICA-TEA'),
              subtitle: const Text('Versão 2.0.0'),
              trailing: const Icon(Icons.info_outline),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'COMUNICA-TEA',
                  applicationVersion: '2.0.0',
                  applicationIcon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 50,
                    color: AppTheme.primaryColor,
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Plataforma digital de Comunicação Aumentativa e Alternativa para crianças com Transtorno do Espectro Autista.\\n\\n'
                            'Desenvolvido por Gustavson Barros com foco em acessibilidade, inclusão e usabilidade.\\n\\n'
                            'Versão 2.0.0 - Melhorias de UI/UX\\n\\n'
                            'Licença: Open Source',
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _getSpeedLabel(double value) {
    if (value < 0.4) return 'Muito lento';
    if (value < 0.6) return 'Lento';
    if (value < 0.8) return 'Normal';
    return 'Rápido';
  }

  String _getSizeLabel(double value) {
    if (value < 100) return 'Pequeno';
    if (value < 120) return 'Médio';
    return 'Grande';
  }
}
