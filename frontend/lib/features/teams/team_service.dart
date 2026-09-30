import '../../core/api/api_client.dart';
import '../auth/auth_service.dart';

class TeamService {
  TeamService(this.api);
  final ApiClient api;

  Future<TeamSummary> addMember({
    required TeamSummary team,
    required int currentUserId,
    required int userId,
    required String role,
  }) async {
    await api.post('/teams/${team.id}/members/', {'user': userId, 'role': role});
    return _reload(team.id, currentUserId);
  }

  Future<TeamSummary> updateMember({
    required TeamSummary team,
    required int currentUserId,
    required int membershipId,
    required String role,
  }) async {
    await api.patch('/teams/${team.id}/members/$membershipId/', {'role': role});
    return _reload(team.id, currentUserId);
  }

  Future<void> removeMember({
    required TeamSummary team,
    required int membershipId,
  }) =>
      api.delete('/teams/${team.id}/members/$membershipId/');

  Future<TeamSummary> _reload(int teamId, int currentUserId) async =>
      TeamSummary.fromJson(await api.get('/teams/$teamId/'), currentUserId);
}
