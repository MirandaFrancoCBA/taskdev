import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../tasks/task_pool_screen.dart';
import '../teams/team_selection_screen.dart';
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
  bool loading = false;
  String? error;

  Future<void> login() async {
    setState(() { loading = true; error = null; });
    try {
      final auth = await AuthService(widget.api).login(username.text.trim(), password.text);
      if (!mounted) return;
      if (auth.teams.isEmpty) {
        setState(() => error = 'Your account does not belong to a team yet.');
        return;
      }
      final destination = auth.teams.length == 1
          ? TaskPoolScreen(team: auth.teams.single, userId: auth.userId, api: widget.api)
          : TeamSelectionScreen(api: widget.api, userId: auth.userId, teams: auth.teams);
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    username.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('TaskDev')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      Text('Sign in', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 24),
      TextField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
      const SizedBox(height: 12),
      TextField(controller: password, obscureText: true, onSubmitted: (_) => loading ? null : login(), decoration: const InputDecoration(labelText: 'Password')),
      if (error != null) ...[const SizedBox(height: 12), Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
      const SizedBox(height: 24),
      FilledButton(onPressed: loading ? null : login, child: Text(loading ? 'Signing in…' : 'Sign in')),
    ])),
  );
}
