import '../../core/api/api_client.dart';
import 'task.dart';

class TaskService {
  TaskService(this.api);
  final ApiClient api;

  Future<List<Task>> listTasks(int teamId) async {
    final data = await api.getList('/tasks/?team=$teamId');
    return data.map((item) => Task.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask({required int teamId, required String title, String description = '', String priority = 'medium', int? assignee, DateTime? dueDate}) async {
    final body = <String, dynamic>{'team': teamId, 'title': title, 'description': description, 'priority': priority};
    if (assignee != null) body['assignee'] = assignee;
    if (dueDate != null) {
      body['due_date'] = '${dueDate.year.toString().padLeft(4, '0')}-${dueDate.month.toString().padLeft(2, '0')}-${dueDate.day.toString().padLeft(2, '0')}';
    }
    return Task.fromJson(await api.post('/tasks/', body));
  }

  Future<Task> claim(int taskId) async => Task.fromJson(await api.post('/tasks/$taskId/claim/', {}));

  Future<Task> setStatus(int taskId, String status) async => Task.fromJson(await api.patch('/tasks/$taskId/', {'status': status}));
}
