// todo_list_item.dart

import 'package:br_todo/screens/todo_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodoListItem extends StatelessWidget {
  final Todo todo;
  final Function(bool?) onToggleComplete;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TodoListItem({
    Key? key,
    required this.todo,
    required this.onToggleComplete,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  Color _getPriorityColor(BuildContext context, String priority) {
    switch (priority) {
      case 'high':
        return Colors.red[700]!;
      case 'medium':
        return Colors.orange[700]!;
      case 'low':
        return Colors.blue[700]!;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Future<void> _updateSubtaskStatus(String todoId, String subtaskId, bool completed) async {
    final todoDoc = FirebaseFirestore.instance.collection('todos').doc(todoId);
    final todoData = (await todoDoc.get()).data();
    
    if (todoData != null) {
      final subtasks = List<Map<String, dynamic>>.from(todoData['subtasks']);
      final subtaskIndex = subtasks.indexWhere((s) => s['id'] == subtaskId);
      
      if (subtaskIndex != -1) {
        subtasks[subtaskIndex]['completed'] = completed;
        await todoDoc.update({'subtasks': subtasks});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSubtasks = todo.subtasks.isNotEmpty;
    final completedSubtasks = todo.subtasks.where((s) => s.completed).length;
    final hasDescription = todo.description.isNotEmpty;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Checkbox(
            value: todo.completed,
            onChanged: onToggleComplete,
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.completed ? TextDecoration.lineThrough : null,
              color: todo.completed
                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                  : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.flag,
                    size: 16,
                    color: _getPriorityColor(context, todo.priority),
                  ),
                  const SizedBox(width: 8),
                  if (hasSubtasks)
                    Text(
                      '$completedSubtasks/${todo.subtasks.length} subtasks',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              if (hasDescription) ...[
                const SizedBox(height: 4),
                Text(
                  todo.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
            ],
          ),
          children: [
            if (hasDescription)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    todo.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            if (hasSubtasks) ...[
              const Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todo.subtasks.length,
                itemBuilder: (context, index) {
                  final subtask = todo.subtasks[index];
                  return ListTile(
                    dense: true,
                    leading: Checkbox(
                      value: subtask.completed,
                      onChanged: (value) {
                        _updateSubtaskStatus(todo.id, subtask.id, value ?? false);
                      },
                    ),
                    title: Text(
                      subtask.title,
                      style: TextStyle(
                        decoration: subtask.completed ? TextDecoration.lineThrough : null,
                        color: subtask.completed
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}