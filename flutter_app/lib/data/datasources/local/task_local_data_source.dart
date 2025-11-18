import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/task_model.dart';

// Fuente de datos local para tareas
// Usa SQLite en móvil y almacenamiento en memoria para web
class TaskLocalDataSource {
  static const String _databaseName = 'tasks.db';
  static const int _databaseVersion = 1;

  static const String tableTasks = 'tasks';
  static const String columnId = 'id';
  static const String columnTitle = 'title';
  static const String columnCompleted = 'completed';
  static const String columnUpdatedAt = 'updated_at';
  static const String columnDeleted = 'deleted';

  TaskLocalDataSource._privateConstructor();
  static final TaskLocalDataSource instance = TaskLocalDataSource._privateConstructor();

  static Database? _database;

  // Almacenamiento en memoria para compatibilidad web
  static final List<Map<String, dynamic>> _webTasks = [];
  static final List<Map<String, dynamic>> webQueue = [];

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('Database not supported on web');
    }
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks (
        $columnId TEXT PRIMARY KEY,
        $columnTitle TEXT NOT NULL,
        $columnCompleted INTEGER NOT NULL DEFAULT 0,
        $columnUpdatedAt TEXT NOT NULL,
        $columnDeleted INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE queue_operations (
        id TEXT PRIMARY KEY,
        entity TEXT,
        entity_id TEXT,
        op TEXT,
        payload TEXT,
        created_at INTEGER,
        attempt_count INTEGER,
        last_error TEXT
      )
    ''');
  }

  Future<List<TaskModel>> getTasks() async {
    if (kIsWeb) {
      return _webTasks
          .where((task) => task[columnDeleted] == 0)
          .map((task) => TaskModel(
                id: task[columnId],
                title: task[columnTitle],
                completed: task[columnCompleted] == 1,
                updatedAt: DateTime.parse(task[columnUpdatedAt]),
              ))
          .toList();
    }

    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTasks,
      where: '$columnDeleted = ?',
      whereArgs: [0],
    );
    return List.generate(maps.length, (i) {
      return TaskModel(
        id: maps[i][columnId],
        title: maps[i][columnTitle],
        completed: maps[i][columnCompleted] == 1,
        updatedAt: DateTime.parse(maps[i][columnUpdatedAt]),
      );
    });
  }

  Future<TaskModel?> getTask(String id) async {
    if (kIsWeb) {
      final task = _webTasks.firstWhere(
        (task) => task[columnId] == id && task[columnDeleted] == 0,
        orElse: () => {},
      );
      if (task.isNotEmpty) {
        return TaskModel(
          id: task[columnId],
          title: task[columnTitle],
          completed: task[columnCompleted] == 1,
          updatedAt: DateTime.parse(task[columnUpdatedAt]),
        );
      }
      return null;
    }

    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableTasks,
      where: '$columnId = ? AND $columnDeleted = ?',
      whereArgs: [id, 0],
    );
    if (maps.isNotEmpty) {
      return TaskModel(
        id: maps.first[columnId],
        title: maps.first[columnTitle],
        completed: maps.first[columnCompleted] == 1,
        updatedAt: DateTime.parse(maps.first[columnUpdatedAt]),
      );
    }
    return null;
  }

  Future<void> insertTask(TaskModel task) async {
    if (kIsWeb) {
      _webTasks.add({
        columnId: task.id,
        columnTitle: task.title,
        columnCompleted: task.completed ? 1 : 0,
        columnUpdatedAt: task.updatedAt.toIso8601String(),
        columnDeleted: 0,
      });
      return;
    }

    Database db = await instance.database;
    await db.insert(
      tableTasks,
      {
        columnId: task.id,
        columnTitle: task.title,
        columnCompleted: task.completed ? 1 : 0,
        columnUpdatedAt: task.updatedAt.toIso8601String(),
        columnDeleted: 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(TaskModel task) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((t) => t[columnId] == task.id);
      if (index != -1) {
        _webTasks[index] = {
          columnId: task.id,
          columnTitle: task.title,
          columnCompleted: task.completed ? 1 : 0,
          columnUpdatedAt: task.updatedAt.toIso8601String(),
          columnDeleted: 0,
        };
      }
      return;
    }

    Database db = await instance.database;
    await db.update(
      tableTasks,
      {
        columnTitle: task.title,
        columnCompleted: task.completed ? 1 : 0,
        columnUpdatedAt: task.updatedAt.toIso8601String(),
      },
      where: '$columnId = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String id) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((t) => t[columnId] == id);
      if (index != -1) {
        _webTasks[index][columnDeleted] = 1;
        _webTasks[index][columnUpdatedAt] = DateTime.now().toIso8601String();
      }
      return;
    }

    Database db = await instance.database;
    await db.update(
      tableTasks,
      {columnDeleted: 1, columnUpdatedAt: DateTime.now().toIso8601String()},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}