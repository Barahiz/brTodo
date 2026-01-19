// todo_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String listId;
  final String priority; // 'high', 'medium', 'low'
  final DateTime createdAt;
  final List<Subtask> subtasks;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.completed,
    required this.listId,
    required this.priority,
    required this.createdAt,
    required this.subtasks,
  });

  factory Todo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convert subtasks from Firestore
    List<Subtask> subtasks = [];
    if (data['subtasks'] != null) {
      subtasks = (data['subtasks'] as List).map((subtask) => 
        Subtask(
          id: subtask['id'],
          title: subtask['title'],
          completed: subtask['completed'],
        )
      ).toList();
    }

    return Todo(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      completed: data['completed'] ?? false,
      listId: data['listId'] ?? '',
      priority: data['priority'] ?? 'medium',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      subtasks: subtasks,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'completed': completed,
      'listId': listId,
      'priority': priority,
      'createdAt': createdAt,
      'subtasks': subtasks.map((subtask) => subtask.toMap()).toList(),
    };
  }
}

class Subtask {
  final String id;
  final String title;
  final bool completed;

  Subtask({
    required this.id,
    required this.title,
    required this.completed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }
}