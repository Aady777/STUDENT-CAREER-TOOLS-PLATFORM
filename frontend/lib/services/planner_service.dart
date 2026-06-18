import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PlannerProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List tasks = [];

  Future<void> fetchTasks() async {
    try {
      final data = await _apiService.getRequest('/api/planner');
      tasks = data;
      notifyListeners();
      print("DATA AA GAYA: $data");
    } catch (e) {
      print("ERROR: $e");
    }
  }
}