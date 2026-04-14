import 'package:flutter/material.dart';

import '../models/todo_item.dart';

class TodoListItem extends StatelessWidget {
  const TodoListItem({
    super.key,
    required this.todo,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  final TodoItem todo;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: Key('todo_item_${todo.id}'),
      leading: Checkbox(
        key: Key('todo_checkbox_${todo.id}'),
        value: todo.isCompleted,
        onChanged: (bool? value) => onToggleComplete(value ?? false),
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            key: Key('edit_todo_${todo.id}'),
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            tooltip: 'Edit',
          ),
          IconButton(
            key: Key('delete_todo_${todo.id}'),
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
