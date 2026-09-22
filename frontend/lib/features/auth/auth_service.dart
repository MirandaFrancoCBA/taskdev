import '../../core/api/api_client.dart';

class AuthContext {
  const AuthContext({required this.userId, required this.teams});
  final int userId;
  final List<TeamSummary> teams;
}

class TeamSummary {
  const TeamSummary({required this.id, required this.name});
  final int id;
  final String name;
  factory TeamSummary.fromJson(Map<String, dynamic> json) => TeamSummary(id: json['id'] as int, name: json['name'] as String);
}

class AuthService {
  AuthService(this.api);
  final ApiClient api;

  Future<AuthContext> login(String username, String password) async {
    final tokens = await api.post('/auth/login/', {'username': username, 'password': password});
    api.accessToken = tokens['access'] as String;
    final user = await api.get('/auth/me/');
    final teamData = await api.getList('/teams/');
    return AuthContext(
      userId: user['id'] as int,
      teams: teamData.map((item) => TeamSummary.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
