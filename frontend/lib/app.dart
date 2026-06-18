import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_routes.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';


class StudentToolkitApp extends StatelessWidget {
  const StudentToolkitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Student Toolkit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
          routes: AppRoutes.routes,
        );
      },
    );
  }
}
