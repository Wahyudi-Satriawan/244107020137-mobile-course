import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/note_local_data_source.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';

// Data layer: database opener disuntikkan (mudah diganti fake saat test)
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// Domain layer: use case menerima abstraksi, bukan implementasi
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

// Presentation layer: state untuk UI
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final (notes, failure) = await ref.watch(getNotesProvider).call();
  if (failure != null) throw Exception(failure.message);
  return notes;
});
