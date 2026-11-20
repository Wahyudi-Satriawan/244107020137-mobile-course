import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';

/// Fake repository terkendali untuk testing fitur notes tanpa menyentuh SQLite/jaringan.
/// Mendukung manipulasi data in-memory, simulasi kegagalan, dan completer untuk testing loading.
class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({
    List<Note>? initialNotes,
    this.fetchFailure,
    this.addFailure,
    this.throwOnFetch,
    this.throwOnAdd,
    this.fetchCompleter,
  }) : _notes = List<Note>.from(initialNotes ?? []);

  final List<Note> _notes;
  Failure? fetchFailure;
  Failure? addFailure;
  Exception? throwOnFetch;
  Exception? throwOnAdd;
  Completer<void>? fetchCompleter;

  /// Memberikan salinan immutable daftar catatan saat ini di memori
  List<Note> get currentNotes => List.unmodifiable(_notes);

  @override
  Future<(List<Note> notes, Failure? failure)> fetchNotes() async {
    // Jika completer disediakan, tunggu hingga completer di-complete oleh tester
    if (fetchCompleter != null) {
      await fetchCompleter!.future;
    }

    if (throwOnFetch != null) {
      throw throwOnFetch!;
    }

    if (fetchFailure != null) {
      return (const <Note>[], fetchFailure);
    }

    return (List<Note>.from(_notes), null);
  }

  @override
  Future<(Note? note, Failure? failure)> addNote({
    required String title,
    String body = '',
  }) async {
    if (throwOnAdd != null) {
      throw throwOnAdd!;
    }

    if (addFailure != null) {
      return (null, addFailure);
    }

    final newNote = Note(
      id: _notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    _notes.add(newNote);
    return (newNote, null);
  }
}
