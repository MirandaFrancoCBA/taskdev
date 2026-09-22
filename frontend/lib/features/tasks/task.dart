class Task {
  const Task({required this.id, required this.title, required this.status, required this.priority, required this.team, this.description = '', this.assignee});
  final int id;
  final int team;
  final String title;
  final String description;
  final String status;
  final String priority;
  final int? assignee;

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as int,
        team: json['team'] as int,
        title: json['title'] as String,
        description: (json['description'] ?? '') as String,
        status: json['status'] as String,
        priority: json['priority'] as String,
        assignee: json['assignee'] as int?,
      );
}
