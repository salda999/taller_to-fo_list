import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Nueva Tarea'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'Ingresa el título de la tarea',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
        onSubmitted: (value) => _addTask(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _addTask,
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  void _addTask() {
    final title = _controller.text.trim();
    if (title.isNotEmpty) {
      context.read<TaskProvider>().addTask(title);
      Navigator.of(context).pop();
    }
  }
}