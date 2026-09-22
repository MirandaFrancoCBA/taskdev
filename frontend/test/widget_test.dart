import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskdev/core/api/api_client.dart';
import 'package:taskdev/features/auth/login_screen.dart';

void main() {
  testWidgets('login only asks for credentials', (tester) async {
    await tester.pumpWidget(MaterialApp(home: LoginScreen(api: ApiClient())));

    expect(find.text('TaskDev'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Team ID'), findsNothing);
    expect(find.text('User ID'), findsNothing);
  });
}
