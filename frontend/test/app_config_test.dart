import 'package:flutter_test/flutter_test.dart';
import 'package:taskdev/core/config/app_config.dart';

void main() {
  test('websocket URL uses team path without credentials in query parameters', () {
    final uri = AppConfig.websocketUri(7);
    expect(uri.scheme, anyOf('ws', 'wss'));
    expect(uri.path, '/ws/teams/7/tasks/');
    expect(uri.queryParameters, isEmpty);
    expect(uri.toString(), isNot(contains('token=')));
  });
}
