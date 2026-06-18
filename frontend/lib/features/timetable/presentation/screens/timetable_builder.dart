import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';

class TimetableBuilder extends StatefulWidget {
  const TimetableBuilder({super.key});

  @override
  State<TimetableBuilder> createState() => _TimetableBuilderState();
}

class _TimetableBuilderState extends State<TimetableBuilder> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _times = ['9 AM', '10 AM', '11 AM', '12 PM', '1 PM', '2 PM', '3 PM', '4 PM'];
  final Map<String, String> _schedule = {};

  final List<String> _subjects = [];
  final TextEditingController _subjectController = TextEditingController();

  final List<Color> _chipColors = [
    const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFF10B981),
    const Color(0xFFF59E0B), const Color(0xFFEF4444), const Color(0xFFEC4899),
    const Color(0xFF06B6D4), const Color(0xFF84CC16), const Color(0xFFF97316),
    const Color(0xFF6366F1),
  ];

  Color _colorForSubject(String subject) {
    final index = _subjects.indexOf(subject) % _chipColors.length;
    return _chipColors[index < 0 ? 0 : index];
  }

  void _addSubject() {
    final name = _subjectController.text.trim();
    if (name.isEmpty || _subjects.contains(name)) return;
    setState(() => _subjects.add(name));
    _subjectController.clear();
  }

  void _removeSubject(String subject) {
    setState(() {
      _subjects.remove(subject);
      _schedule.removeWhere((key, value) => value == subject);
    });
  }

  // ── Add custom time slot ─────────────────────────────────────────────────
  void _showAddTimeDialog(BuildContext context, bool isDark) async {
    const primaryColor = Color(0xFF3B82F6);
    TimeOfDay selectedTime = TimeOfDay.now();

    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(primary: primaryColor)
                : const ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final formatted = picked.format(context);
    if (_times.contains(formatted)) return;

    // Insert in chronological order
    setState(() {
      _times.add(formatted);
      _times.sort((a, b) {
        final ta = _parseTime(a);
        final tb = _parseTime(b);
        return ta.compareTo(tb);
      });
    });
  }

  void _removeTime(String time) {
    setState(() {
      _times.remove(time);
      _schedule.removeWhere((key, _) => key.contains('-$time'));
    });
  }

  // Returns minutes since midnight for sorting
  int _parseTime(String label) {
    try {
      final lower = label.toLowerCase().trim();
      final isPm = lower.contains('pm');
      final isAm = lower.contains('am');
      final cleaned = lower.replaceAll('am', '').replaceAll('pm', '').trim();
      final parts = cleaned.split(':');
      int hour = int.parse(parts[0]);
      int minute = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (isPm && hour != 12) hour += 12;
      if (isAm && hour == 12) hour = 0;
      return hour * 60 + minute;
    } catch (_) {
      return 0;
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    const primaryColor = Color(0xFF3B82F6);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Timetable Builder',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear timetable',
            onPressed: () => setState(() => _schedule.clear()),
          ),
          IconButton(icon: const Icon(Icons.share), onPressed: () {}),
        ],
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ── Subject input ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          onSubmitted: (_) => _addSubject(),
                          decoration: InputDecoration(
                            hintText: 'Enter subject name...',
                            hintStyle: TextStyle(
                                color: isDark ? Colors.white38 : Colors.black38),
                            prefixIcon: Icon(Icons.book_outlined,
                                color: isDark ? Colors.white54 : primaryColor, size: 20),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF13131F) : Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: primaryColor.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                  color: primaryColor.withOpacity(isDark ? 0.3 : 0.15)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: primaryColor, width: 1.8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _addSubject,
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: primaryColor.withOpacity(0.4),
                        ),
                        child: const Icon(Icons.add, size: 22),
                      ),
                    ],
                  ),
                ),

                // ── Subject chips ──────────────────────────────────────
                if (_subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      'Add subjects above, then drag them into the timetable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 13),
                    ),
                  )
                else
                  SizedBox(
                    height: 68,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        final color = _colorForSubject(subject);
                        return Draggable<String>(
                          data: subject,
                          feedback: Material(
                            color: Colors.transparent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color: color.withOpacity(0.5),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                ],
                              ),
                              child: Text(subject,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.35,
                            child: _subjectChip(subject, color, isDark, dragging: true),
                          ),
                          child: _subjectChip(subject, color, isDark),
                        );
                      },
                    ),
                  ),

                // ── Time slot row ──────────────────────────────────────
                Container(
                  height: 44,
                  margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Row(
                    children: [
                      // "Time slots" label
                      Text('Time slots',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white38 : Colors.black38)),
                      const SizedBox(width: 10),
                      // Scrollable existing time chips
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _times.length,
                          itemBuilder: (context, index) {
                            final t = _times[index];
                            // Default times (first 8) can't be deleted;
                            // user-added ones show a remove button
                            final isUserAdded = index >= 8;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isUserAdded
                                    ? primaryColor.withOpacity(isDark ? 0.2 : 0.1)
                                    : (isDark
                                        ? Colors.white.withOpacity(0.06)
                                        : Colors.black.withOpacity(0.04)),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isUserAdded
                                      ? primaryColor.withOpacity(0.5)
                                      : primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(t,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isUserAdded
                                              ? primaryColor
                                              : (isDark
                                                  ? Colors.white60
                                                  : Colors.black54))),
                                  if (isUserAdded) ...[
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () => _removeTime(t),
                                      child: Icon(Icons.close,
                                          size: 12,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Add time button
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showAddTimeDialog(context, isDark),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                  color: primaryColor.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3))
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.add, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text('Time',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ── Timetable grid (centered) ──────────────────────────
                Expanded(
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Color.lerp(const Color(0xFF0A0A10), primaryColor, 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: primaryColor.withOpacity(isDark ? 0.3 : 0.12),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: primaryColor.withOpacity(0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: ConstrainedBox(
                              // Make grid fill available width so it feels centered
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width - 32,
                              ),
                              child: DataTable(
                                headingRowHeight: 48,
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 52,
                                columnSpacing: 8,
                                headingRowColor: MaterialStateProperty.all(
                                    primaryColor.withOpacity(isDark ? 0.18 : 0.08)),
                                dataRowColor: MaterialStateProperty.resolveWith(
                                    (_) => Colors.transparent),
                                dividerThickness: 0.5,
                                columns: [
                                  DataColumn(
                                    label: Text('Time',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black54)),
                                  ),
                                  ..._days.map((d) {
                                    final isWeekend = d == 'Sat' || d == 'Sun';
                                    return DataColumn(
                                      label: Expanded(
                                        child: Text(
                                          d,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isWeekend
                                                ? (isDark
                                                    ? Colors.orange.shade300
                                                    : Colors.orange.shade700)
                                                : primaryColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                                rows: _times.map((time) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 52,
                                          child: Text(time,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: isDark
                                                      ? Colors.white60
                                                      : Colors.black45)),
                                        ),
                                      ),
                                      ..._days.map((day) {
                                        final cellKey = '$day-$time';
                                        final isWeekend = day == 'Sat' || day == 'Sun';
                                        return DataCell(
                                          DragTarget<String>(
                                            onAcceptWithDetails: (details) => setState(
                                                () => _schedule[cellKey] = details.data),
                                            builder: (context, candidateData, _) {
                                              final subject = _schedule[cellKey];
                                              final hasData = subject != null;
                                              final isHovered = candidateData.isNotEmpty;
                                              final cellColor = hasData
                                                  ? _colorForSubject(subject)
                                                  : primaryColor;

                                              return GestureDetector(
                                                onLongPress: hasData
                                                    ? () => setState(
                                                        () => _schedule.remove(cellKey))
                                                    : null,
                                                child: AnimatedContainer(
                                                  duration: const Duration(milliseconds: 180),
                                                  margin: const EdgeInsets.symmetric(
                                                      vertical: 5, horizontal: 2),
                                                  width: 82,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: isHovered
                                                        ? primaryColor.withOpacity(0.18)
                                                        : hasData
                                                            ? cellColor.withOpacity(
                                                                isDark ? 0.22 : 0.12)
                                                            : isWeekend
                                                                ? Colors.orange.withOpacity(
                                                                    isDark ? 0.04 : 0.03)
                                                                : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: isHovered
                                                        ? Border.all(
                                                            color: primaryColor, width: 1.5)
                                                        : hasData
                                                            ? Border.all(
                                                                color:
                                                                    cellColor.withOpacity(0.6),
                                                                width: 1.2)
                                                            : isWeekend
                                                                ? Border.all(
                                                                    color: Colors.orange
                                                                        .withOpacity(isDark
                                                                            ? 0.2
                                                                            : 0.15),
                                                                    width: 1)
                                                                : null,
                                                  ),
                                                  child: Center(
                                                    child: hasData
                                                        ? Text(subject,
                                                            style: TextStyle(
                                                                color: cellColor,
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 11),
                                                            overflow: TextOverflow.ellipsis,
                                                            textAlign: TextAlign.center)
                                                        : Text(
                                                            isHovered ? '+' : '·',
                                                            style: TextStyle(
                                                              color: isHovered
                                                                  ? primaryColor
                                                                  : isDark
                                                                      ? Colors.white12
                                                                      : Colors.black12,
                                                              fontSize: isHovered ? 18 : 14,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Hint ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Drag to assign · Long-press cell to remove',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isDark ? Colors.white24 : Colors.black26,
                        fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectChip(String subject, Color color, bool isDark,
      {bool dragging = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 6, top: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13131F) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: color.withOpacity(isDark ? 0.5 : 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(isDark ? 0.12 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 14),
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(subject,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(width: 4),
          if (!dragging)
            GestureDetector(
              onTap: () => _removeSubject(subject),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 0, 10, 0),
                child: Icon(Icons.close,
                    size: 14,
                    color: isDark ? Colors.white38 : Colors.black38),
              ),
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}