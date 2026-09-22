class AppConfig {
  const AppConfig._();

  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000/api');

  static Uri websocketUri(int teamId, String token) {
    final api = Uri.parse(apiBaseUrl);
    final scheme = api.scheme == 'https' ? 'wss' : 'ws';
    return Uri(
      scheme: scheme,
      host: api.host,
      port: api.hasPort ? api.port : null,
      path: '/ws/teams/$teamId/tasks/',
      queryParameters: {'token': token},
    );
  }
}
