// todo_dialog.dart

import 'package:br_todo/screens/todo_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class TodoDialog extends StatefulWidget {
  final String listId;
  final Todo? todo; // Pass existing todo for editing

  const TodoDialog({
    Key? key,
    required this.listId,
    this.todo,
  }) : super(key: key);

  @override
  _TodoDialogState createState() => _TodoDialogState();
}

class _TodoDialogState extends State<TodoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();
  String _priority = 'medium';
  List<Subtask> _subtasks = [];

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      _titleController.text = widget.todo!.title;
      _descriptionController.text = widget.todo!.description;
      _priority = widget.todo!.priority;
      _subtasks = List.from(widget.todo!.subtasks);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.todo == null ? 'New Task' : 'Edit Task',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'high',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          const Text('High'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text('Medium'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'low',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text('Low'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _priority = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Subtasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _subtaskController,
                        decoration: const InputDecoration(
                          labelText: 'Add Subtask',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_subtaskController.text.isNotEmpty) {
                          setState(() {
                            _subtasks.add(Subtask(
                              id: const Uuid().v4(),
                              title: _subtaskController.text,
                              completed: false,
                            ));
                            _subtaskController.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _subtasks.length,
                    itemBuilder: (context, index) {
                      final subtask = _subtasks[index];
                      return ListTile(
                        dense: true,
                        leading: Checkbox(
                          value: subtask.completed,
                          onChanged: (value) {
                            setState(() {
                              _subtasks[index] = Subtask(
                                id: subtask.id,
                                title: subtask.title,
                                completed: value!,
                              );
                            });
                          },
                        ),
                        title: Text(subtask.title),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              _subtasks.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _saveTodo,
                      child: Text(widget.todo == null ? 'Create' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveTodo() async {
    if (_formKey.currentState!.validate()) {
      final todoData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'priority': _priority,
        'completed': widget.todo?.completed ?? false,
        'listId': widget.listId,
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'createdAt': widget.todo?.createdAt ?? FieldValue.serverTimestamp(),
        'subtasks': _subtasks.map((subtask) => subtask.toMap()).toList(),
      };

      if (widget.todo == null) {
        // Create new todo
        await FirebaseFirestore.instance.collection('todos').add(todoData);
      } else {
        // Update existing todo
        await FirebaseFirestore.instance
            .collection('todos')
            .doc(widget.todo!.id)
            .update(todoData);
      }

      Navigator.of(context).pop();
    }
  }
}