// todo_list_screen.dart
import 'package:br_todo/screens/todo_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:br_todo/providers/theme_provider.dart';
import 'package:br_todo/screens/todo_service.dart';
import 'todo_dialog.dart';
import 'todo_list_item.dart';
import 'package:uuid/uuid.dart';

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  String? _selectedListId;
  final _todoService = TodoService();
  final _formKey = GlobalKey<FormState>();
  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    if (_selectedListId != null) {
      // If we're in a list, go back to lists view
      setState(() => _selectedListId = null);
      return false;
    } else {
      // If we're in lists view, show toast and handle double back press
      if (_lastBackPressTime == null || 
          DateTime.now().difference(_lastBackPressTime!) > Duration(seconds: 2)) {
        // First back press
        _lastBackPressTime = DateTime.now();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
          ),
        );
        return false;
      }
      return true; // Exit app on second back press
    }
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: _selectedListId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    setState(() => _selectedListId = null);
                  },
                )
              : null,
          title: Text(
            _selectedListId != null ? 'Tasks' : 'My Lists',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _selectedListId == null ? _buildListsView() : _buildTodoList(),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream: _todoService.getTodoLists(),
        builder: (context, snapshot) {
          final lists = snapshot.data?.docs ?? [];
          final showFab = _selectedListId != null || lists.isNotEmpty;

          return showFab
              ? FloatingActionButton.extended(
                  onPressed: () {
                    if (_selectedListId != null) {
                      showDialog(
                        context: context,
                        builder: (context) => TodoDialog(listId: _selectedListId!),
                      );
                    } else {
                      _showAddListDialog(context);
                    }
                  },
                  label: Text(_selectedListId != null ? 'Add Task' : 'Add List'),
                  icon: const Icon(Icons.add),
                )
              : const SizedBox.shrink();
        },
      ),
      ));
  }

  Widget _buildListsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _todoService.getTodoLists(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final lists = snapshot.data?.docs ?? [];

        if (lists.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No lists yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create a list to get started',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showAddListDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Create New List'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: Text(list['title']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteList(list.id),
                    ),
                    onTap: () {
                      setState(() => _selectedListId = list.id);
                    },
                  ),
                  // Stream builder for todo previews
                  StreamBuilder<QuerySnapshot>(
                    stream: _todoService.getTodos(list.id),
                    builder: (context, todoSnapshot) {
                      if (!todoSnapshot.hasData || todoSnapshot.data!.docs.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      final todos = todoSnapshot.data!.docs.take(3).toList();
                      return Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            ...todos.map((todo) {
                              final todoData = todo.data() as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      todoData['completed'] ? 
                                        Icons.check_circle_outline : 
                                        Icons.radio_button_unchecked,
                                      size: 16,
                                      color: todoData['completed'] ? 
                                        Colors.green : 
                                        Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        todoData['title'],
                                        style: TextStyle(
                                          decoration: todoData['completed'] ? 
                                            TextDecoration.lineThrough : null,
                                          color: todoData['completed'] ? 
                                            Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : 
                                            Theme.of(context).colorScheme.onSurface,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            if (todoSnapshot.data!.docs.length > 3)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '+ ${todoSnapshot.data!.docs.length - 3} more tasks',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget _buildDrawer() {
  //   return Drawer(
  //     child: Column(
  //       children: [
  //         DrawerHeader(
  //           decoration: BoxDecoration(
  //             color: Theme.of(context).colorScheme.primaryContainer,
  //           ),
  //           child: Center(
  //             child: Text(
  //               'My Todo Lists',
  //               style: Theme.of(context).textTheme.headlineSmall?.copyWith(
  //                     color: Theme.of(context).colorScheme.onPrimaryContainer,
  //                   ),
  //             ),
  //           ),
  //         ),
  //         Expanded(
  //           child: StreamBuilder<QuerySnapshot>(
  //             stream: _todoService.getTodoLists(),
  //             builder: (context, snapshot) {
  //               if (snapshot.hasError) {
  //                 return Center(child: Text('Error: ${snapshot.error}'));
  //               }

  //               if (snapshot.connectionState == ConnectionState.waiting) {
  //                 return const Center(child: CircularProgressIndicator());
  //               }

  //               final lists = snapshot.data?.docs ?? [];

  //               if (lists.isEmpty) {
  //                 return const Center(
  //                   child: Padding(
  //                     padding: EdgeInsets.all(16.0),
  //                     child: Text(
  //                       'No lists yet. Create one to get started!',
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ),
  //                 );
  //               }

  //               return ListView.builder(
  //                 padding: EdgeInsets.zero,
  //                 itemCount: lists.length,
  //                 itemBuilder: (context, index) {
  //                   final list = lists[index];
  //                   final isSelected = _selectedListId == list.id;
                    
  //                   return ListTile(
  //                     selected: isSelected,
  //                     selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
  //                     leading: Icon(
  //                       isSelected ? Icons.folder_open : Icons.folder,
  //                       color: isSelected
  //                           ? Theme.of(context).colorScheme.primary
  //                           : null,
  //                     ),
  //                     title: Text(list['title']),
  //                     onTap: () {
  //                       setState(() => _selectedListId = list.id);
  //                       if (MediaQuery.of(context).size.width < 600) {
  //                         Navigator.pop(context);
  //                       }
  //                     },
  //                     trailing: IconButton(
  //                       icon: const Icon(Icons.delete_outline),
  //                       onPressed: () => _deleteList(list.id),
  //                     ),
  //                   );
  //                 },
  //               );
  //             },
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTodoList() {
    if (_selectedListId == null) {
      return _buildWelcomeScreen();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _todoService.getTodos(_selectedListId!),
      builder: (context, snapshot) {
        // Handle errors
        if (snapshot.hasError) {
          // If we get a permission error, it likely means the list was deleted
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                const Text('Unable to load tasks'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => setState(() => _selectedListId = null),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final todos = snapshot.data?.docs ?? [];

        if (todos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add a task to get started',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                // ElevatedButton.icon(
                //   onPressed: () {
                //     showDialog(
                //       context: context,
                //       builder: (context) => TodoDialog(listId: _selectedListId!),
                //     );
                //   },
                //   icon: const Icon(Icons.add),
                //   label: const Text('Add Task'),
                // ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: todos.length,
          itemBuilder: (context, index) {
            final todoDoc = todos[index];
            final todo = Todo.fromFirestore(todoDoc);

            return TodoListItem(
              todo: todo,
              onToggleComplete: (value) {
                _todoService.toggleTodoStatus(todo.id, value ?? false);
              },
              onDelete: () => _deleteTodo(todo.id),
              onEdit: () {
                showDialog(
                  context: context,
                  builder: (context) => TodoDialog(
                    listId: _selectedListId!,
                    todo: todo,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to Your Todo Lists',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Select a list or create a new one to get started',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddListDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Create New List'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddListDialog(BuildContext context) async {
    final textController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New List'),
        content: Form(
          key: _formKey,
          child: TextFormField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'List Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a list name';
              }
              return null;
            },
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                _todoService.createTodoList(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

   @override
  void dispose() {
    _todoService.dispose();
    super.dispose();
  }

  Future<void> _deleteList(String listId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text('Are you sure you want to delete this list and all its tasks?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      try {
        // First clear the selected list ID
        setState(() => _selectedListId = null);
        
        // Then delete the list and its todos
        await _todoService.deleteTodoList(listId);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('List deleted successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        
      }
    }
  }


  Future<void> _deleteTodo(String todoId) async {
    await _todoService.deleteTodo(todoId);
  }
}