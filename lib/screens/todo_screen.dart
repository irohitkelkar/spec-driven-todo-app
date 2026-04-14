import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import '../services/todo_storage_service.dart';
import '../widgets/todo_list_item.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TodoStorageService _storageService = TodoStorageService();
  List<TodoItem> _todos = <TodoItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final List<TodoItem> storedTodos = await _storageService.loadTodos();
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = storedTodos;
      _isLoading = false;
    });
  }

  Future<void> _showAddOrEditDialog({TodoItem? todo}) async {
    String draftTitle = todo?.title ?? '';
    final bool isEditing = todo != null;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Todo' : 'Add Todo'),
          content: TextFormField(
            key: const Key('todo_input_field'),
            initialValue: draftTitle,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'What needs to be done?',
            ),
            onChanged: (String value) => draftTitle = value,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('save_todo_button'),
              onPressed: () {
                final String title = draftTitle.trim();
                if (title.isEmpty) {
                  return;
                }
                _saveTodo(title: title, existingTodo: todo);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveTodo({
    required String title,
    TodoItem? existingTodo,
  }) async {
    final DateTime now = DateTime.now();
    late final List<TodoItem> updatedTodos;

    if (existingTodo == null) {
      final TodoItem todo = TodoItem(
        id: now.microsecondsSinceEpoch.toString(),
        title: title,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      );
      updatedTodos = <TodoItem>[..._todos, todo];
    } else {
      updatedTodos = _todos
          .map(
            (TodoItem todo) => todo.id == existingTodo.id
                ? todo.copyWith(title: title, updatedAt: now)
                : todo,
          )
          .toList();
    }

    await _storageService.saveTodos(updatedTodos);
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = updatedTodos;
    });
  }

  Future<void> _toggleTodo(TodoItem todo, bool isCompleted) async {
    final DateTime now = DateTime.now();
    final List<TodoItem> updatedTodos = _todos
        .map(
          (TodoItem item) => item.id == todo.id
              ? item.copyWith(isCompleted: isCompleted, updatedAt: now)
              : item,
        )
        .toList();

    await _storageService.saveTodos(updatedTodos);
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = updatedTodos;
    });
  }

  Future<void> _deleteTodo(String id) async {
    final List<TodoItem> updatedTodos = _todos
        .where((TodoItem todo) => todo.id != id)
        .toList();
    await _storageService.saveTodos(updatedTodos);
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = updatedTodos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todo App')),
      floatingActionButton: FloatingActionButton(
        key: const Key('add_todo_fab'),
        onPressed: () => _showAddOrEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
          ? const Center(child: Text('No todos yet'))
          : ListView.builder(
              itemCount: _todos.length,
              itemBuilder: (BuildContext context, int index) {
                final TodoItem todo = _todos[index];
                return TodoListItem(
                  todo: todo,
                  onToggleComplete: (bool value) => _toggleTodo(todo, value),
                  onEdit: () => _showAddOrEditDialog(todo: todo),
                  onDelete: () => _deleteTodo(todo.id),
                );
              },
            ),
    );
  }
}
