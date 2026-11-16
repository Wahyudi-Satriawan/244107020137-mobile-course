import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({required this.openDb});

  final Future<Database> Function() openDb;

  @override
  Future<(List<Note> notes, Failure? failure)> fetchNotes() async {
    try {
      final db = await openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();
      return (notes, null);
    } catch (e) {
      return (const <Note>[], LocalFailure('Gagal membaca catatan: $e'));
    }
  }

  @override
  Future<(Note? note, Failure? failure)> addNote({
    required String title,
    String body = '',
  }) async {
    try {
      final db = await openDb();
      final now = DateTime.now();
      final id = await db.insert(
        'notes',
        NoteModel(
          title: title,
          body: body,
          updatedAt: now,
          dirty: true,
        ).toMap(),
      );
      return (
        Note(id: id, title: title, body: body, updatedAt: now, dirty: true),
        null,
      );
    } catch (e) {
      return (null, LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }
}
