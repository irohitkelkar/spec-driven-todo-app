import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_app/models/todo_item.dart';
import 'package:todo_app/services/todo_storage_service.dart';

void main() {
  group('TodoStorageService', () {
    final TodoStorageService service = TodoStorageService();

    test('loadTodos returns empty list when storage is empty', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final List<TodoItem> loaded = await service.loadTodos();

      expect(loaded, isEmpty);
    });

    test('loadTodos returns stored todos when data exists', () async {
      final DateTime now = DateTime.now();
      final List<TodoItem> todos = <TodoItem>[
        TodoItem(
          id: 'todo-1',
          title: 'Stored todo',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      SharedPreferences.setMockInitialValues(<String, Object>{
        'todos_v1': TodoItem.toRawJsonList(todos),
      });

      final List<TodoItem> loaded = await service.loadTodos();

      expect(loaded.length, 1);
      expect(loaded.first.id, 'todo-1');
      expect(loaded.first.title, 'Stored todo');
      expect(loaded.first.isCompleted, false);
    });

    test('saveTodos persists encoded todo data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final DateTime now = DateTime.now();

      final List<TodoItem> todos = <TodoItem>[
        TodoItem(
          id: 'todo-2',
          title: 'Persist me',
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      await service.saveTodos(todos);
      final String? raw = prefs.getString('todos_v1');

      expect(raw, isNotNull);
      final List<TodoItem> decoded = TodoItem.fromRawJsonList(raw!);
      expect(decoded.length, 1);
      expect(decoded.first.id, 'todo-2');
      expect(decoded.first.title, 'Persist me');
      expect(decoded.first.isCompleted, true);
    });
  });
}
