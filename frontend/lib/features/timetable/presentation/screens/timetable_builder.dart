import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/theme_provider.dart';

class TimetableBuilder extends StatefulWidget {
  const TimetableBuilder({super.key});

  @override
  State<TimetableBuilder> createState() => _TimetableBuilderState();
}

class _TimetableBuilderState extends State<TimetableBuilder> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<String> _times = ['9 AM', '10 AM', '11 AM', '12 PM', '1 PM', '2 PM'];
  final Map<String, String> _schedule = {};

  final List<String> _subjects = ['Physics', 'Maths', 'CS', 'History', 'English'];

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = const Color(0xFF3B82F6);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Timetable Builder', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
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
              children: [
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _subjects.length,
                    itemBuilder: (context, index) {
                      return Draggable<String>(
                        data: _subjects[index],
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: primaryColor.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                              ]
                            ),
                            child: Text(_subjects[index], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12, bottom: 8, top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF13131F) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(isDark ? 0.4 : 0.2), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withOpacity(isDark ? 0.1 : 0.05), blurRadius: 8, offset: const Offset(0, 4))
                            ]
                          ),
                          child: Center(child: Text(_subjects[index], style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                        ),
                      );
                    },
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Color.lerp(const Color(0xFF0A0A10), primaryColor, 0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: primaryColor.withOpacity(isDark ? 0.3 : 0.1), width: 1.5),
                      boxShadow: [
                        BoxShadow(color: primaryColor.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                      ]
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: MaterialStateProperty.all(primaryColor.withOpacity(0.1)),
                            dataRowColor: MaterialStateProperty.all(Colors.transparent),
                            dividerThickness: 0.5,
                            columns: [
                              DataColumn(label: Text('Time', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                              ..._days.map((d) => DataColumn(label: Text(d, style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)))),
                            ],
                            rows: _times.map((time) {
                              return DataRow(
                                cells: [
                                  DataCell(Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54))),
                                  ..._days.map((day) {
                                    final cellKey = '$day-$time';
                                    return DataCell(
                                      DragTarget<String>(
                                        onAcceptWithDetails: (details) => setState(() => _schedule[cellKey] = details.data),
                                        builder: (context, candidateData, rejectedData) {
                                          final hasData = _schedule.containsKey(cellKey);
                                          final isHovered = candidateData.isNotEmpty;
                                          return Container(
                                            margin: const EdgeInsets.symmetric(vertical: 4),
                                            width: 90,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: isHovered 
                                                  ? primaryColor.withOpacity(0.2) 
                                                  : (hasData ? primaryColor.withOpacity(isDark ? 0.15 : 0.1) : Colors.transparent),
                                              borderRadius: BorderRadius.circular(8),
                                              border: hasData ? Border.all(color: primaryColor.withOpacity(0.5)) : (isHovered ? Border.all(color: primaryColor) : null),
                                            ),
                                            child: Center(
                                              child: hasData
                                                ? Text(_schedule[cellKey]!, style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold))
                                                : Text('-', style: TextStyle(color: isDark ? Colors.white24 : Colors.black12)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
