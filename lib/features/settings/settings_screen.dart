import 'package:flutter/material.dart';
import '../../models/child_profile.dart';
import 'parent_dashboard_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Para teste, vamos usar um perfil fixo ou buscar do provider/banco
    // No seu app real, você pegaria o perfil da criança logada
    final childMock = ChildProfile(
      id: 'child123', 
      name: 'Joãozinho', 
      age: 5,
      gender: 'Masculino',
      level: 'Nível 1'
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('ÁREA DA FAMÍLIA', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.purple[50], shape: BoxShape.circle),
              child: Icon(Icons.family_restroom, color: Colors.purple[800]),
            ),
            title: const Text('Painel de Acompanhamento'),
            subtitle: const Text('Veja o progresso e atividades para casa'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ParentDashboardScreen(child: childMock)),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('OPÇÕES DO APLICATIVO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Perfil do Aluno'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text('Configurações de Voz'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Modo Profissional (Senha)'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
