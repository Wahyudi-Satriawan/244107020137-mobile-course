import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/todo_provider.dart';

class TodoTile extends ConsumerWidget {
  const TodoTile({
    super.key,
    required this.todo,
  });

  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Checkbox(
        value: todo.done,
        onChanged: (_) {
          final index = ref.read(todoListProvider).indexOf(todo);
          if (index != -1) {
            ref.read(todoListProvider.notifier).toggle(index);
          }
        },
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () {
          final index = ref.read(todoListProvider).indexOf(todo);
          if (index != -1) {
            ref.read(todoListProvider.notifier).remove(index);
          }
        },
      ),
    );
  }
}