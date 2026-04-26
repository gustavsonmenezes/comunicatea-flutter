import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase: $e');
  }
  runApp(const ComunicaTeaAdmin());
}

class ComunicaTeaAdmin extends StatelessWidget {
  const ComunicaTeaAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'COMUNICA-TEA Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData) return const HomePage();
          return const LoginPage();
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${e.message}'), backgroundColor: Colors.red));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro de conexão. Verifique sua internet.'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🗣️ COMUNICA-TEA', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 32),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail Profissional', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder(), prefixIcon: Icon(Icons.lock))),
              const SizedBox(height: 32),
              _isLoading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55), backgroundColor: Colors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Entrar no Painel')),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String? uid = user?.uid;
    final String? email = user?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Profissional'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut())
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bem-vindo, $email', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const Text('Pacientes em Acompanhamento', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSyncStatus(context, uid, email),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Status de Sincronia'),
                )
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('children').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Center(child: Text('Erro de conexão com o Banco: ${snapshot.error}'));
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                  final allDocs = snapshot.data?.docs ?? [];
                  final docs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List<dynamic> profIds = data['professionalIds'] ?? [];
                    final String? singleId = data['professionalId'];
                    return profIds.contains(uid) || profIds.contains(email) || singleId == uid || singleId == email;
                  }).toList();

                  if (docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person_search, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhum paciente novo encontrado.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Text('Crie um perfil no Mobile usando seu e-mail profissional.'),
                          const SizedBox(height: 24),
                          Text('Seu ID Atual: $uid', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.person, color: Colors.white)),
                          title: Text(data['name'] ?? 'Criança sem nome', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Diagnóstico: ${data['diagnosis'] ?? "Não informado"}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PatientDetailPage(childId: id, childName: data['name'] ?? 'Paciente'))),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSyncStatus(BuildContext context, String? uid, String? email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dados de Sincronização'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Para uma criança aparecer aqui, o perfil dela no Mobile deve ter um destes IDs:', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            SelectableText('UID: $uid', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 8),
            SelectableText('E-mail: $email', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
      ),
    );
  }
}

class PatientDetailPage extends StatelessWidget {
  final String childId;
  final String childName;

  const PatientDetailPage({super.key, required this.childId, required this.childName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório: $childName'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('children').doc(childId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Nenhum dado de progresso encontrado.', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('ID da criança: $childId', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
                  ),
                ],
              ),
            );
          }

          // 🔥 Buscar progresso - pode estar em campos diretos ou dentro de 'progress'
          final progress = data['progress'] as Map<String, dynamic>? ?? data;

          final int stars = progress['totalStars'] ?? 0;
          final int phrases = progress['totalPhrasesBuilt'] ?? 0;
          final int sessions = progress['totalSessions'] ?? 0;
          final Map<String, dynamic> categories = progress['categoryUsage'] ?? {};
          final Map<String, dynamic> pictograms = progress['pictogramUsage'] ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cards de estatísticas
                Row(
                  children: [
                    _buildStatCard('Total de Estrelas', '$stars', Icons.star, Colors.orange),
                    const SizedBox(width: 16),
                    _buildStatCard('Frases Construídas', '$phrases', Icons.chat, Colors.blue),
                    const SizedBox(width: 16),
                    _buildStatCard('Total de Sessões', '$sessions', Icons.timer, Colors.green),
                  ],
                ),

                const SizedBox(height: 40),

                // Gráfico de categorias
                const Text('Desempenho por Categoria', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                if (categories.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.bar_chart, size: 48, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhuma categoria utilizada ainda.'),
                          const SizedBox(height: 8),
                          Text('A criança precisa usar o app para gerar estatísticas.',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 400,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: PieChart(
                            PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 40,
                              sections: categories.entries.map((e) {
                                final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal, Colors.pink, Colors.indigo];
                                final index = categories.keys.toList().indexOf(e.key);
                                return PieChartSectionData(
                                  value: (e.value as num).toDouble(),
                                  title: '${e.key}\n(${e.value})',
                                  radius: 100,
                                  color: colors[index % colors.length],
                                  titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: categories.entries.map((e) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      color: Colors.primaries[categories.keys.toList().indexOf(e.key) % Colors.primaries.length],
                                    ),
                                    const SizedBox(width: 8),
                                    Text('${e.key}: ${e.value}'),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                // Pictogramas mais usados
                const Text('Pictogramas Mais Usados', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                if (pictograms.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: Text('Nenhum pictograma utilizado ainda.')),
                    ),
                  )
                else
                  Card(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: pictograms.entries.take(10).length,
                      itemBuilder: (context, index) {
                        final entry = pictograms.entries.elementAt(index);
                        return ListTile(
                          leading: const Icon(Icons.image, color: Colors.blue),
                          title: Text(entry.key),
                          trailing: Text('${entry.value} vezes', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 24),

                // Informações do paciente
                Card(
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Informações do Paciente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Divider(),
                        _buildInfoRow('Nome', data['name'] ?? 'N/A'),
                        _buildInfoRow('Diagnóstico', data['diagnosis'] ?? 'Não informado'),
                        _buildInfoRow('Idade', data['age'] != null ? '${data['age']} anos' : 'N/A'),
                        _buildInfoRow('Último acesso', data['lastActive'] != null
                            ? _formatDate((data['lastActive'] as Timestamp).toDate())
                            : 'N/A'),
                        _buildInfoRow('Data de criação', data['createdAt'] != null
                            ? _formatDate((data['createdAt'] as Timestamp).toDate())
                            : 'N/A'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(height: 12),
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
              Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}