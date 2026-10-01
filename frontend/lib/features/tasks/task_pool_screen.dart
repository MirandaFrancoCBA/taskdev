import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/masse_dev_theme.dart';
import '../../core/theme/taskdev_page.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import '../teams/team_members_screen.dart';
import 'task.dart';
import 'task_detail_screen.dart';
import 'task_realtime_service.dart';
import 'task_service.dart';

class TaskPoolScreen extends StatefulWidget {
  const TaskPoolScreen({super.key, required this.team, required this.userId, required this.api});
  final TeamSummary team;
  final int userId;
  final ApiClient api;

  @override
  State<TaskPoolScreen> createState() => _TaskPoolScreenState();
}

class _TaskPoolScreenState extends State<TaskPoolScreen> {
  late final TaskService service = TaskService(widget.api);
  late TeamSummary team = widget.team;
  List<Task> tasks = const [];
  bool loading = true;
  String? error;
  TaskRealtimeService? realtime;

  @override
  void initState() {
    super.initState();
    refresh();
    if (widget.api.accessToken != null) {
      realtime = TaskRealtimeService(
        teamId: team.id,
        accessTokenProvider: () => widget.api.accessToken,
        onTaskEvent: _refreshFromRealtime,
      )..connect();
    }
  }

  Future<void> _refreshFromRealtime() async {
    try {
      final result = await service.listTasks(team.id);
      if (mounted) setState(() { tasks = result; error = null; });
    } catch (_) {
      // Preserve the last good local state. Manual REST refresh remains available.
    }
  }

  @override
  void dispose() {
    realtime?.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await service.listTasks(team.id);
      if (mounted) setState(() => tasks = result);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> claim(Task task) async {
    try {
      await service.claim(task.id);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> changeStatus(Task task, String status) async {
    try {
      await service.setStatus(task.id, status);
      await refresh();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> createTask() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateTaskDialog(service: service, team: team),
    );
    if (created == true) await refresh();
  }

  Future<void> _openTask(Task task) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task, service: service)),
    );
  }

  Future<void> _logout() async {
    await AuthService(widget.api).logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final available = tasks.where((task) => task.assignee == null && task.status == 'pending').toList();
    final mine = tasks.where((task) => task.assignee == widget.userId && task.status != 'blocked' && task.status != 'completed').toList();
    final blocked = tasks.where((task) => task.status == 'blocked').toList();
    final completed = tasks.where((task) => task.status == 'completed').toList();

    return TaskDevPage(
      title: team.name,
      actions: [
        if (team.role == 'coordinator') IconButton(
          tooltip: 'Manage members',
          onPressed: () async {
            final updated = await Navigator.of(context).push<TeamSummary>(
              MaterialPageRoute(builder: (_) => TeamMembersScreen(api: widget.api, team: team, userId: widget.userId)),
            );
            if (updated != null && mounted) setState(() => team = updated);
          },
          icon: const Icon(Icons.group_outlined),
        ),
        IconButton(tooltip: 'Refresh', onPressed: loading ? null : refresh, icon: const Icon(Icons.refresh)),
        IconButton(tooltip: 'Log out', onPressed: _logout, icon: const Icon(Icons.logout)),
      ],
      floatingActionButton: team.role == 'coordinator'
          ? FloatingActionButton.extended(onPressed: createTask, icon: const Icon(Icons.add), label: const Text('New task'))
          : null,
      child: _body(available: available, mine: mine, blocked: blocked, completed: completed),
    );
  }

  Widget _body({
    required List<Task> available,
    required List<Task> mine,
    required List<Task> blocked,
    required List<Task> completed,
  }) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(MasseDevTokens.spaceLg),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 42),
          const SizedBox(height: MasseDevTokens.spaceMd),
          Text('We could not load this team.', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: MasseDevTokens.spaceSm),
          Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: MasseDevTokens.spaceMd),
          FilledButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('Retry')),
        ]),
      ));
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: LayoutBuilder(builder: (context, constraints) {
        final sections = [
          _WorkSection(title: 'My work', icon: Icons.work_outline, tasks: mine, emptyMessage: 'You have no active tasks.', actionFor: _statusAction, onTap: _openTask),
          _WorkSection(title: 'Available', icon: Icons.inbox_outlined, tasks: available, emptyMessage: 'No tasks are waiting in the pool.', actionFor: (task) => FilledButton(onPressed: () => claim(task), child: const Text('Take')), onTap: _openTask),
          _WorkSection(title: 'Blocked', icon: Icons.block_outlined, tasks: blocked, emptyMessage: 'No blocked tasks.', actionFor: _statusAction, onTap: _openTask),
          _WorkSection(title: 'Completed', icon: Icons.task_alt, tasks: completed, emptyMessage: 'No completed tasks yet.', actionFor: (_) => const SizedBox.shrink(), onTap: _openTask),
        ];
        final wide = constraints.maxWidth >= 900;
        return ListView(
          padding: const EdgeInsets.all(MasseDevTokens.spaceMd),
          children: [
            Text('Operational overview', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: MasseDevTokens.spaceXs),
            Text('${tasks.length} tasks across the team', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: MasseDevTokens.mutedInk)),
            const SizedBox(height: MasseDevTokens.spaceLg),
            if (wide)
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: MasseDevTokens.spaceMd,
                mainAxisSpacing: MasseDevTokens.spaceMd,
                childAspectRatio: 1.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: sections,
              )
            else
              ...sections.expand((section) => [section, const SizedBox(height: MasseDevTokens.spaceLg)]),
          ],
        );
      }),
    );
  }

  Widget _statusAction(Task task) => PopupMenuButton<String>(
        tooltip: 'Update status',
        onSelected: (value) => changeStatus(task, value),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'in_progress', child: Text('In progress')),
          PopupMenuItem(value: 'blocked', child: Text('Blocked')),
          PopupMenuItem(value: 'completed', child: Text('Complete')),
        ],
        child: const Padding(padding: EdgeInsets.all(8), child: Text('Update')),
      );
}

