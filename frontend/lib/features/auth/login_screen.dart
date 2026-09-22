import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../tasks/task_pool_screen.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.api});
  final ApiClient api;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final username = TextEditingController();
  final password = TextEditingController();
  final teamId = TextEditingController();
  final userId = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      await AuthService(widget.api).login(username.text.trim(), password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TaskPoolScreen(teamId: int.parse(teamId.text), userId: int.parse(userId.text), api: widget.api)));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TaskDev')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
      const SizedBox(height: 12),
      TextField(controller: teamId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Team ID')),
      const SizedBox(height: 12),
      TextField(controller: userId, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'User ID')),
      if (error != null) ...[const SizedBox(height: 12), Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
      const SizedBox(height: 24),
      FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'Signing in…' : 'Sign in')),
    ])),
  );
}
