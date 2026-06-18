import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/test_provider.dart';
import 'result_screen.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int _currentQuestion = 0;
  String? _selectedOption;
  late Timer _timer;
  int _timeLeft = 2700; // 45 mins
  bool _isPanelVisible = true;

  Map<int, String?> _answers = {};
  Map<int, QuestionStatus> _statuses = {};

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'What is the powerhouse of the cell?',
      'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Endoplasmic Reticulum'],
      'answer': 'Mitochondria'
    },
    {
      'question': 'What is the speed of light?',
      'options': ['300,000 km/s', '150,000 km/s', '400,000 km/s', 'None of the above'],
      'answer': '300,000 km/s'
    },
    ...List.generate(18, (index) => {
          'question': 'Sample Question ${index + 3}: Choose the correct option below.',
          'options': ['Option A', 'Option B', 'Option C', 'Option D'],
          'answer': 'Option A'
        })
  ];

  @override
  void initState() {
    super.initState();
    final testProvider = Provider.of<TestProvider>(context, listen: false);
    if (testProvider.activeTest != null) {
      _timeLeft = testProvider.activeTest!.timeLeft;
      _currentQuestion = testProvider.activeTest!.currentQuestion;
      _answers = Map.from(testProvider.activeTest!.answers);
      _statuses = Map.from(testProvider.activeTest!.statuses);
      _selectedOption = _answers[_currentQuestion];
    } else {
      for (int i = 0; i < _questions.length; i++) {
        _statuses[i] = QuestionStatus.notVisited;
      }
    }
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _timer.cancel();
        _submitTest();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _submitTest() {
    _timer.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) {
        return SubmitConfirmationDialog(
          statuses: _statuses,
          totalQuestions: _questions.length,
        );
      },
    ).then((result) {
      if (!mounted) return;
      if (result == 'submit') {
        Provider.of<TestProvider>(context, listen: false).clearTest();
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ResultScreen()));
      } else if (result == 'pause') {
        // ✅ FIX: save state so InstructionsScreen detects the paused test
        Provider.of<TestProvider>(context, listen: false).saveTest(
          TestState(
            timeLeft: _timeLeft,
            currentQuestion: _currentQuestion,
            answers: _answers,
            statuses: _statuses,
          ),
        );
        setState(() => _canPop = true);
        Navigator.popUntil(context, ModalRoute.withName('/'));
      } else {
        // Continue — restart timer
        _startTimer();
      }
    });
  }

  void _clearResponse() {
    setState(() {
      _selectedOption = null;
      _answers.remove(_currentQuestion);
      _statuses[_currentQuestion] = QuestionStatus.notVisited;
    });
  }

  void _markReview() {
    setState(() {
      _statuses[_currentQuestion] = QuestionStatus.markedForReview;
      if (_selectedOption != null) {
        _answers[_currentQuestion] = _selectedOption;
      }
      _moveToNext();
    });
  }

  void _nextQuestion() {
    setState(() {
      if (_statuses[_currentQuestion] == QuestionStatus.notVisited) {
        _statuses[_currentQuestion] = QuestionStatus.skipped;
      }
      _moveToNext();
    });
  }

  void _saveAndNext() {
    setState(() {
      if (_selectedOption != null) {
        _answers[_currentQuestion] = _selectedOption;
        _statuses[_currentQuestion] = QuestionStatus.answered;
      } else {
        _statuses[_currentQuestion] = QuestionStatus.skipped;
      }
      _moveToNext();
    });
  }

  void _moveToNext() {
    if (_currentQuestion < _questions.length - 1) {
      _currentQuestion++;
    } else {
      _currentQuestion = 0;
    }
    _selectedOption = _answers[_currentQuestion];
  }

  void _goToQuestion(int index) {
    setState(() {
      if (_statuses[_currentQuestion] == QuestionStatus.notVisited) {
        _statuses[_currentQuestion] = QuestionStatus.skipped;
      }
      _currentQuestion = index;
      _selectedOption = _answers[_currentQuestion];
    });
  }

  bool _canPop = false;

  void _handleBack() async {
    _timer.cancel();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => SubmitConfirmationDialog(
        statuses: _statuses,
        totalQuestions: _questions.length,
      ),
    );

    if (!mounted) return;

    if (result == 'submit') {
      Provider.of<TestProvider>(context, listen: false).clearTest();
      setState(() => _canPop = true);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ResultScreen()));
    } else if (result == 'pause') {
      Provider.of<TestProvider>(context, listen: false).saveTest(
        TestState(
          timeLeft: _timeLeft,
          currentQuestion: _currentQuestion,
          answers: _answers,
          statuses: _statuses,
        ),
      );
      setState(() => _canPop = true);
      Navigator.popUntil(context, ModalRoute.withName('/'));
    } else {
      _startTimer();
    }
  }

  Widget _buildLegendItem(Color color, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = _questions[_currentQuestion];
    final minutes = (_timeLeft / 60).floor().toString().padLeft(2, '0');
    final seconds = (_timeLeft % 60).toString().padLeft(2, '0');
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const primaryColor = Color(0xFFE11D48);

    return PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
          title: const Text('Mock Test',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.5))),
              child: Center(
                child: Text('$minutes:$seconds',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(_isPanelVisible ? Icons.menu_open : Icons.menu,
                  color: primaryColor),
              tooltip: 'Toggle Question Panel',
              onPressed: () {
                setState(() {
                  _isPanelVisible = !_isPanelVisible;
                });
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Stack(
          children: [
            Container(
                color: isDark
                    ? const Color(0xFF0A0A10)
                    : const Color(0xFFF8FAFC)),
            Positioned(
              top: 100,
              left: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      primaryColor.withOpacity(isDark ? 0.2 : 0.3),
                      Colors.transparent
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight - 48),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Side: Question Area
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                      'Question ${_currentQuestion + 1}/${_questions.length}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor)),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF13131F)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                            color: primaryColor.withOpacity(
                                                isDark ? 0.3 : 0.1),
                                            width: 1.5),
                                        boxShadow: [
                                          BoxShadow(
                                              color: primaryColor
                                                  .withOpacity(0.05),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4))
                                        ]),
                                    child: Text(question['question'],
                                        style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87)),
                                  ),
                                  const SizedBox(height: 32),
                                  ...List.generate(question['options'].length,
                                      (index) {
                                    final option = question['options'][index];
                                    final isSelected = _selectedOption == option;
                                    return GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedOption = option),
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor.withOpacity(0.15)
                                              : (isDark
                                                  ? Colors.white.withOpacity(0.05)
                                                  : Colors.black
                                                      .withOpacity(0.02)),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                              color: isSelected
                                                  ? primaryColor
                                                  : (isDark
                                                      ? Colors.white12
                                                      : Colors.black12),
                                              width: 2),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected
                                                    ? primaryColor
                                                    : Colors.transparent,
                                                border: Border.all(
                                                    color: isSelected
                                                        ? primaryColor
                                                        : Colors.grey,
                                                    width: 2),
                                              ),
                                              child: isSelected
                                                  ? const Icon(Icons.check,
                                                      size: 16,
                                                      color: Colors.white)
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                                child: Text(option,
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        color: isDark
                                                            ? Colors.white
                                                            : Colors.black87,
                                                        fontWeight: isSelected
                                                            ? FontWeight.bold
                                                            : FontWeight
                                                                .normal))),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  const Spacer(),
                                  const SizedBox(height: 16),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: _clearResponse,
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        child: const Text('Clear'),
                                      ),
                                      OutlinedButton(
                                        onPressed: _markReview,
                                        style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF8B5CF6),
                                            side: const BorderSide(
                                                color: Color(0xFF8B5CF6)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 24, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        child: const Text('Review'),
                                      ),
                                      FilledButton.tonal(
                                        onPressed: _nextQuestion,
                                        style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12))),
                                        child: const Text('Next'),
                                      ),
                                      FilledButton(
                                        onPressed: _saveAndNext,
                                        style: FilledButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF10B981),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12)),
                                            elevation: 4,
                                            shadowColor: const Color(0xFF10B981)
                                                .withOpacity(0.5)),
                                        child: const Text('Save & Next',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            if (_isPanelVisible) ...[
                              const SizedBox(width: 24),

                              // Right Side: Question Panel
                              SizedBox(
                                width: 300,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF13131F)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                          color: primaryColor.withOpacity(
                                              isDark ? 0.3 : 0.1),
                                          width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                            color:
                                                primaryColor.withOpacity(0.05),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ]),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text('Question Panel',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87)),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        height: 200,
                                        child: GridView.builder(
                                          shrinkWrap: true,
                                          gridDelegate:
                                              const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 5,
                                            crossAxisSpacing: 10,
                                            mainAxisSpacing: 10,
                                          ),
                                          itemCount: _questions.length,
                                          itemBuilder: (context, index) {
                                            final status = _statuses[index] ??
                                                QuestionStatus.notVisited;
                                            Color bgColor = isDark
                                                ? Colors.white12
                                                : Colors.black12;
                                            Color textColor = isDark
                                                ? Colors.white
                                                : Colors.black87;

                                            if (status ==
                                                QuestionStatus.answered) {
                                              bgColor = const Color(0xFF10B981);
                                              textColor = Colors.white;
                                            } else if (status ==
                                                QuestionStatus.markedForReview) {
                                              bgColor = const Color(0xFF8B5CF6);
                                              textColor = Colors.white;
                                            } else if (status ==
                                                QuestionStatus.skipped) {
                                              bgColor = isDark
                                                  ? Colors.white24
                                                  : Colors.black26;
                                            }

                                            final isCurrent =
                                                _currentQuestion == index;

                                            return GestureDetector(
                                              onTap: () => _goToQuestion(index),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: bgColor,
                                                  shape: BoxShape.circle,
                                                  border: isCurrent
                                                      ? Border.all(
                                                          color: primaryColor,
                                                          width: 2.5)
                                                      : null,
                                                ),
                                                child: Center(
                                                  child: Text('${index + 1}',
                                                      style: TextStyle(
                                                          color: textColor,
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const Divider(),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 8,
                                        children: [
                                          _buildLegendItem(
                                              const Color(0xFF10B981),
                                              'Answered',
                                              isDark),
                                          _buildLegendItem(
                                              const Color(0xFF8B5CF6),
                                              'Review',
                                              isDark),
                                          _buildLegendItem(
                                              isDark
                                                  ? Colors.white12
                                                  : Colors.black12,
                                              'Not Visited',
                                              isDark),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      FilledButton(
                                        onPressed: _submitTest,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 16),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Submit Test',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SubmitConfirmationDialog extends StatefulWidget {
  final Map<int, QuestionStatus> statuses;
  final int totalQuestions;

  const SubmitConfirmationDialog({
    super.key,
    required this.statuses,
    required this.totalQuestions,
  });

  @override
  State<SubmitConfirmationDialog> createState() =>
      _SubmitConfirmationDialogState();
}

class _SubmitConfirmationDialogState extends State<SubmitConfirmationDialog> {
  int _selectedAction = 2;

  Widget _buildStatItem(String label, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count.toString(),
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const primaryColor = Color(0xFFE11D48);

    final int answered = widget.statuses.values
        .where((s) => s == QuestionStatus.answered)
        .length;
    final int marked = widget.statuses.values
        .where((s) => s == QuestionStatus.markedForReview)
        .length;
    final int skipped =
        widget.statuses.values.where((s) => s == QuestionStatus.skipped).length;
    final int notVisited = widget.statuses.values
        .where((s) => s == QuestionStatus.notVisited)
        .length;

    Widget buildOption(int index, String text, IconData icon) {
      final isSelected = _selectedAction == index;
      return GestureDetector(
        onTap: () => setState(() => _selectedAction = index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withOpacity(0.15)
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.02)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDark ? Colors.white12 : Colors.black12),
                width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? primaryColor : Colors.transparent,
                  border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey, width: 2),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              Icon(icon,
                  color: isSelected
                      ? primaryColor
                      : (isDark ? Colors.white54 : Colors.black54)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal))),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13131F) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: primaryColor.withOpacity(isDark ? 0.3 : 0.1),
                  width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Exam Summary',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatItem(
                            'Answered', answered, const Color(0xFF10B981), isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatItem(
                            'Not Visited',
                            notVisited,
                            isDark ? Colors.white54 : Colors.black54,
                            isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                        child: _buildStatItem(
                            'Review', marked, const Color(0xFF8B5CF6), isDark)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _buildStatItem(
                            'Skipped', skipped, primaryColor, isDark)),
                  ],
                ),
                const SizedBox(height: 28),
                Text('Action to Take:',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black54)),
                const SizedBox(height: 12),
                buildOption(0, 'Continue Test', Icons.play_arrow_rounded),
                buildOption(1, 'Pause & Resume Later', Icons.pause_circle_outline),
                buildOption(2, 'Submit & Complete', Icons.done_all_rounded),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () {
                    String result = 'continue';
                    if (_selectedAction == 1) result = 'pause';
                    if (_selectedAction == 2) result = 'submit';
                    Navigator.pop(context, result);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Confirm',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}