import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';

class CgpaScreen extends StatefulWidget {
  const CgpaScreen({super.key});

  @override
  State<CgpaScreen> createState() => _CgpaScreenState();
}

class _CgpaScreenState extends State<CgpaScreen> {
  final List<Subject> _subjects = [Subject()];
  double _cgpa = 0.0;
  String _gradingSystem = '10-Point Scale';
  final List<String> _history = [];

  void _addSubject() {
    setState(() => _subjects.add(Subject()));
  }

  void _calculateCgpa() {
    double totalCredits = 0;
    double totalPoints = 0;
    for (var subject in _subjects) {
      if (subject.credits > 0) {
        totalCredits += subject.credits;
        totalPoints += subject.credits * subject.gradePoint;
      }
    }
    setState(() {
      _cgpa = totalCredits > 0 ? totalPoints / totalCredits : 0.0;
      _history.add('Calculated CGPA: ${_cgpa.toStringAsFixed(2)} ($_gradingSystem)');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('CGPA Calculator', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  colors: [primaryColor.withOpacity(isDark ? 0.3 : 0.4), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: isDark ? Color.lerp(const Color(0xFF0A0A10), primaryColor, 0.15) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: primaryColor.withOpacity(isDark ? 0.4 : 0.1), width: 2),
                    boxShadow: [
                      BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 30, offset: const Offset(0, 10))
                    ],
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                            value: _gradingSystem,
                            items: const [
                              DropdownMenuItem(value: '10-Point Scale', child: Text('10-Point Scale')),
                              DropdownMenuItem(value: '4-Point Scale', child: Text('4-Point Scale')),
                            ],
                            onChanged: (val) => setState(() => _gradingSystem = val!),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Your CGPA',
                            style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54)),
                        Text(
                          _cgpa.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_history.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: ListView(
                      children: _history
                          .map((h) => Text(
                                'History: $h',
                                style: TextStyle(
                                    color: isDark ? Colors.white54 : Colors.black45, fontSize: 12),
                                textAlign: TextAlign.center,
                              ))
                          .toList(),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) =>
                        _buildSubjectRow(_subjects[index], index, isDark, primaryColor),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addSubject,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Subject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : primaryColor,
                            side: BorderSide(color: primaryColor.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          onPressed: _calculateCgpa,
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                            shadowColor: primaryColor.withOpacity(0.5),
                          ),
                          child: const Text('Calculate',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectRow(Subject subject, int index, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(isDark ? 0.3 : 0.1), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Subject name input ──────────────────────────────────────
          TextFormField(
            controller: subject.nameController,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Subject ${index + 1} name',
              hintStyle: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(Icons.book_outlined,
                  color: isDark ? Colors.white54 : primaryColor, size: 20),
              filled: true,
              fillColor: primaryColor.withOpacity(isDark ? 0.12 : 0.06),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) => subject.name = val,
          ),
          const SizedBox(height: 12),
          // ── Credits + Grade row ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Credits',
                    labelStyle:
                        TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => subject.credits = double.tryParse(val) ?? 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<double>(
                  dropdownColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Grade',
                    labelStyle:
                        TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.02),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _gradingSystem == '10-Point Scale'
                      ? const [
                          DropdownMenuItem(value: 10.0, child: Text('O (10)')),
                          DropdownMenuItem(value: 9.0, child: Text('A+ (9)')),
                          DropdownMenuItem(value: 8.0, child: Text('A (8)')),
                          DropdownMenuItem(value: 7.0, child: Text('B+ (7)')),
                        ]
                      : const [
                          DropdownMenuItem(value: 4.0, child: Text('A (4.0)')),
                          DropdownMenuItem(value: 3.0, child: Text('B (3.0)')),
                          DropdownMenuItem(value: 2.0, child: Text('C (2.0)')),
                          DropdownMenuItem(value: 1.0, child: Text('D (1.0)')),
                        ],
                  onChanged: (val) {
                    if (val != null) subject.gradePoint = val;
                  },
                ),
              ),
              const SizedBox(width: 8),
              // ── Delete button ───────────────────────────────────────
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () => setState(() => _subjects.removeAt(index)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Subject {
  String name = '';
  double credits = 0.0;
  double gradePoint = 0.0;

  // Dedicated controller so the field retains typed text across rebuilds
  final TextEditingController nameController = TextEditingController();
}