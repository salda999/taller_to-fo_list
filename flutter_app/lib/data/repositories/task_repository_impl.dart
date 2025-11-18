import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/local/task_local_data_source.dart';
import '../datasources/local/sync_queue_local_data_source.dart';
import '../datasources/remote/task_remote_data_source.dart';
import '../models/task_model.dart';

// Implementación del repositorio de tareas
// Maneja la lógica offline-first y sincronización
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;
  final SyncQueueLocalDataSource syncQueueDataSource;
  final TaskRemoteDataSource remoteDataSource;
  final Connectivity connectivity;

  TaskRepositoryImpl({
    required this.localDataSource,
    required this.syncQueueDataSource,
    required this.remoteDataSource,
    required this.connectivity,
  });

  @override
  Future<List<Task>> getTasks() async {
    // Always return local data first
    final localTasks = await localDataSource.getTasks();

    // Try to sync in background if connected
    _syncIfConnected();

    return localTasks;
  }

  @override
  Future<Task?> getTask(String id) async {
    return await localDataSource.getTask(id);
  }

  @override
  Future<Task> createTask(Task task) async {
    final taskId = task.id.isEmpty ? Uuid().v4() : task.id;
    final taskWithId = task.copyWith(id: taskId);
    final taskModel = TaskModel.fromEntity(taskWithId);
    await localDataSource.insertTask(taskModel);

    // Add to sync queue
    final queueItem = SyncQueueItem(
      id: Uuid().v4(),
      entity: 'task',
      entityId: taskId,
      operation: 'CREATE',
      payload: json.encode(taskModel.toJson()),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      attemptCount: 0,
    );
    await syncQueueDataSource.addToQueue(queueItem);

    // Try to sync immediately if connected
    _syncIfConnected();

    return taskWithId;
  }

  @override
  Future<Task> updateTask(Task task) async {
    final taskModel = TaskModel.fromEntity(task);
    await localDataSource.updateTask(taskModel);

    // Add to sync queue
    final queueItem = SyncQueueItem(
      id: Uuid().v4(),
      entity: 'task',
      entityId: task.id,
      operation: 'UPDATE',
      payload: json.encode(taskModel.toJson()),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      attemptCount: 0,
    );
    await syncQueueDataSource.addToQueue(queueItem);

    // Try to sync immediately if connected
    _syncIfConnected();

    return task;
  }

  @override
  Future<void> deleteTask(String id) async {
    await localDataSource.deleteTask(id);

    // Add to sync queue
    final queueItem = SyncQueueItem(
      id: Uuid().v4(),
      entity: 'task',
      entityId: id,
      operation: 'DELETE',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      attemptCount: 0,
    );
    await syncQueueDataSource.addToQueue(queueItem);

    // Try to sync immediately if connected
    _syncIfConnected();
  }

  Future<void> _syncIfConnected() async {
    final connectivityResult = await connectivity.checkConnectivity();
    if (connectivityResult != ConnectivityResult.none) {
      await syncPendingOperations();
    }
  }

  Future<void> syncPendingOperations() async {
    final pendingOperations = await syncQueueDataSource.getPendingOperations();

    for (final operation in pendingOperations) {
      // Skip operations that have exceeded retry limit
      const maxRetries = 5;
      if (operation.attemptCount >= maxRetries) {
        print('Operation ${operation.id} exceeded max retries, skipping');
        continue;
      }

      // Calculate backoff delay
      final backoffDelay = _calculateBackoffDelay(operation.attemptCount);
      final timeSinceCreation = DateTime.now().millisecondsSinceEpoch - operation.createdAt;
      
      if (timeSinceCreation < backoffDelay.inMilliseconds) {
        // Too early to retry, skip this operation
        continue;
      }

      try {
        await _executeOperation(operation);
        await syncQueueDataSource.removeFromQueue(operation.id);
        print('Successfully synced operation ${operation.id}');
      } catch (e) {
        await syncQueueDataSource.updateAttempt(operation.id, e.toString());
        print('Failed to sync operation ${operation.id}: $e. Attempt ${operation.attemptCount + 1}');
      }
    }
  }

  Duration _calculateBackoffDelay(int attemptCount) {
    // Exponential backoff: 2^attempt seconds, with a max of 5 minutes
    final delaySeconds = (2 << attemptCount).clamp(1, 300);
    return Duration(seconds: delaySeconds);
  }

  Future<void> _executeOperation(SyncQueueItem operation) async {
    // Use operation ID as request ID for idempotency
    final requestId = operation.id;
    
    switch (operation.operation) {
      case 'CREATE':
        final payload = json.decode(operation.payload!);
        final task = TaskModel.fromJson(payload);
        final remoteTask = await remoteDataSource.createTask(task, requestId: requestId);
        
        // Update local task with remote data if newer (LWW resolution)
        final localTask = await localDataSource.getTask(task.id);
        if (localTask == null || remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          await localDataSource.updateTask(remoteTask);
        }
        break;
        
      case 'UPDATE':
        final payload = json.decode(operation.payload!);
        final task = TaskModel.fromJson(payload);
        final remoteTask = await remoteDataSource.updateTask(task, requestId: requestId);
        
        // Update local task with remote data if newer (LWW resolution)
        final localTask = await localDataSource.getTask(task.id);
        if (localTask == null || remoteTask.updatedAt.isAfter(localTask.updatedAt)) {
          await localDataSource.updateTask(remoteTask);
        }
        break;
        
      case 'DELETE':
        await remoteDataSource.deleteTask(operation.entityId, requestId: requestId);
        break;
    }
  }
}