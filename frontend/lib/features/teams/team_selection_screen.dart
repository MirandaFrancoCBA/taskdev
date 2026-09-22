import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../auth/auth_service.dart';
import '../tasks/task_pool_screen.dart';

class TeamSelectionScreen extends StatelessWidget {
  const TeamSelectionScreen({super.key, required this.api, required this.userId, required this.teams});
  final ApiClient api;
  final int userId;
  final List<TeamSummary> teams;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Choose team')),
    body: ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final team = teams[index];
        return Card(child: ListTile(
          title: Text(team.name),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TaskPoolScreen(teamId: team.id, userId: userId, api: api))),
        ));
      },
    ),
  );
}
