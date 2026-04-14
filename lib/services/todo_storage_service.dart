import 'package:shared_preferences/shared_preferences.dart';

import '../models/todo_item.dart';

class TodoStorageService {
  static const String _storageKey = 'todos_v1';

  Future<List<TodoItem>> loadTodos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rawTodos = prefs.getString(_storageKey);
    if (rawTodos == null || rawTodos.isEmpty) {
      return <TodoItem>[];
    }

    return TodoItem.fromRawJsonList(rawTodos);
  }

  Future<void> saveTodos(List<TodoItem> todos) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, TodoItem.toRawJsonList(todos));
  }
}
