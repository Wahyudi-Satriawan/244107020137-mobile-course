import 'package:sqflite/sqflite.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../models/note_model.dart';

/// Implementasi NoteRepository dengan optimasi in-memory caching
/// untuk mencegah disk I/O berulang pada SQLite saat rebuild/navigasi.
class NoteRepositoryImpl implements NoteRepository {
  NoteRepositoryImpl({
    required this.openDb,
    this.cacheTtl = const Duration(seconds: 30),
  });

  final Future<Database> Function() openDb;
  final Duration cacheTtl;

  // In-memory cache
  List<Note>? _memoryCache;
  DateTime? _lastFetchTime;

  @override
  Future<(List<Note> notes, Failure? failure)> fetchNotes() async {
    // 1. Cek apakah in-memory cache masih valid
    if (_memoryCache != null && _lastFetchTime != null) {
      final isFresh = DateTime.now().difference(_lastFetchTime!) < cacheTtl;
      if (isFresh) {
        return (_memoryCache!, null);
      }
    }

    // 2. Fetch fresh data dari SQLite database jika cache expired / belum ada
    try {
      final db = await openDb();
      final rows = await db.query('notes', orderBy: 'updated_at DESC');
      final notes = rows.map((r) => NoteModel.fromMap(r).toEntity()).toList();

      // 3. Simpan ke in-memory cache
      _memoryCache = List.unmodifiable(notes);
      _lastFetchTime = DateTime.now();

      return (notes, null);
    } catch (e) {
      // Fallback ke cache jika ada error
      if (_memoryCache != null) {
        return (_memoryCache!, null);
      }
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

      final newNote = Note(
        id: id,
        title: title,
        body: body,
        updatedAt: now,
        dirty: true,
      );

      // Invalidate atau update cache segera agar data tetap konsisten
      _memoryCache = null;
      _lastFetchTime = null;

      return (newNote, null);
    } catch (e) {
      return (null, LocalFailure('Gagal menyimpan catatan: $e'));
    }
  }
}
