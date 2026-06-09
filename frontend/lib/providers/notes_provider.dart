import 'package:flutter/material.dart';

class Note {
  final String id;
  String title;
  String content;
  final DateTime updatedAt;
  int colorIndex;

  Note({
    required this.id, 
    required this.title, 
    required this.content, 
    required this.updatedAt,
    this.colorIndex = 0,
  });
}

class NotesProvider extends ChangeNotifier {
  final List<Note> _notes = [
    Note(id: '1', title: 'Science Chapter 1', content: 'This is a rich text content preview...\n- Study mitochondria\n- Read about speed of light', updatedAt: DateTime.now(), colorIndex: 1),
    Note(id: '2', title: 'Ideas', content: 'Build a great student dashboard app.', updatedAt: DateTime.now(), colorIndex: 2),
  ];
  
  List<Note> get notes => _notes;

  void addOrUpdateNote(String id, String title, String content, int colorIndex) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index >= 0) {
      _notes[index].title = title;
      _notes[index].content = content;
      _notes[index].colorIndex = colorIndex;
    } else {
      _notes.add(Note(id: id, title: title, content: content, updatedAt: DateTime.now(), colorIndex: colorIndex));
    }
    notifyListeners();
  }

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }
}
