import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Modo de alto contraste'),
            subtitle: const Text('Melhor visualização para crianças com sensibilidade visual'),
            value: false,
            onChanged: (value) {},
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Síntese de voz'),
            subtitle: const Text('Ativar fala automática ao selecionar pictogramas'),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Velocidade da voz'),
            subtitle: const Text('Normal'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Tamanho dos pictogramas'),
            subtitle: const Text('Médio'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Feedback tátil'),
            subtitle: const Text('Vibração ao tocar nos botões'),
            value: true,
            onChanged: (value) {},
          ),
          const Divider(),
          ListTile(
            title: const Text('Sobre o COMUNICA-TEA'),
            subtitle: const Text('Versão 1.0.0'),
            trailing: const Icon(Icons.info_outline),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'COMUNICA-TEA',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.chat_bubble_outline, size: 50),
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                        'Plataforma digital de Comunicação Aumentativa e Alternativa '
                            'para crianças com Transtorno do Espectro Autista.'
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}