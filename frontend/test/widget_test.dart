import 'package:flutter_test/flutter_test.dart';
import 'package:taskdev/app.dart';
void main() { testWidgets('renders TaskDev shell', (tester) async { await tester.pumpWidget(const TaskDevApp()); await tester.pumpAndSettle(); expect(find.text('TaskDev'), findsOneWidget); expect(find.text('What needs to be done now?'), findsOneWidget); }); }
