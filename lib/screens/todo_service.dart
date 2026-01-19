// todo_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TodoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _todosSubscription;

  // Get user's todo lists
  Stream<QuerySnapshot> getTodoLists() {
    return _firestore
        .collection('todo_lists')
        .where('userId', isEqualTo: _auth.currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get todos for a specific list
  Stream<QuerySnapshot>? getTodos(String? listId) {
    if (listId == null) return null;
    return _firestore
        .collection('todos')
        .where('listId', isEqualTo: listId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Create a new todo list
  Future<void> createTodoList(String title) {
    return _firestore.collection('todo_lists').add({
      'title': title,
      'userId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Create a new todo
  Future<void> createTodo({
    required String listId,
    required String title,
    required String description,
    required String priority,
    required List<Map<String, dynamic>> subtasks,
  }) {
    return _firestore.collection('todos').add({
      'title': title,
      'description': description,
      'completed': false,
      'listId': listId,
      'userId': _auth.currentUser?.uid,
      'priority': priority,
      'createdAt': FieldValue.serverTimestamp(),
      'subtasks': subtasks,
    });
  }

  // Update an existing todo
  Future<void> updateTodo({
    required String todoId,
    required String title,
    required String description,
    required String priority,
    required bool completed,
    required List<Map<String, dynamic>> subtasks,
  }) {
    return _firestore.collection('todos').doc(todoId).update({
      'title': title,
      'description': description,
      'priority': priority,
      'completed': completed,
      'subtasks': subtasks,
    });
  }

  // Toggle todo completion status
  Future<void> toggleTodoStatus(String todoId, bool completed) {
    return _firestore
        .collection('todos')
        .doc(todoId)
        .update({'completed': completed});
  }

  // Update subtask status
  Future<void> updateSubtaskStatus(String todoId, String subtaskId, bool completed) async {
    final todoDoc = _firestore.collection('todos').doc(todoId);
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

  // Delete a todo list and all its todos
  Future<void> deleteTodoList(String listId) async {
    // Cancel the existing subscription if any
    await _todosSubscription?.cancel();
    _todosSubscription = null;

    // Delete the list
    await _firestore.collection('todo_lists').doc(listId).delete();

    // Delete all todos in the list using a batch
    final todosQuery = await _firestore
        .collection('todos')
        .where('listId', isEqualTo: listId)
        .get();

    if (todosQuery.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (var doc in todosQuery.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  // Delete a single todo
  Future<void> deleteTodo(String todoId) {
    return _firestore.collection('todos').doc(todoId).delete();
  }

  void dispose() {
    _todosSubscription?.cancel();
  }
}