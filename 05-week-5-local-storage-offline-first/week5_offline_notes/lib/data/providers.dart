import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repositories/note_repository.dart';
import 'local/note.dart';

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepository();
});

final notesProvider = FutureProvider<List<Note>>((ref) {
  final repo = ref.read(noteRepositoryProvider);
  return repo.fetchNotes();
});