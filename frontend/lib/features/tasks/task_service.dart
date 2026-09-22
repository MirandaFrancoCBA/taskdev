import '../../core/api/api_client.dart';
import 'task.dart';

class TaskService {
  TaskService(this.api);
  final ApiClient api;

  Future<List<Task>> listTasks(int teamId) async {
    final data = await api.getList('/tasks/?team=$teamId');
    return data.map((item) => Task.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Task> claim(int taskId) async => Task.fromJson(await api.post('/tasks/$taskId/claim/'));

  Future<Task> setStatus(int taskId, String status) async => Task.fromJson(await api.patch('/tasks/$taskId/', {'status': status}));
}
