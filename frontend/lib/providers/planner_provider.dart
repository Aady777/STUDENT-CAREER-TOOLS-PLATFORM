import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Task {
  final String id;
  final String title;
  final DateTime date;
  final String time;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.date,
    required this.time,
    this.isDone = false,
  });
}

class PlannerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  final List<Task> _tasks = [];

  List<Task> get tasks => _tasks;

  Future<void> fetchTasks() async {
    try {
      final data = await _apiService.getRequest('/api/planner/');

      print("DATA AA GAYA: $data");

      _tasks.clear();

      final taskList = data['tasks'] as List<dynamic>;

      for (var item in taskList) {
        _tasks.add(
          Task(
            id: item['id'].toString(),
            title: item['title'] ?? 'No title',
            date: item['due_date'] != null
                ? DateTime.parse(item['due_date'])
                : DateTime.now(),
            time: "N/A",
            isDone: item['is_completed'] ?? false,
          ),
        );
      }

      notifyListeners();
    } catch (e) {
      print("ERROR: $e");
    }
  }

  
  Future<void> addTask(String title, DateTime date, String time) async {
    try {
      await _apiService.postRequest('/api/planner/', {
        "title": title,
        "description": "Added from Flutter app",
        "due_date": date.toIso8601String().split('T')[0],
        "priority": "medium"
      });

      // fresh data fetch
      await fetchTasks();
    } catch (e) {
      print("ADD TASK ERROR: $e");
    }
  }

  void toggleTask(String id) {
    final task = _tasks.firstWhere((t) => t.id == id);
    task.isDone = !task.isDone;
    notifyListeners();
  }
}