import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/test_provider.dart';
import 'test_screen.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});

  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  bool _isAccepted = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = const Color(0xFFE11D48);
    final hasPausedTest = Provider.of<TestProvider>(context).activeTest != null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(hasPausedTest ? 'Resume Mock Test' : 'Instructions', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: Stack(
        children: [
          Container(color: isDark ? const Color(0xFF0A0A10) : const Color(0xFFF8FAFC)),
          Positioned(
            top: -100, right: -100,
            child: Container(
              width: 500, height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryColor.withOpacity(isDark ? 0.2 : 0.3), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF13131F) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryColor.withOpacity(isDark ? 0.3 : 0.1), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: primaryColor.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(hasPausedTest ? 'You have an ongoing test!' : 'General Instructions', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: hasPausedTest ? [
                            Text(
                              'You paused your previous mock test. Would you like to resume from where you left off?',
                              style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Remaining time and all marked answers have been securely saved.',
                              style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54),
                            ),
                          ] : [
                            _buildInstructionItem('1. The test duration is 45 minutes.', isDark, primaryColor),
                            _buildInstructionItem('2. There are a total of 20 questions in the test.', isDark, primaryColor),
                            _buildInstructionItem('3. Each question has 4 options, out of which only one is correct.', isDark, primaryColor),
                            _buildInstructionItem('4. You can use the "Review" button to mark a question for later review.', isDark, primaryColor),
                            _buildInstructionItem('5. Make sure to click "Save & Next" to record your answer.', isDark, primaryColor),
                            _buildInstructionItem('6. Do not refresh the page or close the window during the test.', isDark, primaryColor),
                            _buildInstructionItem('7. The test will be automatically submitted when the timer ends.', isDark, primaryColor),
                            _buildInstructionItem('8. Use the toggle menu button at the top right to show or hide the question panel.', isDark, primaryColor),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 32),
                    if (!hasPausedTest) Row(
                      children: [
                        Checkbox(
                          value: _isAccepted,
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) {
                            setState(() {
                              _isAccepted = val ?? false;
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAccepted = !_isAccepted;
                              });
                            },
                            child: Text(
                              'I have read and understood all the instructions. I am ready to begin the test.',
                              style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!hasPausedTest) const SizedBox(height: 24),
                    FilledButton(
                      onPressed: (hasPausedTest || _isAccepted) ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const TestScreen()),
                        );
                      } : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: isDark ? Colors.white12 : Colors.black12,
                        disabledForegroundColor: isDark ? Colors.white38 : Colors.black38,
                      ),
                      child: Text(hasPausedTest ? 'Resume Paused Test' : 'Start Test', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    if (hasPausedTest) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          Provider.of<TestProvider>(context, listen: false).clearTest();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Start New Test Instead', style: TextStyle(fontSize: 16)),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text, bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.arrow_right, color: primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: isDark ? Colors.white : Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
