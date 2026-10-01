import 'package:flutter/material.dart';

import '../../core/theme/masse_dev_theme.dart';
import 'task.dart';
import 'task_service.dart';
import 'task_realtime_service.dart';

class TaskDetailScreen extends StatefulWidget {
  const TaskDetailScreen({super.key, required this.task, required this.service});

  final Task task;
  final TaskService service;

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late Task task = widget.task;
  List<TaskActivity> activity = const [];
  TaskRealtimeService? realtime;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
    realtime = TaskRealtimeService(
      teamId: task.team,
      accessTokenProvider: () => widget.service.api.accessToken,
      onTaskEvent: _refreshFromRealtime,
    )..connect();
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final results = await Future.wait<dynamic>([
        widget.service.getTask(task.id),
        widget.service.listActivity(task.id),
      ]);
      if (mounted) {
        setState(() {
          task = results[0] as Task;
          activity = results[1] as List<TaskActivity>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _refreshFromRealtime() async {
    try {
      final results = await Future.wait<dynamic>([
        widget.service.getTask(task.id),
        widget.service.listActivity(task.id),
      ]);
      if (mounted) {
        setState(() {
          task = results[0] as Task;
          activity = results[1] as List<TaskActivity>;
          error = null;
        });
      }
    } catch (_) {
      // Keep the last good detail state; REST/manual refresh remains available.
    }
  }

  @override
  void dispose() {
    realtime?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task details')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(MasseDevTokens.spaceMd),
          children: [
            Text(task.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: MasseDevTokens.spaceSm),
              Text(task.description),
            ],
            const SizedBox(height: MasseDevTokens.spaceMd),
            Wrap(
              spacing: MasseDevTokens.spaceSm,
              runSpacing: MasseDevTokens.spaceSm,
              children: [
                Chip(label: Text(task.priority.toUpperCase())),
                Chip(label: Text(task.status.replaceAll('_', ' '))),
                if (task.assigneeUsername != null) Chip(avatar: const Icon(Icons.person, size: 18), label: Text(task.assigneeUsername!)),
                if (task.dueDate != null) Chip(avatar: const Icon(Icons.event, size: 18), label: Text(_date(context, task.dueDate!))),
              ],
            ),
            const SizedBox(height: MasseDevTokens.spaceLg),
            Text('Activity', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: MasseDevTokens.spaceSm),
            if (loading) const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
            if (error != null) Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              Text(error!),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
            ]))),
            if (!loading && error == null && activity.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No activity has been recorded yet.'))),
            if (!loading && error == null)
              ...activity.reversed.map((item) => _ActivityTile(activity: item)),
          ],
        ),
      ),
    );
  }

  String _date(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context).formatMediumDate(value);
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity});
  final TaskActivity activity;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: MasseDevTokens.spaceSm),
        child: ListTile(
          leading: CircleAvatar(child: Icon(_icon(activity.event))),
          title: Text(_label(activity.event)),
          subtitle: Text('${activity.actorUsername ?? 'System'} · ${_timestamp(context, activity.createdAt)}${_changeSummary(activity)}'),
        ),
      );

  static IconData _icon(String event) => switch (event) {
        'created' => Icons.add_task,
        'claimed' => Icons.front_hand,
        'assignee_changed' => Icons.person_outline,
        'completed' => Icons.task_alt,
        _ => Icons.sync,
      };

  static String _label(String event) => switch (event) {
        'created' => 'Task created',
        'claimed' => 'Task claimed',
        'assignee_changed' => 'Assignee changed',
        'status_changed' => 'Status changed',
        'completed' => 'Task completed',
        _ => event.replaceAll('_', ' '),
      };

  static String _timestamp(BuildContext context, DateTime value) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatMediumDate(value)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(value))}';
  }

  static String _changeSummary(TaskActivity activity) {
    final before = activity.previousValue;
    final after = activity.newValue;
    if (before == null && after == null) return '';
    if (before?['status'] != null || after?['status'] != null) {
      return '\n${before?['status'] ?? '—'} → ${after?['status'] ?? '—'}';
    }
    if (before?['assignee_id'] != null || after?['assignee_id'] != null) {
      return '\nAssignee #${before?['assignee_id'] ?? '—'} → #${after?['assignee_id'] ?? '—'}';
    }
    return '';
  }
}
