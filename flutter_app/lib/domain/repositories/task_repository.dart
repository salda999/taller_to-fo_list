import '../entities/task.dart';

// Interfaz del repositorio para operaciones con tareas
// Define el contrato que deben implementar las fuentes de datos
abstract class TaskRepository {
  Future<List<Task>> getTasks(); // Obtener todas las tareas
  Future<Task?> getTask(String id); // Obtener tarea por ID
  Future<Task> createTask(Task task); // Crear nueva tarea
  Future<Task> updateTask(Task task); // Actualizar tarea existente
  Future<void> deleteTask(String id); // Eliminar tarea por ID
}