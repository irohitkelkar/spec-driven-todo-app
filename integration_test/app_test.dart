import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/main.dart' as app;

void main() {
  final IntegrationTestWidgetsFlutterBinding binding =
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final bool needsSurfaceConversion =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  bool didConvertSurface = false;

  Future<void> takeStepScreenshot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    if (needsSurfaceConversion && !didConvertSurface) {
      await binding.convertFlutterSurfaceToImage();
      didConvertSurface = true;
      await tester.pump();
    }
    await binding.takeScreenshot(name);
  }

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

  testWidgets('Todo lifecycle with screenshots and persistence', (
    WidgetTester tester,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    app.main();
    await tester.pumpAndSettle();
    await takeStepScreenshot(tester, '01_empty_state');

    await tester.tap(find.byKey(const Key('add_todo_fab')));
    await tester.pumpAndSettle();
    await takeStepScreenshot(tester, '02_add_dialog_open');

    await tester.enterText(
      find.byKey(const Key('todo_input_field')),
      'Buy milk',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_todo_button')));
    await tester.pumpAndSettle();
    expect(find.text('Buy milk'), findsOneWidget);
    await takeStepScreenshot(tester, '03_todo_added');

    final String createdTodoId = firstTodoId(tester);
    final Finder completeCheckbox = find.byKey(
      Key('todo_checkbox_$createdTodoId'),
    );
    await tester.tap(completeCheckbox);
    await tester.pumpAndSettle();
    final Checkbox checkbox = tester.widget<Checkbox>(completeCheckbox);
    expect(checkbox.value, isTrue);
    await takeStepScreenshot(tester, '04_todo_completed');

    await tester.tap(find.byKey(Key('edit_todo_$createdTodoId')));
    await tester.pumpAndSettle();
    await takeStepScreenshot(tester, '05_edit_dialog_open');

    await tester.enterText(
      find.byKey(const Key('todo_input_field')),
      'Buy almond milk',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_todo_button')));
    await tester.pumpAndSettle();
    expect(find.text('Buy almond milk'), findsOneWidget);
    await takeStepScreenshot(tester, '06_todo_edited');

    app.main();
    await tester.pumpAndSettle();
    expect(find.text('Buy almond milk'), findsOneWidget);
    await takeStepScreenshot(tester, '07_persistence_verified');

    final String persistedTodoId = firstTodoId(tester);
    await tester.tap(find.byKey(Key('delete_todo_$persistedTodoId')));
    await tester.pumpAndSettle();
    expect(find.text('Buy almond milk'), findsNothing);
    await takeStepScreenshot(tester, '08_todo_deleted');
  });
}
