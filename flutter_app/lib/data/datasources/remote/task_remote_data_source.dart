import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/task_model.dart';

// Fuente de datos remota para comunicación con API REST
class TaskRemoteDataSource {
  final String baseUrl;
  static const Duration _timeout = Duration(seconds: 10);

  TaskRemoteDataSource({required this.baseUrl});

  Future<List<TaskModel>> getTasks() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks')).timeout(_timeout);
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => TaskModel.fromJson(json)).toList();
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw HttpException('Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error: ${response.statusCode}');
      } else {
        throw HttpException('Failed to load tasks: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out', _timeout);
    } on SocketException {
      throw const SocketException('No internet connection');
    }
  }

  Future<TaskModel> getTask(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks/$id')).timeout(_timeout);
      if (response.statusCode == 200) {
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw HttpException('Task not found');
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw HttpException('Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error: ${response.statusCode}');
      } else {
        throw HttpException('Failed to load task: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out', _timeout);
    } on SocketException {
      throw const SocketException('No internet connection');
    }
  }

  Future<TaskModel> createTask(TaskModel task, {String? requestId}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (requestId != null) 'Idempotency-Key': requestId,
      };
      final response = await http.post(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
        body: json.encode(task.toJson()),
      ).timeout(_timeout);
      if (response.statusCode == 201) {
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw HttpException('Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error: ${response.statusCode}');
      } else {
        throw HttpException('Failed to create task: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out', _timeout);
    } on SocketException {
      throw const SocketException('No internet connection');
    }
  }

  Future<TaskModel> updateTask(TaskModel task, {String? requestId}) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (requestId != null) 'Idempotency-Key': requestId,
      };
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/${task.id}'),
        headers: headers,
        body: json.encode(task.toJson()),
      ).timeout(_timeout);
      if (response.statusCode == 200) {
        return TaskModel.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw HttpException('Task not found');
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw HttpException('Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error: ${response.statusCode}');
      } else {
        throw HttpException('Failed to update task: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out', _timeout);
    } on SocketException {
      throw const SocketException('No internet connection');
    }
  }

  Future<void> deleteTask(String id, {String? requestId}) async {
    try {
      final headers = <String, String>{
        if (requestId != null) 'Idempotency-Key': requestId,
      };
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers.isNotEmpty ? headers : null,
      ).timeout(_timeout);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return;
      } else if (response.statusCode == 404) {
        // Task already deleted, consider this success
        return;
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        throw HttpException('Client error: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        throw HttpException('Server error: ${response.statusCode}');
      } else {
        throw HttpException('Failed to delete task: ${response.statusCode}');
      }
    } on TimeoutException {
      throw TimeoutException('Request timed out', _timeout);
    } on SocketException {
      throw const SocketException('No internet connection');
    }
  }
}