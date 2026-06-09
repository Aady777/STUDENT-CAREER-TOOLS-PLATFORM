import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/test_provider.dart';
import 'instructions_screen.dart';

class ResultScreen extends StatelessWidget {
  // Pass the answers map and questions list so we can compute real scores.
  // Both are optional so existing Navigator.pushReplacement calls keep working
  // (they'll just show placeholder zeros until you wire them up).
  final Map<int, String?> answers;
  final List<Map<String, dynamic>> questions;

  const ResultScreen({
    super.key,
    this.answers = const {},
    this.questions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const primaryColor = Color(0xFFE11D48);

    // ── Score calculation ──────────────────────────────────────────────────
    final int total = questions.isEmpty ? 20 : questions.length;
    int correct = 0;
    for (int i = 0; i < questions.length; i++) {
      if (answers[i] != null && answers[i] == questions[i]['answer']) {
        correct++;
      }
    }
    final int wrong = answers.isEmpty ? 0 : (answers.length - correct);
    final int unattempted = total - answers.length;
    final double scorePercent = total == 0 ? 0 : (correct / total) * 100;

    // ── Grade label & color ────────────────────────────────────────────────
    String grade;
    Color gradeColor;
    IconData gradeIcon;
    if (scorePercent >= 80) {
      grade = 'Excellent!';
      gradeColor = const Color(0xFF10B981);
      gradeIcon = Icons.emoji_events_rounded;
    } else if (scorePercent >= 60) {
      grade = 'Good Job!';
      gradeColor = const Color(0xFFF59E0B);
      gradeIcon = Icons.thumb_up_alt_rounded;
    } else if (scorePercent >= 40) {
      grade = 'Keep Practising';
      gradeColor = const Color(0xFFE11D48);
      gradeIcon = Icons.trending_up_rounded;
    } else {
      grade = 'Needs Improvement';
      gradeColor = Colors.redAccent;
      gradeIcon = Icons.restart_alt_rounded;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Test Results',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: Stack(
        children: [
          // Background
          Container(
              color: isDark
                  ? const Color(0xFF0A0A10)
                  : const Color(0xFFF8FAFC)),
          Positioned(
            bottom: -120,
            right: -120,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  gradeColor.withOpacity(isDark ? 0.18 : 0.12),
                  Colors.transparent
                ]),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),

                      // ── Trophy / grade icon ──────────────────────────────
                      Center(
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: gradeColor.withOpacity(0.15),
                            border: Border.all(
                                color: gradeColor.withOpacity(0.4),
                                width: 2),
                          ),
                          child: Icon(gradeIcon,
                              size: 52, color: gradeColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(grade,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: gradeColor)),
                      const SizedBox(height: 4),
                      Text('Test Completed',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black45)),
                      const SizedBox(height: 32),

                      // ── Score card ───────────────────────────────────────
                      _Card(
                        isDark: isDark,
                        primaryColor: primaryColor,
                        child: Column(
                          children: [
                            Text(
                              '${scorePercent.toStringAsFixed(1)}%',
                              style: TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.bold,
                                  color: gradeColor,
                                  letterSpacing: -1),
                            ),
                            const SizedBox(height: 4),
                            Text('Overall Score',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.black45)),
                            const SizedBox(height: 24),

                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: scorePercent / 100,
                                minHeight: 10,
                                backgroundColor: isDark
                                    ? Colors.white12
                                    : Colors.black12,
                                valueColor:
                                    AlwaysStoppedAnimation(gradeColor),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Stats row
                            Row(
                              children: [
                                _StatCell(
                                    label: 'Total',
                                    value: '$total',
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                    isDark: isDark),
                                _divider(isDark),
                                _StatCell(
                                    label: 'Correct',
                                    value: '$correct',
                                    color: const Color(0xFF10B981),
                                    isDark: isDark),
                                _divider(isDark),
                                _StatCell(
                                    label: 'Wrong',
                                    value: '$wrong',
                                    color: primaryColor,
                                    isDark: isDark),
                                _divider(isDark),
                                _StatCell(
                                    label: 'Skipped',
                                    value: '$unattempted',
                                    color: const Color(0xFF8B5CF6),
                                    isDark: isDark),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Accuracy / time card ─────────────────────────────
                      _Card(
                        isDark: isDark,
                        primaryColor: primaryColor,
                        child: Row(
                          children: [
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.my_library_books_rounded,
                                label: 'Accuracy',
                                value: answers.isEmpty
                                    ? '—'
                                    : '${((correct / (answers.length == 0 ? 1 : answers.length)) * 100).toStringAsFixed(1)}%',
                                color: const Color(0xFF10B981),
                                isDark: isDark,
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 48,
                                color: isDark
                                    ? Colors.white12
                                    : Colors.black12),
                            Expanded(
                              child: _InfoTile(
                                icon: Icons.quiz_rounded,
                                label: 'Attempted',
                                value:
                                    '${answers.length}/$total',
                                color: const Color(0xFFF59E0B),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Actions ──────────────────────────────────────────
                      FilledButton.icon(
                        onPressed: () {
                          // Clear any residual paused test and go home
                          Provider.of<TestProvider>(context,
                                  listen: false)
                              .clearTest();
                          Navigator.of(context)
                              .popUntil(ModalRoute.withName('/'));
                        },
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Back to Home',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          Provider.of<TestProvider>(context,
                                  listen: false)
                              .clearTest();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const InstructionsScreen()),
                          );
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Try Again',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              isDark ? Colors.white : Colors.black87,
                          padding:
                              const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
      width: 1,
      height: 40,
      color: isDark ? Colors.white12 : Colors.black12);
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final Color primaryColor;

  const _Card(
      {required this.child,
      required this.isDark,
      required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: primaryColor.withOpacity(isDark ? 0.3 : 0.1),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: primaryColor.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: child,
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatCell(
      {required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _InfoTile(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45)),
      ],
    );
  }
}