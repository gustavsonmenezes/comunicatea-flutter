import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _childIdController = TextEditingController(); // 🔥 ID da Criança para os Pais
  
  String _userRole = 'professional'; // 'professional' ou 'parent'
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos')));
      return;
    }

    if (_userRole == 'parent' && _childIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o ID da criança fornecido pelo profissional')));
      return;
    }

    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    bool success;
    if (_userRole == 'professional') {
      success = await authService.registerProfessional(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
    } else {
      success = await authService.registerParent(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _childIdController.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada com sucesso! Faça login.')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao criar conta. Verifique os dados.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Nova Conta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Selecione seu perfil:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Profissional', style: TextStyle(fontSize: 12)),
                    value: 'professional',
                    groupValue: _userRole,
                    onChanged: (v) => setState(() => _userRole = v!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Pai/Mãe', style: TextStyle(fontSize: 12)),
                    value: 'parent',
                    groupValue: _userRole,
                    onChanged: (v) => setState(() => _userRole = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Seu Nome Completo', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder()), obscureText: true),
            
            if (_userRole == 'parent') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _childIdController, 
                decoration: const InputDecoration(
                  labelText: 'ID da Criança (Código)', 
                  helperText: 'Peça este código ao fonoaudiólogo da criança',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key)
                )
              ),
            ],

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('CRIAR CONTA'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
