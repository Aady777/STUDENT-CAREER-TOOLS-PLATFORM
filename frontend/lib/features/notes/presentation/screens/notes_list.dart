import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/notes_provider.dart';
import '../../../../providers/theme_provider.dart';
import 'notes_editor.dart';

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  String _searchQuery = '';

  final List<Color> noteColors = [
    const Color(0xFFF8FAFC), // Default Light
    const Color(0xFFFEE2E2), // Red
    const Color(0xFFFEF3C7), // Yellow
    const Color(0xFFD1FAE5), // Green
    const Color(0xFFDBEAFE), // Blue
    const Color(0xFFF3E8FF), // Purple
  ];

  final List<Color> noteColorsDark = [
    const Color(0xFF13131F), // Default Dark
    const Color(0xFF451A1E), // Red Dark
    const Color(0xFF423314), // Yellow Dark
    const Color(0xFF0F3D27), // Green Dark
    const Color(0xFF162D4A), // Blue Dark
    const Color(0xFF3B2159), // Purple Dark
  ];

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final allNotes = Provider.of<NotesProvider>(context).notes;
    final notes = allNotes.where((n) => n.title.toLowerCase().contains(_searchQuery.toLowerCase()) || n.content.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    // Sort by most recent
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = const Color(0xFFF59E0B);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('My Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: Stack(
        children: [
          Container(color: isDark ? const Color(0xFF0A0A10) : const Color(0xFFF8FAFC)),
          Positioned(
            top: 50, right: -50,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryColor.withOpacity(isDark ? 0.15 : 0.2), Colors.transparent],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search your notes...',
                      hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                      prefixIcon: Icon(Icons.search, color: isDark ? Colors.white54 : Colors.black54),
                      filled: true,
                      fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                Expanded(
                  child: notes.isEmpty 
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_alt_outlined, size: 64, color: isDark ? Colors.white24 : Colors.black26),
                            const SizedBox(height: 16),
                            Text("No Notes Found", style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ) 
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 300,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final bgColor = isDark ? noteColorsDark[note.colorIndex % noteColorsDark.length] : noteColors[note.colorIndex % noteColors.length];
                          
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotesEditor(note: note))),
                            child: Container(
                              decoration: BoxDecoration(
                                color: bgColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 1),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                                ]
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(note.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: 12),
                                        Expanded(
                                          child: Text(
                                            note.content, 
                                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 14, height: 1.5), 
                                            overflow: TextOverflow.fade,
                                          )
                                        ),
                                        const SizedBox(height: 12),
                                        Text(_formatDate(note.updatedAt), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      color: isDark ? Colors.white38 : Colors.black38,
                                      onPressed: () {
                                        Provider.of<NotesProvider>(context, listen: false).deleteNote(note.id);
                                      },
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        elevation: 8,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const NotesEditor()));
        },
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }
}
