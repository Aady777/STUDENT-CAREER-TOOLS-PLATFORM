import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../providers/notes_provider.dart';
import '../../../../providers/theme_provider.dart';

class MarkdownController extends TextEditingController {
  MarkdownController({super.text});

  @override
  TextSpan buildTextSpan({required BuildContext context, TextStyle? style, required bool withComposing}) {
    List<TextSpan> spans = [];
    String sourceText = text;

    final RegExp exp = RegExp(r'(\*\*.*?\*\*|_.*?_)');
    int start = 0;

    for (final Match m in exp.allMatches(sourceText)) {
      if (m.start > start) {
        spans.add(TextSpan(text: sourceText.substring(start, m.start), style: style));
      }
      String matchText = m.group(0)!;
      if (matchText.startsWith('**')) {
        spans.add(TextSpan(text: '**', style: style?.copyWith(color: Colors.grey.withOpacity(0.5))));
        spans.add(TextSpan(
          text: matchText.substring(2, matchText.length - 2),
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ));
        spans.add(TextSpan(text: '**', style: style?.copyWith(color: Colors.grey.withOpacity(0.5))));
      } else if (matchText.startsWith('_')) {
        spans.add(TextSpan(text: '_', style: style?.copyWith(color: Colors.grey.withOpacity(0.5))));
        spans.add(TextSpan(
          text: matchText.substring(1, matchText.length - 1),
          style: style?.copyWith(fontStyle: FontStyle.italic),
        ));
        spans.add(TextSpan(text: '_', style: style?.copyWith(color: Colors.grey.withOpacity(0.5))));
      }
      start = m.end;
    }

    if (start < sourceText.length) {
      spans.add(TextSpan(text: sourceText.substring(start), style: style));
    }

    return TextSpan(children: spans, style: style);
  }
}

class NotesEditor extends StatefulWidget {
  final Note? note;
  const NotesEditor({super.key, this.note});

  @override
  State<NotesEditor> createState() => _NotesEditorState();
}

class _NotesEditorState extends State<NotesEditor> {
  late TextEditingController _titleController;
  late MarkdownController _contentController;
  late int _selectedColorIndex;

  final List<Color> noteColors = [
    const Color(0xFFF8FAFC), // Default
    const Color(0xFFFEE2E2), // Red
    const Color(0xFFFEF3C7), // Yellow
    const Color(0xFFD1FAE5), // Green
    const Color(0xFFDBEAFE), // Blue
    const Color(0xFFF3E8FF), // Purple
  ];

  final List<Color> noteColorsDark = [
    const Color(0xFF13131F), // Default
    const Color(0xFF451A1E), // Red
    const Color(0xFF423314), // Yellow
    const Color(0xFF0F3D27), // Green
    const Color(0xFF162D4A), // Blue
    const Color(0xFF3B2159), // Purple
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = MarkdownController(text: widget.note?.content ?? '');
    _selectedColorIndex = widget.note?.colorIndex ?? 0;
  }

  void _saveNote() {
    if (_titleController.text.trim().isEmpty && _contentController.text.trim().isEmpty) {
      Navigator.pop(context);
      return;
    }
    final id = widget.note?.id ?? DateTime.now().toString();
    Provider.of<NotesProvider>(context, listen: false).addOrUpdateNote(id, _titleController.text.isEmpty ? 'Untitled Note' : _titleController.text, _contentController.text, _selectedColorIndex);
    Navigator.pop(context);
  }

  void _insertFormatting(String wrapSyntax) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start == -1) {
      // No selection, insert at end
      _contentController.text = text + wrapSyntax + wrapSyntax;
      _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length - wrapSyntax.length);
    } else {
      // Wrap selection
      final selectedText = text.substring(selection.start, selection.end);
      final newText = text.replaceRange(selection.start, selection.end, '$wrapSyntax$selectedText$wrapSyntax');
      _contentController.text = newText;
      _contentController.selection = TextSelection(
        baseOffset: selection.start + wrapSyntax.length,
        extentOffset: selection.end + wrapSyntax.length,
      );
    }
  }

  void _insertList() {
    final text = _contentController.text;
    final selection = _contentController.selection;
    if (selection.start == -1) {
      _contentController.text = '$text\n• ';
      _contentController.selection = TextSelection.collapsed(offset: _contentController.text.length);
    } else {
      final newText = text.replaceRange(selection.start, selection.start, '\n• ');
      _contentController.text = newText;
      _contentController.selection = TextSelection.collapsed(offset: selection.start + 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final primaryColor = const Color(0xFFF59E0B);
    final bgColor = isDark ? noteColorsDark[_selectedColorIndex] : noteColors[_selectedColorIndex];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _saveNote,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: primaryColor, size: 28),
            onPressed: _saveNote,
            tooltip: 'Save Note',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        hintText: 'Title',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 28, fontWeight: FontWeight.bold),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      style: TextStyle(fontSize: 18, color: isDark ? Colors.white70 : Colors.black87, height: 1.6),
                      decoration: InputDecoration(
                        hintText: 'Start typing...',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 18),
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Toolbar for Formatting and Color Picker
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                ]
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Formatting Toolbar
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.format_bold, color: isDark ? Colors.white70 : Colors.black87),
                          onPressed: () => _insertFormatting('**'),
                          tooltip: 'Bold',
                        ),
                        IconButton(
                          icon: Icon(Icons.format_italic, color: isDark ? Colors.white70 : Colors.black87),
                          onPressed: () => _insertFormatting('_'),
                          tooltip: 'Italic',
                        ),
                        IconButton(
                          icon: Icon(Icons.format_list_bulleted, color: isDark ? Colors.white70 : Colors.black87),
                          onPressed: _insertList,
                          tooltip: 'Bullet List',
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _saveNote,
                          icon: const Icon(Icons.save, size: 18),
                          label: const Text('Save'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const Divider(height: 16),
                    // Color Picker Toolbar
                    Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: List.generate(noteColors.length, (index) {
                                final colorItem = isDark ? noteColorsDark[index] : noteColors[index];
                                final isSelected = _selectedColorIndex == index;
                                return GestureDetector(
                                  onTap: () => setState(() => _selectedColorIndex = index),
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: colorItem,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isSelected ? primaryColor : (isDark ? Colors.white24 : Colors.black12), width: isSelected ? 3 : 1),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
