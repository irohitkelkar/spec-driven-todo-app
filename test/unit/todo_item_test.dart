import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/models/todo_item.dart';

void main() {
  group('TodoItem', () {
    test('serializes and deserializes a list of todos', () {
      final DateTime now = DateTime.now();
      final List<TodoItem> original = <TodoItem>[
        TodoItem(
          id: '1',
          title: 'Buy milk',
          isCompleted: false,
          createdAt: now,
          updatedAt: now,
        ),
        TodoItem(
          id: '2',
          title: 'Walk dog',
          isCompleted: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

      final String raw = TodoItem.toRawJsonList(original);
      final List<TodoItem> decoded = TodoItem.fromRawJsonList(raw);

      expect(decoded.length, 2);
      expect(decoded.first.id, '1');
      expect(decoded.first.title, 'Buy milk');
      expect(decoded.first.isCompleted, false);
      expect(decoded.last.id, '2');
      expect(decoded.last.title, 'Walk dog');
      expect(decoded.last.isCompleted, true);
    });

    test('copyWith updates selected fields only', () {
      final DateTime now = DateTime.now();
      final TodoItem base = TodoItem(
        id: 'todo-id',
        title: 'Original',
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      final DateTime updatedAt = now.add(const Duration(minutes: 2));

      final TodoItem updated = base.copyWith(
        title: 'Updated',
        isCompleted: true,
        updatedAt: updatedAt,
      );

      expect(updated.id, 'todo-id');
      expect(updated.title, 'Updated');
      expect(updated.isCompleted, true);
      expect(updated.createdAt, now);
      expect(updated.updatedAt, updatedAt);
    });
  });
}