class _WorkSection extends StatelessWidget {
  const _WorkSection({
    required this.title,
    required this.icon,
    required this.tasks,
    required this.emptyMessage,
    required this.actionFor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final List<Task> tasks;
  final String emptyMessage;
  final Widget Function(Task) actionFor;
  final void Function(Task) onTap;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20),
            const SizedBox(width: MasseDevTokens.spaceSm),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('${tasks.length}', style: Theme.of(context).textTheme.labelLarge),
          ]),
          const SizedBox(height: MasseDevTokens.spaceSm),
          if (tasks.isEmpty) _EmptyCard(message: emptyMessage),
          ...tasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: MasseDevTokens.spaceSm),
                child: _TaskCard(task: task, onTap: () => onTap(task), action: actionFor(task)),
              )),
        ],
      );
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.action, required this.onTap});
  final Task task;
  final Widget action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(MasseDevTokens.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(MasseDevTokens.spaceMd),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Text(task.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                const SizedBox(width: MasseDevTokens.spaceSm),
                action,
              ]),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: MasseDevTokens.spaceXs),
                Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: MasseDevTokens.spaceSm),
              Wrap(spacing: MasseDevTokens.spaceSm, runSpacing: MasseDevTokens.spaceXs, children: [
                _Meta(icon: Icons.flag_outlined, label: task.priority.toUpperCase()),
                _Meta(icon: Icons.sync, label: task.status.replaceAll('_', ' ')),
                if (task.assigneeUsername != null) _Meta(icon: Icons.person_outline, label: task.assigneeUsername!),
                if (task.dueDate != null) _Meta(icon: Icons.event_outlined, label: MaterialLocalizations.of(context).formatMediumDate(task.dueDate!)),
              ]),
            ]),
          ),
        ),
      );
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ]),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(MasseDevTokens.spaceMd),
          child: Row(children: [
            const Icon(Icons.check_circle_outline),
            const SizedBox(width: MasseDevTokens.spaceSm),
            Expanded(child: Text(message)),
          ]),
        ),
      );
}

class _CreateTaskDialog extends StatefulWidget {
  const _CreateTaskDialog({required this.service, required this.team});
  final TaskService service;
  final TeamSummary team;

  @override
  State<_CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<_CreateTaskDialog> {
  final title = TextEditingController();
  final description = TextEditingController();
  String priority = 'medium';
  int? assignee;
  DateTime? dueDate;
  bool saving = false;
  String? error;

  Future<void> save() async {
    if (title.text.trim().isEmpty) {
      setState(() => error = 'Title is required.');
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      await widget.service.createTask(teamId: team.id, title: title.text.trim(), description: description.text.trim(), priority: priority, assignee: assignee, dueDate: dueDate);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('New task'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'Title')),
      const SizedBox(height: MasseDevTokens.spaceSm),
      TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
      const SizedBox(height: MasseDevTokens.spaceSm),
      DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(labelText: 'Priority'), items: const [
        DropdownMenuItem(value: 'low', child: Text('Low')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'high', child: Text('High')),
        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
      ], onChanged: saving ? null : (value) => setState(() => priority = value ?? 'medium')),
      ListTile(contentPadding: EdgeInsets.zero, title: const Text('Due date'), subtitle: Text(dueDate == null ? 'No due date' : MaterialLocalizations.of(context).formatMediumDate(dueDate!)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (dueDate != null) IconButton(tooltip: 'Clear due date', onPressed: saving ? null : () => setState(() => dueDate = null), icon: const Icon(Icons.clear)), IconButton(tooltip: 'Choose due date', onPressed: saving ? null : () async { final picked = await showDatePicker(context: context, initialDate: dueDate ?? DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650))); if (picked != null && mounted) setState(() => dueDate = picked); }, icon: const Icon(Icons.calendar_today))])),
      DropdownButtonFormField<int?>(initialValue: assignee, decoration: const InputDecoration(labelText: 'Assign to'), items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Shared pool')),
        ...widget.team.members.map((member) => DropdownMenuItem<int?>(value: member.userId, child: Text(member.username))),
      ], onChanged: saving ? null : (value) => setState(() => assignee = value)),
      if (error != null) ...[const SizedBox(height: MasseDevTokens.spaceSm), Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
    ])),
    actions: [
      TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
      FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Creating…' : 'Create')),
    ],
  );
}
