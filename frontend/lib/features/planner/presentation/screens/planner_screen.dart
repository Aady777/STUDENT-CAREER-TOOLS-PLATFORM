import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/planner_provider.dart';
import '../../../../providers/theme_provider.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<PlannerProvider>(context, listen: false).fetchTasks();
    });
  }

  void _showAddTaskSheet(BuildContext context, bool isDark) {
    final titleController = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();
    const primaryColor = Color(0xFF10B981);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF13131F) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: primaryColor.withOpacity(isDark ? 0.3 : 0.15),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Add New Task',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: titleController,
                      autofocus: true,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Subject / Task',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                        prefixIcon:
                            const Icon(Icons.book_rounded, color: primaryColor),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setSheetState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time,
                                color: primaryColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Scheduled Time',
                                style: TextStyle(
                                  color:
                                      isDark ? Colors.white54 : Colors.black45,
                                ),
                              ),
                            ),
                            Text(
                              selectedTime.format(ctx),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: () {
                        final title = titleController.text.trim();
                        if (title.isEmpty) return;

                        Provider.of<PlannerProvider>(context, listen: false)
                            .addTask(
                                title, DateTime.now(), selectedTime.format(ctx));

                        Navigator.pop(ctx);
                      },
                      child: const Text("Add Task"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final planner = Provider.of<PlannerProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(title: const Text("Planner")),
      body: planner.tasks.isEmpty
          ? const Center(child: Text("No tasks yet"))
          : ListView.builder(
              itemCount: planner.tasks.length,
              itemBuilder: (context, index) {
                final task = planner.tasks[index];
                return ListTile(
                  title: Text(task.title),
                  subtitle: Text(task.time),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context, isDark),
        child: const Icon(Icons.add),
      ),
    );
  }
}