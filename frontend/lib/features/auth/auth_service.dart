import '../../core/api/api_client.dart';
import 'session_store.dart';

class AuthContext {
  const AuthContext({required this.userId, required this.teams});
  final int userId;
  final List<TeamSummary> teams;
}

class TeamSummary {
  const TeamSummary({required this.id, required this.name, required this.role, required this.members});
  final int id;
  final String name;
  final String role;
  final List<TeamMember> members;

  factory TeamSummary.fromJson(Map<String, dynamic> json, int userId) {
    final memberships = (json['memberships'] as List<dynamic>? ?? const []);
    final members = memberships.map((item) => TeamMember.fromJson(item as Map<String, dynamic>)).toList();
    final mine = members.where((member) => member.userId == userId);
    return TeamSummary(id: json['id'] as int, name: json['name'] as String, role: mine.isEmpty ? 'member' : mine.first.role, members: members);
  }
}

class TeamMember {
  const TeamMember({required this.userId, required this.username, required this.role});
  final int userId;
  final String username;
  final String role;
  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(userId: json['user'] as int, username: json['username'] as String, role: json['role'] as String);
}

class AuthService {
  AuthService(this.api, {SessionStore? store}) : store = store ?? SessionStore() {
    api.refreshAccessToken = refresh;
  }
  final ApiClient api;
  final SessionStore store;

  Future<AuthContext> login(String username, String password) async {
    final tokens = await api.post('/auth/login/', {'username': username, 'password': password}, retry: false);
    final access = tokens['access'] as String;
    final refreshToken = tokens['refresh'] as String;
    api.accessToken = access;
    await store.save(access: access, refresh: refreshToken);
    return loadContext();
  }

  Future<AuthContext?> restore() async {
    api.accessToken = await store.readAccess();
    if (api.accessToken == null && !await refresh()) return null;
    try {
      return await loadContext();
    } on ApiException catch (error) {
      if (error.statusCode == 401) await logout();
      return null;
    }
  }

  Future<bool> refresh() async {
    final refreshToken = await store.readRefresh();
    if (refreshToken == null) return false;
    try {
      final data = await api.post('/auth/refresh/', {'refresh': refreshToken}, retry: false);
      final access = data['access'] as String;
      api.accessToken = access;
      await store.save(access: access, refresh: (data['refresh'] as String?) ?? refreshToken);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<AuthContext> loadContext() async {
    final user = await api.get('/auth/me/');
    final teamData = await api.getList('/teams/');
    return AuthContext(userId: user['id'] as int, teams: teamData.map((item) => TeamSummary.fromJson(item as Map<String, dynamic>, user['id'] as int)).toList());
  }

  Future<void> logout() async {
    api.accessToken = null;
    await store.clear();
  }
}
