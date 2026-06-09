import 'package:flutter/material.dart';

enum QuestionStatus { notVisited, answered, markedForReview, skipped }

class TestState {
  int timeLeft;
  int currentQuestion;
  Map<int, String?> answers;
  Map<int, QuestionStatus> statuses;

  TestState({
    required this.timeLeft,
    required this.currentQuestion,
    required this.answers,
    required this.statuses,
  });
}

class TestProvider extends ChangeNotifier {
  TestState? _activeTest;

  TestState? get activeTest => _activeTest;

  void saveTest(TestState state) {
    _activeTest = state;
    notifyListeners();
  }

  void clearTest() {
    _activeTest = null;
    notifyListeners();
  }
}
