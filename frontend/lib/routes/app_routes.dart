import 'package:flutter/material.dart';
import '../features/cgpa/presentation/screens/cgpa_screen.dart';
import '../features/planner/presentation/screens/planner_screen.dart';
import '../features/notes/presentation/screens/notes_list.dart';
import '../features/test/presentation/screens/instructions_screen.dart';
import '../features/timetable/presentation/screens/timetable_builder.dart';

class AppRoutes {
  static const String home = '/';
  static const String cgpa = '/cgpa';
  static const String planner = '/planner';
  static const String notes = '/notes';
  static const String test = '/test';
  static const String timetable = '/timetable';

  static Map<String, WidgetBuilder> get routes => {
        cgpa: (context) => const CgpaScreen(),
        planner: (context) => const PlannerScreen(),
        notes: (context) => const NotesListScreen(),
        test: (context) => const InstructionsScreen(),
        timetable: (context) => const TimetableBuilder(),
      };
}
