import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../routes/app_routes.dart';
import '../../../../providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    final cards = [
      PremiumCard(
        title: 'CGPA Calculator', 
        subtitle: 'Calculate, Track & Improve\nYour Performance', 
        btnText: 'Calculate Now →', 
        colorStart: const Color(0xFF6366F1), 
        colorEnd: const Color(0xFF8B5CF6), 
        route: AppRoutes.cgpa,
        customTopIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFE0E7FF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('-', style: TextStyle(color: Color(0xFF4338CA), fontSize: 18, fontWeight: FontWeight.w900, height: 0.9)),
                    SizedBox(width: 4),
                    Text('x', style: TextStyle(color: Color(0xFF4338CA), fontSize: 14, fontWeight: FontWeight.w900, height: 0.9)),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('+', style: TextStyle(color: Color(0xFF4338CA), fontSize: 16, fontWeight: FontWeight.w900, height: 0.9)),
                    SizedBox(width: 4),
                    Text('=', style: TextStyle(color: Color(0xFF4338CA), fontSize: 16, fontWeight: FontWeight.w900, height: 0.9)),
                  ],
                ),
              ],
            ),
          ),
        ),
        backgroundGraphics: [
          Positioned(
            top: 20,
            right: 20,
            child: Transform.rotate(
              angle: -0.2,
              child: Icon(Icons.analytics_rounded, size: 80, color: const Color(0xFF6366F1).withOpacity(isDark ? 0.15 : 0.08)),
            ),
          ),
          Positioned(
            bottom: -5,
            right: 15,
            child: Transform.rotate(
              angle: 0.1,
              child: Icon(Icons.calculate_rounded, size: 100, color: const Color(0xFF6366F1).withOpacity(isDark ? 0.15 : 0.08)),
            ),
          ),
        ],
      ),
      PremiumCard(
        title: 'Study Planner', 
        subtitle: 'Plan Smarter, Study Better,\nStay Consistent', 
        btnText: 'Start Planning →', 
        colorStart: const Color(0xFF10B981), 
        colorEnd: const Color(0xFF34D399), 
        route: AppRoutes.planner,
        customTopIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.event_note_rounded, color: Color(0xFF047857), size: 26),
          ),
        ),
        backgroundGraphics: [
          Positioned(
            bottom: -5,
            right: 10,
            child: Transform.rotate(
              angle: -0.1,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 90, color: const Color(0xFF10B981).withOpacity(isDark ? 0.15 : 0.08)),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Container(
                      decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF0A0A10) : Colors.white),
                      child: Icon(Icons.schedule_rounded, size: 45, color: const Color(0xFF10B981).withOpacity(isDark ? 0.3 : 0.15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      PremiumCard(
        title: 'Notes Maker', 
        subtitle: 'Capture ideas & organize\nyour thoughts', 
        btnText: 'Write Notes →', 
        colorStart: const Color(0xFFF59E0B), 
        colorEnd: const Color(0xFFFCD34D), 
        route: AppRoutes.notes,
        customTopIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.edit_document, color: Color(0xFFB45309), size: 26),
          ),
        ),
        backgroundGraphics: [
          Positioned(
            top: 10,
            right: 10,
            child: Transform.rotate(
              angle: 0.15,
              child: Icon(Icons.edit_document, size: 80, color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.15 : 0.08)),
            ),
          ),
          Positioned(
            bottom: 25,
            right: 30,
            child: Transform.rotate(
              angle: -0.1,
              child: Icon(Icons.draw_rounded, size: 50, color: const Color(0xFFF59E0B).withOpacity(isDark ? 0.15 : 0.08)),
            ),
          ),
        ],
      ),
      PremiumCard(
        title: 'Mock Test', 
        subtitle: 'Evaluate your prep with\ntimed tests', 
        btnText: 'Take Test →', 
        colorStart: const Color(0xFFE11D48), 
        colorEnd: const Color(0xFFFDA4AF), 
        route: AppRoutes.test,
        customTopIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE4E6),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.quiz_rounded, color: Color(0xFFBE123C), size: 26),
          ),
        ),
        backgroundGraphics: [
          Positioned(
            bottom: 0,
            right: 10,
            child: Transform.rotate(
              angle: -0.15,
              child: Icon(Icons.assignment_turned_in_rounded, size: 100, color: const Color(0xFFE11D48).withOpacity(isDark ? 0.15 : 0.08)),
            ),
          ),
        ],
      ),
      PremiumCard(
        title: 'Time Table', 
        subtitle: 'Structure your week\nefficiently', 
        btnText: 'Build Schedule →', 
        colorStart: const Color(0xFF3B82F6), 
        colorEnd: const Color(0xFF67E8F9), 
        route: AppRoutes.timetable,
        customTopIcon: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.calendar_month_rounded, color: Color(0xFF1D4ED8), size: 26),
          ),
        ),
        backgroundGraphics: [
          Positioned(
            bottom: 0,
            right: 10,
            child: Transform.rotate(
              angle: 0.1,
              child: Icon(Icons.view_week_rounded, size: 100, color: const Color(0xFF3B82F6).withOpacity(isDark ? 0.15 : 0.08)),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Base Background
          Container(color: isDark ? const Color(0xFF0A0A10) : const Color(0xFFF8FAFC)),
          
          // Background Glow Effect - Top Right
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDark ? const Color(0xFF4C1D95).withOpacity(0.4) : Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Background Glow Effect - Center Left
          Positioned(
            bottom: 0,
            left: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDark ? const Color(0xFF14B8A6).withOpacity(0.15) : const Color(0xFF99F6E4).withOpacity(0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Student Toolkit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      GestureDetector(
                        onTap: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2D2A4A) : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? const Color(0xFF6366F1).withOpacity(0.2) : Colors.transparent),
                                child: Icon(Icons.dark_mode, size: 18, color: isDark ? const Color(0xFFA5B4FC) : Colors.grey.shade500),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(shape: BoxShape.circle, color: isDark ? Colors.transparent : Colors.white),
                                child: Icon(Icons.light_mode, size: 18, color: isDark ? Colors.grey.shade600 : const Color(0xFFF59E0B)),
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                
                // Welcome Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2D2A4A) : const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('🚀 Ready to Achieve!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF4F46E5))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          RichText(
                            text: TextSpan(
                              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A), fontFamily: 'Poppins'),
                              children: [
                                const TextSpan(text: 'Welcome back, '),
                                TextSpan(text: 'Scholar!', style: TextStyle(color: isDark ? const Color(0xFFA855F7) : const Color(0xFF6366F1))),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.auto_awesome, color: const Color(0xFFEAB308), size: 30),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("Let's make today productive 🚀", style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : const Color(0xFF64748B))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                // Feature Cards Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 360, // limits width of card so it's not too wide
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.15, // limits height of card so it's not too tall
                    ),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      return cards[index];
                    },
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

class PremiumCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String btnText;
  final Widget customTopIcon;
  final Color colorStart;
  final Color colorEnd;
  final String route;
  final List<Widget> backgroundGraphics;

  const PremiumCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.btnText,
    required this.customTopIcon,
    required this.colorStart,
    required this.colorEnd,
    required this.route,
    required this.backgroundGraphics,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: isDark ? Color.lerp(const Color(0xFF0A0A10), widget.colorStart, 0.15) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: widget.colorStart.withOpacity(isDark ? (_isHovered ? 0.6 : 0.4) : (_isHovered ? 0.3 : 0.15)),
                blurRadius: _isHovered ? 40 : 25,
                spreadRadius: isDark ? 2 : 0,
                offset: const Offset(0, 0),
              ),
            ],
            border: Border.all(
              color: widget.colorStart.withOpacity(isDark ? 0.8 : 0.3), 
              width: 2.5
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pushNamed(context, widget.route),
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Subtle gradient inside to match image
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.colorStart.withOpacity(isDark ? 0.25 : 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Background Custom Graphics matching image exactly
                  ...widget.backgroundGraphics,
                  
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // White/Tinted rounded icon box exactly matching image
                        widget.customTopIcon,
                        const Spacer(),
                        Text(widget.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                        const SizedBox(height: 6),
                        Text(widget.subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black54, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 16),
                        // Colored Button
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: widget.colorStart,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: widget.colorStart.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ]
                          ),
                          child: Text(widget.btnText, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
