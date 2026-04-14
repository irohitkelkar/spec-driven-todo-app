import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/main.dart' as app;

void main() {
  testWidgets('Todo app launches', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Todo App'), findsOneWidget);
    expect(find.byKey(const Key('add_todo_fab')), findsOneWidget);
  });
}
