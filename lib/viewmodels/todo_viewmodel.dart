import 'package:flutter/material.dart';
import '../models/todo_model.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class TodoViewModel extends ChangeNotifier {
  final DatabaseService _databaseService;
  final EncryptionService _encryptionService;
  List<TodoModel> _todos = [];

  List<TodoModel> get todos => _todos;

  TodoViewModel(this._databaseService, this._encryptionService) {
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    _todos = await _databaseService.getTodos();
    notifyListeners();
  }

  Future<void> addTodo(String title, String secretNotes) async {
    debugPrint('--- AES-256 ENCRYPTION PROOF ---');
    debugPrint('1. USER INPUT: $secretNotes');

    final encryptedNotes = _encryptionService.encryptText(secretNotes);
    debugPrint('2. CIPHERTEXT GENERATED: $encryptedNotes');

    final todo = TodoModel(
      title: title,
      encryptedSecretNotes: encryptedNotes,
      createdAt: DateTime.now(),
    );

    debugPrint('3. SAVING TO DATABASE: ${todo.toMap()}');
    await _databaseService.insertTodo(todo);
    await _loadTodos();
  }

  Future<void> updateTodo(int id, String title, String secretNotes) async {
    final encryptedNotes = _encryptionService.encryptText(secretNotes);
    var originalCreatedAt = DateTime.now();
    for (final existingTodo in _todos) {
      if (existingTodo.id == id) {
        originalCreatedAt = existingTodo.createdAt;
        break;
      }
    }

    final todo = TodoModel(
      id: id,
      title: title,
      encryptedSecretNotes: encryptedNotes,
      createdAt: originalCreatedAt,
    );
    await _databaseService.updateTodo(todo);
    await _loadTodos();
  }

  Future<void> toggleTodoStatus(TodoModel todo) async {
    todo.isCompleted = !todo.isCompleted;
    await _databaseService.updateTodo(todo);
    await _loadTodos();
  }

  Future<void> deleteTodo(int id) async {
    await _databaseService.deleteTodo(id);
    await _loadTodos();
  }

  Future<void> deleteAllTodos() async {
    await _databaseService.deleteAllTodos();
    await _loadTodos();
  }

  String decryptSecretNote(String encryptedNotes) {
    return _encryptionService.decryptText(encryptedNotes);
  }
}
