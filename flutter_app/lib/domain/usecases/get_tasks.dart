import '../entities/task.dart';
import '../repositories/task_repository.dart';

// Caso de uso para obtener todas las tareas
// Implementa la lógica de negocio para recuperar tareas
class GetTasksUseCase {
  final TaskRepository repository;

  GetTasksUseCase(this.repository);

  Future<List<Task>> call() {
    return repository.getTasks();
  }
}