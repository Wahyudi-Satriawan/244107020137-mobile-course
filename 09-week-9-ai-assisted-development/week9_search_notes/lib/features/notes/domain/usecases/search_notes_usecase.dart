import '../entities/note.dart';

/// Use case PURE domain: filter notes berdasarkan keyword di title.
///
/// Tidak ada dependency ke data layer maupun framework.
/// Logika case-insensitive matching diisolasi di sini supaya
/// bisa di-unit-test tanpa Flutter/SQLite.
class SearchNotesUseCase {
  const SearchNotesUseCase();

  /// Menerima [allNotes] dan [query], lalu mengembalikan list
  /// yang title-nya mengandung [query] (case-insensitive).
  ///
  /// Jika [query] kosong atau hanya whitespace, semua notes dikembalikan.
  List<Note> call({
    required List<Note> allNotes,
    required String query,
  }) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return allNotes;
    return allNotes
        .where((note) => note.title.toLowerCase().contains(trimmed))
        .toList();
  }
}
