import 'package:flutter_test/flutter_test.dart';
import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/get_notes.dart';

class FakeNoteRepository implements NoteRepository {
  FakeNoteRepository({this.items = const [], this.fail = false});

  final List<Note> items;
  final bool fail;

  @override
  Future<(List<Note>, Failure?)> fetchNotes() async {
    if (fail) {
      return (
        const <Note>[],
        const LocalFailure('db locked (simulasi)'),
      );
    }
    return (items, null);
  }

  @override
  Future<(Note?, Failure?)> addNote({
    required String title,
    String body = '',
  }) {
    throw UnimplementedError();
  }
}

void main() {
  test('GetNotes meneruskan daftar dari repository', () async {
    final repo = FakeNoteRepository(items: [
      Note(title: 'A', body: '', updatedAt: DateTime(2026, 3, 27)),
    ]);
    final result = await GetNotes(repo).call();
    expect(result.$2, isNull);
    expect(result.$1.length, 1);
    expect(result.$1.first.title, 'A');
  });

  test('GetNotes meneruskan failure tanpa melempar', () async {
    final repo = FakeNoteRepository(fail: true);
    final result = await GetNotes(repo).call();
    expect(result.$2, isA<LocalFailure>());
    expect(result.$1, isEmpty);
  });
}
