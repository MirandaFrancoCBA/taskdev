import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/masse_dev_theme.dart';
import '../auth/auth_service.dart';
import 'team_service.dart';

class TeamMembersScreen extends StatefulWidget {
  const TeamMembersScreen({super.key, required this.api, required this.team, required this.userId});
  final ApiClient api;
  final TeamSummary team;
  final int userId;

  @override
  State<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<TeamMembersScreen> {
  late final TeamService service = TeamService(widget.api);
  late TeamSummary team = widget.team;
  bool saving = false;

  Future<void> _add() async {
    final input = await showDialog<_MemberInput>(context: context, builder: (_) => const _MemberDialog());
    if (input == null) return;
    await _run(() async {
      team = await service.addMember(team: team, currentUserId: widget.userId, userId: input.userId, role: input.role);
    });
  }

  Future<void> _changeRole(TeamMember member, String role) async {
    if (member.userId == widget.userId) {
      _message('You cannot change your own coordinator role here.');
      return;
    }
    await _run(() async {
      team = await service.updateMember(team: team, currentUserId: widget.userId, membershipId: member.id, role: role);
    });
  }

  Future<void> _remove(TeamMember member) async {
    if (member.userId == widget.userId) {
      _message('You cannot remove yourself from the team here.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${member.username}?'),
        content: const Text('They will lose access to this team and its tasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await service.removeMember(team: team, membershipId: member.id);
      team = TeamSummary(
        id: team.id,
        name: team.name,
        role: team.role,
        members: team.members.where((item) => item.id != member.id).toList(),
      );
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => saving = true);
    try {
      await action();
    } catch (e) {
      _message(e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text('${team.name} members'),
          leading: BackButton(onPressed: () => Navigator.of(context).pop(team)),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: saving ? null : _add,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add member'),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(MasseDevTokens.spaceMd),
          itemCount: team.members.length,
          separatorBuilder: (_, __) => const SizedBox(height: MasseDevTokens.spaceSm),
          itemBuilder: (context, index) {
            final member = team.members[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(member.username.isEmpty ? '?' : member.username[0].toUpperCase())),
                title: Text(member.username),
                subtitle: Text(member.role == 'coordinator' ? 'Coordinator' : 'Member'),
                trailing: member.userId == widget.userId
                    ? const Chip(label: Text('You'))
                    : PopupMenuButton<String>(
                        enabled: !saving,
                        onSelected: (value) {
                          if (value == 'remove') {
                            _remove(member);
                          } else {
                            _changeRole(member, value);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'coordinator', child: Text('Make coordinator')),
                          PopupMenuItem(value: 'member', child: Text('Make member')),
                          PopupMenuDivider(),
                          PopupMenuItem(value: 'remove', child: Text('Remove from team')),
                        ],
                      ),
              ),
            );
          },
        ),
      );
}

class _MemberInput {
  const _MemberInput(this.userId, this.role);
  final int userId;
  final String role;
}

class _MemberDialog extends StatefulWidget {
  const _MemberDialog();

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  final controller = TextEditingController();
  String role = 'member';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add team member'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'User ID', helperText: 'Enter the existing TaskDev user ID.'),
          ),
          const SizedBox(height: MasseDevTokens.spaceSm),
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: 'member', child: Text('Member')),
              DropdownMenuItem(value: 'coordinator', child: Text('Coordinator')),
            ],
            onChanged: (value) => setState(() => role = value ?? 'member'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final id = int.tryParse(controller.text.trim());
              if (id != null) Navigator.pop(context, _MemberInput(id, role));
            },
            child: const Text('Add'),
          ),
        ],
      );
}
