import '../../core/api/api_client.dart';

class AuthService {
  AuthService(this.api);
  final ApiClient api;

  Future<void> login(String username, String password) async {
    final data = await api.post('/auth/login/', {'username': username, 'password': password});
    api.accessToken = data['access'] as String;
  }
}
