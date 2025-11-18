import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'task_local_data_source.dart';

class SyncQueueItem {
  final String id;
  final String entity;
  final String entityId;
  final String operation; // CREATE, UPDATE, DELETE
  final String? payload;
  final int createdAt;
  final int attemptCount;
  final String? lastError;

  SyncQueueItem({
    required this.id,
    required this.entity,
    required this.entityId,
    required this.operation,
    this.payload,
    required this.createdAt,
    required this.attemptCount,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity': entity,
      'entity_id': entityId,
      'op': operation,
      'payload': payload,
      'created_at': createdAt,
      'attempt_count': attemptCount,
      'last_error': lastError,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'],
      entity: map['entity'],
      entityId: map['entity_id'],
      operation: map['op'],
      payload: map['payload'],
      createdAt: map['created_at'],
      attemptCount: map['attempt_count'],
      lastError: map['last_error'],
    );
  }
}

class SyncQueueLocalDataSource {
  static const String tableQueue = 'queue_operations';
  static const String columnId = 'id';
  static const String columnEntity = 'entity';
  static const String columnEntityId = 'entity_id';
  static const String columnOp = 'op';
  static const String columnPayload = 'payload';
  static const String columnCreatedAt = 'created_at';
  static const String columnAttemptCount = 'attempt_count';
  static const String columnLastError = 'last_error';

  final TaskLocalDataSource _taskLocalDataSource;

  SyncQueueLocalDataSource(this._taskLocalDataSource);

  Future<Database> get database => _taskLocalDataSource.database;

  Future<void> initQueueTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $tableQueue (
        $columnId TEXT PRIMARY KEY,
        $columnEntity TEXT,
        $columnEntityId TEXT,
        $columnOp TEXT,
        $columnPayload TEXT,
        $columnCreatedAt INTEGER,
        $columnAttemptCount INTEGER,
        $columnLastError TEXT
      )
    ''');
  }

  Future<void> addToQueue(SyncQueueItem item) async {
    if (kIsWeb) {
      TaskLocalDataSource.webQueue.add(item.toMap());
      return;
    }

    Database db = await database;
    await db.insert(
      tableQueue,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SyncQueueItem>> getPendingOperations() async {
    if (kIsWeb) {
      return TaskLocalDataSource.webQueue
          .map((map) => SyncQueueItem.fromMap(map))
          .toList();
    }

    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(tableQueue);
    return List.generate(maps.length, (i) => SyncQueueItem.fromMap(maps[i]));
  }

  Future<void> removeFromQueue(String id) async {
    if (kIsWeb) {
      TaskLocalDataSource.webQueue.removeWhere((item) => item['id'] == id);
      return;
    }

    Database db = await database;
    await db.delete(
      tableQueue,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateAttempt(String id, String? error) async {
    if (kIsWeb) {
      final index = TaskLocalDataSource.webQueue.indexWhere((item) => item['id'] == id);
      if (index != -1) {
        TaskLocalDataSource.webQueue[index]['attempt_count'] =
            (TaskLocalDataSource.webQueue[index]['attempt_count'] ?? 0) + 1;
        TaskLocalDataSource.webQueue[index]['last_error'] = error;
      }
      return;
    }

    Database db = await database;
    await db.update(
      tableQueue,
      {
        columnAttemptCount: await _getAttemptCount(id) + 1,
        columnLastError: error,
      },
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  Future<int> _getAttemptCount(String id) async {
    if (kIsWeb) {
      final item = TaskLocalDataSource.webQueue.firstWhere(
        (item) => item['id'] == id,
        orElse: () => {},
      );
      return item.isNotEmpty ? item['attempt_count'] ?? 0 : 0;
    }

    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableQueue,
      columns: [columnAttemptCount],
      where: '$columnId = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? maps.first[columnAttemptCount] : 0;
  }
}