class Task {
  const Task({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.team,
    this.description = '',
    this.creator,
    this.creatorUsername,
    this.assignee,
    this.assigneeUsername,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final int team;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int? creator;
  final String? creatorUsername;
  final int? assignee;
  final String? assigneeUsername;
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        team: json['team'] as int,
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        status: json['status'] as String,
        priority: json['priority'] as String,
        creator: json['creator'] as int?,
        creatorUsername: json['creator_username'] as String?,
        assignee: json['assignee'] as int?,
        assigneeUsername: json['assignee_username'] as String?,
        dueDate: _date(json['due_date']),
        createdAt: _date(json['created_at']),
        updatedAt: _date(json['updated_at']),
      );

  static DateTime? _date(dynamic value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

class TaskActivity {
  const TaskActivity({
    required this.id,
    required this.event,
    required this.createdAt,
    this.actor,
    this.actorUsername,
    this.previousValue,
    this.newValue,
  });

  final int id;
  final String event;
  final int? actor;
  final String? actorUsername;
  final Map<String, dynamic>? previousValue;
  final Map<String, dynamic>? newValue;
  final DateTime createdAt;

  factory TaskActivity.fromJson(Map<String, dynamic> json) => TaskActivity(
        id: json['id'] as int,
        event: json['event'] as String,
        actor: json['actor'] as int?,
        actorUsername: json['actor_username'] as String?,
        previousValue: _map(json['previous_value']),
        newValue: _map(json['new_value']),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  static Map<String, dynamic>? _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
}
