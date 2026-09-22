import 'package:flutter_test/flutter_test.dart';
import 'package:taskdev/app.dart';

void main() {
  testWidgets('renders login shell', (tester) async {
    await tester.pumpWidget(const TaskDevApp());
    expect(find.text('TaskDev'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
    expect(find.text('Username'), findsOneWidget);
  });
}
