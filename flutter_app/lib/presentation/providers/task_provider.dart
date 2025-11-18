import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/create_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/delete_task.dart';
import '../../data/repositories/task_repository_impl.dart';

// Provider para gestión de estado de tareas
// Maneja la lógica de presentación y comunicación con casos de uso
class TaskProvider with ChangeNotifier {
  final GetTasksUseCase getTasksUseCase;
  final CreateTaskUseCase createTaskUseCase;
  final UpdateTaskUseCase updateTaskUseCase;
  final DeleteTaskUseCase deleteTaskUseCase;
  final TaskRepositoryImpl repository;
  final Connectivity connectivity;

  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  TaskProvider({
    required this.getTasksUseCase,
    required this.createTaskUseCase,
    required this.updateTaskUseCase,
    required this.deleteTaskUseCase,
    required this.repository,
    required this.connectivity,
  }) {
    _initConnectivityListener();
  }

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await getTasksUseCase();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addTask(String title) async {
    final task = Task(
      id: '', // Will be generated
      title: title,
      completed: false,
      updatedAt: DateTime.now(),
    );

    try {
      await createTaskUseCase(task);
      await loadTasks(); // Reload tasks
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggleTask(Task task) async {
    final updatedTask = task.copyWith(completed: !task.completed);
    try {
      await updateTaskUseCase(updatedTask);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateTaskTitle(Task task, String newTitle) async {
    final updatedTask = task.copyWith(title: newTitle);
    try {
      await updateTaskUseCase(updatedTask);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeTask(Task task) async {
    try {
      await deleteTaskUseCase(task.id);
      await loadTasks();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        repository.syncPendingOperations();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}