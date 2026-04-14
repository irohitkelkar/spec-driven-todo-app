import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  String firstTodoId(WidgetTester tester) {
    final Iterable<Element> matches = find.byWidgetPredicate((Widget widget) {
      final Key? key = widget.key;
      if (key is! ValueKey<String>) {
        return false;
      }
      return key.value.startsWith('todo_item_');
    }).evaluate();

    expect(matches, isNotEmpty);
    final ValueKey<String> key = matches.first.widget.key! as ValueKey<String>;
    return key.value.substring('todo_item_'.length);
  }

  testWidgets('Todo lifecycle for coverage', (WidgetTester tester) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add_todo_fab')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('todo_input_field')),
      'Coverage todo',
    );
    await tester.tap(find.byKey(const Key('save_todo_button')));
    await tester.pumpAndSettle();
    expect(find.text('Coverage todo'), findsOneWidget);

    final String todoId = firstTodoId(tester);
    await tester.tap(find.byKey(Key('todo_checkbox_$todoId')));
    await tester.pumpAndSettle();
    final Checkbox checkbox = tester.widget<Checkbox>(
      find.byKey(Key('todo_checkbox_$todoId')),
    );
    expect(checkbox.value, true);

    await tester.tap(find.byKey(Key('edit_todo_$todoId')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('todo_input_field')),
      'Coverage todo edited',
    );
    await tester.tap(find.byKey(const Key('save_todo_button')));
    await tester.pumpAndSettle();
    expect(find.text('Coverage todo edited'), findsOneWidget);

    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Coverage todo edited'), findsOneWidget);

    final String persistedId = firstTodoId(tester);
    await tester.tap(find.byKey(Key('delete_todo_$persistedId')));
    await tester.pumpAndSettle();
    expect(find.text('Coverage todo edited'), findsNothing);
  });
}
