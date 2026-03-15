import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/professional_provider.dart';
import '../../../models/child_profile.dart';

class ChildDetailsScreen extends StatelessWidget {
  final String childId;

  const ChildDetailsScreen({Key? key, required this.childId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProfessionalProvider>(context, listen: false);

    return FutureBuilder<ChildProfile?>(
      future: provider.getChild(childId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Erro'),
              backgroundColor: Colors.blue[800],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erro ao carregar dados'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          );
        }

        final child = snapshot.data!;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(child.name),
              backgroundColor: Colors.blue[800],
              foregroundColor: Colors.white,
              bottom: const TabBar(
                indicatorColor: Colors.white,
                tabs: [
                  Tab(icon: Icon(Icons.person), text: 'Perfil'),
                  Tab(icon: Icon(Icons.bar_chart), text: 'Progresso'),
                  Tab(icon: Icon(Icons.settings), text: 'Configurações'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildProfileTab(child),
                _buildProgressTab(child),
                _buildSettingsTab(child, provider, context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileTab(ChildProfile child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      child.name.isNotEmpty ? child.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 32, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    child.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (child.age != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${child.age} anos',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                  if (child.diagnosis != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        child.diagnosis!,
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Informações de Uso',
            [
              _buildInfoRow('Total de sessões', '${child.progress.totalSessions}'),
              _buildInfoRow('Frases construídas', '${child.progress.totalPhrasesBuilt}'),
              _buildInfoRow('Primeiro acesso', _formatDate(child.createdAt)),
              _buildInfoRow('Último acesso', _formatDate(child.lastActive)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab(ChildProfile child) {
    final mostUsed = child.progress.pictogramUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Resumo',
            [
              _buildInfoRow('Média diária',
                  (child.progress.totalSessions / 7).toStringAsFixed(1)),
              _buildInfoRow('Total de frases', '${child.progress.totalPhrasesBuilt}'),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Pictogramas Mais Usados',
            mostUsed.isEmpty
                ? [const Text('Nenhum dado disponível')]
                : mostUsed.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.key)),
                    Text(
                      '${entry.value}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(ChildProfile child, ProfessionalProvider provider, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Preferências de Comunicação',
            [
              SwitchListTile(
                title: const Text('Alto Contraste'),
                value: child.settings.highContrast,
                onChanged: (value) {
                  provider.updateChildSettings(child.id, {'highContrast': value});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuração atualizada!')),
                  );
                },
                secondary: const Icon(Icons.contrast),
              ),
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Velocidade da Voz'),
                  Slider(
                    value: child.settings.voiceRate,
                    min: 0.1,
                    max: 1.0,
                    divisions: 9,
                    label: child.settings.voiceRate.toStringAsFixed(1),
                    onChanged: (value) {
                      provider.updateChildSettings(child.id, {'voiceRate': value});
                    },
                  ),
                ],
              ),
              const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tom da Voz'),
                  Slider(
                    value: child.settings.voicePitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    label: child.settings.voicePitch.toStringAsFixed(1),
                    onChanged: (value) {
                      provider.updateChildSettings(child.id, {'voicePitch': value});
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Profissionais',
            child.professionalIds.isEmpty
                ? [const Text('Nenhum profissional vinculado')]
                : child.professionalIds.map((id) =>
                ListTile(
                  leading: const Icon(Icons.medical_services),
                  title: const Text('Profissional'),
                  subtitle: Text('ID: $id'),
                )
            ).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}