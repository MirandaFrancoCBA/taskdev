import 'package:flutter_test/flutter_test.dart';
import 'package:taskdev/app.dart';

void main() {
  testWidgets('login only asks for credentials', (tester) async {
    await tester.pumpWidget(const TaskDevApp());
    expect(find.text('TaskDev'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Team ID'), findsNothing);
    expect(find.text('User ID'), findsNothing);
  });
}
