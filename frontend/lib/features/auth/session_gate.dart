import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../tasks/task_pool_screen.dart';
import '../teams/team_selection_screen.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class SessionGate extends StatefulWidget {
  const SessionGate({super.key, required this.api});
  final ApiClient api;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final AuthService auth = AuthService(widget.api);
  AuthContext? sessionContext;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    restore();
  }

  Future<void> restore() async {
    final restored = await auth.restore();
    if (mounted) setState(() { sessionContext = restored; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final session = sessionContext;
    if (session == null || session.teams.isEmpty) return LoginScreen(api: widget.api);
    if (session.teams.length == 1) return TaskPoolScreen(team: session.teams.single, userId: session.userId, api: widget.api);
    return TeamSelectionScreen(api: widget.api, userId: session.userId, teams: session.teams);
  }
}
