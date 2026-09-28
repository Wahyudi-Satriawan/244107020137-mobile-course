import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:week5_offline_notes/data/local/note.dart';
import 'package:week5_offline_notes/data/repositories/note_repository.dart';
// Ini import penting agar noteRepositoryProvider dan notesProvider dikenali
import 'package:week5_offline_notes/data/providers.dart'; 

class FakeNoteRepository extends NoteRepository {
  FakeNoteRepository({this.items, this.throwError = false})
      // PERBAIKAN: Menambahkan openDb: dan async sesuai panduan
      : super(openDb: () async => throw UnimplementedError());

  final List<Note>? items;
  final bool throwError;

  @override
  Future<List<Note>> fetchNotes() async {
    if (throwError) throw Exception("DB locked simulasi");
    return items ?? [];
  }

  @override
  Future<int> countDirty() async =>
      (items ?? []).where((n) => n.dirty).length;
}

void main() {
  test('fromMap aman terhadap null/hilang', () {
    final note = Note.fromMap({'title': 'Test'});
    expect(note.title, 'Test');
    expect(note.body, '');
    expect(note.dirty, isFalse);
  });

  test('flag dirty tersimpan pada toMap', () {
    final note = Note(
      title: 'A',
      body: 'B',
      updatedAt: DateTime(2026, 1, 1),
      dirty: true,
    );
    final restored = Note.fromMap(note.toMap());
    expect(restored.dirty, isTrue);
  });

  test('provider dengan repository palsu sukses', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(items: [
            Note(title: 'Tes 123', body: '', updatedAt: DateTime.now(), dirty: false),
          ]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final notes = await container.read(notesProvider.future);
    expect(notes.length, 1);
    expect(notes.first.title, 'Tes 123');
  });

  test('provider dengan repository palsu error', () async {
    final container = ProviderContainer(
      overrides: [
        noteRepositoryProvider.overrideWithValue(
          FakeNoteRepository(throwError: true),
        ),
      ],
    );
    addTearDown(container.dispose);

    expectLater(
      container.read(notesProvider.future),
      throwsA(isA<Exception>()),
    );
  });
}