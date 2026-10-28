import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/note_local_data_source.dart';
import '../../data/repositories/note_repository_impl.dart';
import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../../domain/usecases/get_notes.dart';
import '../../domain/usecases/search_notes_usecase.dart';

// ── Data layer ──────────────────────────────────────────────────────
final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  return NoteRepositoryImpl(openDb: openNotesDb);
});

// ── Domain layer ────────────────────────────────────────────────────
final getNotesProvider = Provider<GetNotes>((ref) {
  return GetNotes(ref.watch(noteRepositoryProvider));
});

final searchNotesUseCaseProvider = Provider<SearchNotesUseCase>((ref) {
  return const SearchNotesUseCase();
});

// ── Presentation layer ─────────────────────────────────────────────

/// Provider FutureProvider untuk ambil semua notes dari DB.
final allNotesProvider = FutureProvider<List<Note>>((ref) async {
  final (notes, failure) = await ref.watch(getNotesProvider).call();
  if (failure != null) throw Exception(failure.message);
  return notes;
});

/// Notifier untuk menyimpan keyword pencarian yang diketik user.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

/// Provider turunan: hasil filter notes berdasarkan search query.
/// UI hanya perlu watch provider ini.
final filteredNotesProvider = Provider<AsyncValue<List<Note>>>((ref) {
  final allNotesAsync = ref.watch(allNotesProvider);
  final query = ref.watch(searchQueryProvider);
  final searchUseCase = ref.watch(searchNotesUseCaseProvider);

  return allNotesAsync.whenData(
    (allNotes) => searchUseCase.call(allNotes: allNotes, query: query),
  );
});
