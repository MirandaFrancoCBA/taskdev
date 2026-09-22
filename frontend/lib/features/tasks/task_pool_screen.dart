import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../auth/auth_service.dart';
import '../auth/login_screen.dart';
import 'task.dart';
import 'task_service.dart';
import 'task_realtime_service.dart';

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
  List<Task> tasks = const [];
  bool loading = true;
  String? error;
  TaskRealtimeService? realtime;

  @override
  void initState() {
    super.initState();
    refresh();
    final token = widget.api.accessToken;
    if (token != null) {
      realtime = TaskRealtimeService(teamId: widget.team.id, accessToken: token, onTaskEvent: _refreshFromRealtime)..connect();
    }
  }

  Future<void> _refreshFromRealtime() async {
    try {
      final result = await service.listTasks(widget.team.id);
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
      final result = await service.listTasks(widget.team.id);
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
    final created = await showDialog<bool>(context: context, builder: (_) => _CreateTaskDialog(service: service, team: widget.team));
    if (created == true) await refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(appBar: AppBar(title: const Text('TaskDev')), body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), const SizedBox(height: 16), FilledButton(onPressed: refresh, child: const Text('Retry'))]))));

    final available = tasks.where((task) => task.assignee == null && task.status == 'pending').toList();
    final mine = tasks.where((task) => task.assignee == widget.userId && task.status != 'completed').toList();

    return Scaffold(
      floatingActionButton: widget.team.role == 'coordinator' ? FloatingActionButton.extended(onPressed: createTask, icon: const Icon(Icons.add), label: const Text('New task')) : null,
      appBar: AppBar(title: Text(widget.team.name), actions: [IconButton(onPressed: refresh, icon: const Icon(Icons.refresh)), IconButton(tooltip: 'Log out', onPressed: () async { await AuthService(widget.api).logout(); if (!context.mounted) return; Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => LoginScreen(api: widget.api)), (_) => false); }, icon: const Icon(Icons.logout))]),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('My work', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (mine.isEmpty) const _EmptyCard(message: 'You have no active tasks.'),
            ...mine.map((task) => _TaskCard(task: task, action: PopupMenuButton<String>(onSelected: (value) => changeStatus(task, value), itemBuilder: (_) => const [PopupMenuItem(value: 'in_progress', child: Text('In progress')), PopupMenuItem(value: 'blocked', child: Text('Blocked')), PopupMenuItem(value: 'completed', child: Text('Complete'))], child: const Padding(padding: EdgeInsets.all(8), child: Text('Update'))))),
            const SizedBox(height: 24),
            Text('Available', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (available.isEmpty) const _EmptyCard(message: 'No tasks are waiting in the pool.'),
            ...available.map((task) => _TaskCard(task: task, action: FilledButton(onPressed: () => claim(task), child: const Text('Take')))),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task, required this.action});
  final Task task;
  final Widget action;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title, style: Theme.of(context).textTheme.titleMedium),
              if (task.description.isNotEmpty) ...[const SizedBox(height: 6), Text(task.description)],
              const SizedBox(height: 8),
              Text('${task.priority.toUpperCase()} · ${task.status.replaceAll('_', ' ')}', style: Theme.of(context).textTheme.labelMedium),
            ])),
            const SizedBox(width: 12),
            action,
          ]),
        ),
      );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(20), child: Text(message)));
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
  bool saving = false;
  String? error;

  Future<void> save() async {
    if (title.text.trim().isEmpty) {
      setState(() => error = 'Title is required.');
      return;
    }
    setState(() { saving = true; error = null; });
    try {
      await widget.service.createTask(teamId: widget.team.id, title: title.text.trim(), description: description.text.trim(), priority: priority, assignee: assignee);
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
      TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
      DropdownButtonFormField<String>(initialValue: priority, decoration: const InputDecoration(labelText: 'Priority'), items: const [
        DropdownMenuItem(value: 'low', child: Text('Low')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'high', child: Text('High')),
        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
      ], onChanged: saving ? null : (value) => setState(() => priority = value ?? 'medium')),
      DropdownButtonFormField<int?>(initialValue: assignee, decoration: const InputDecoration(labelText: 'Assign to'), items: [
        const DropdownMenuItem<int?>(value: null, child: Text('Shared pool')),
        ...widget.team.members.map((member) => DropdownMenuItem<int?>(value: member.userId, child: Text(member.username))),
      ], onChanged: saving ? null : (value) => setState(() => assignee = value)),
      if (error != null) ...[const SizedBox(height: 12), Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))],
    ])),
    actions: [
      TextButton(onPressed: saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
      FilledButton(onPressed: saving ? null : save, child: Text(saving ? 'Creating…' : 'Create')),
    ],
  );
}
