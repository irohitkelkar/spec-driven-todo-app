import 'dart:convert';

class TodoItem {
  TodoItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoItem copyWith({String? title, bool? isCompleted, DateTime? updatedAt}) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static List<TodoItem> fromRawJsonList(String rawJson) {
    final List<dynamic> decoded = jsonDecode(rawJson) as List<dynamic>;
    return decoded
        .map((dynamic item) => TodoItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static String toRawJsonList(List<TodoItem> todos) {
    final List<Map<String, dynamic>> list = todos
        .map((TodoItem todo) => todo.toJson())
        .toList();
    return jsonEncode(list);
  }
}
