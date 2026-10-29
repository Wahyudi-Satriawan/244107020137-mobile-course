import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/repositories/note_repository.dart';
import 'package:campus_notify/features/notes/domain/usecases/add_note.dart';
import 'package:campus_notify/features/notes/domain/usecases/validate_note.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeNoteRepository implements NoteRepository {
  final List<Note> notes = [];

  @override
  Future<(List<Note>, Failure?)> fetchNotes() async {
    return (notes, null);
  }

  @override
  Future<(Note?, Failure?)> addNote({
    required String title,
    String body = '',
  }) async {
    final note = Note(
      id: notes.length + 1,
      title: title,
      body: body,
      updatedAt: DateTime.now(),
    );
    notes.add(note);
    return (note, null);
  }
}

void main() {
  group('ValidateNote Domain Logic', () {
    const validator = ValidateNote();

    test(
      'Skenario gagal: judul null atau kosong mengembalikan ValidationFailure',
      () {
        final resNull = validator(null);
        expect(resNull, isA<ValidationFailure>());
        expect(resNull?.message, 'Judul tidak boleh kosong');

        final resEmpty = validator('');
        expect(resEmpty, isA<ValidationFailure>());
        expect(resEmpty?.message, 'Judul tidak boleh kosong');
      },
    );

    test('Skenario gagal: judul hanya berisi spasi/whitespace mengembalikan ValidationFailure', () {
      final resWhitespace = validator('    ');
      expect(resWhitespace, isA<ValidationFailure>());
      expect(resWhitespace?.message, 'Judul tidak boleh kosong');
    });

    test('Skenario gagal: judul kurang dari 3 karakter mengembalikan ValidationFailure', () {
      final resShort = validator('ab');
      expect(resShort, isA<ValidationFailure>());
      expect(resShort?.message, 'Judul minimal 3 karakter');
    });

    test(
      'Skenario sukses: judul valid lolos validasi (mengembalikan null)',
      () {
        final resValid = validator('Catatan Kuliah');
        expect(resValid, isNull);
      },
    );
  });

  group('AddNote UseCase Integration dengan Validasi', () {
    late FakeNoteRepository repo;
    late AddNote addNote;

    setUp(() {
      repo = FakeNoteRepository();
      addNote = AddNote(repo);
    });

    test(
      'Skenario gagal: judul kosong ditolak sebelum masuk repository',
      () async {
        final (note, failure) = await addNote(title: '   ');
        expect(note, isNull);
        expect(failure, isA<ValidationFailure>());
        expect(failure?.message, 'Judul tidak boleh kosong');
        expect(repo.notes, isEmpty);
      },
    );

    test('Skenario gagal: judul kurang dari 3 karakter ditolak', () async {
      final (note, failure) = await addNote(title: 'ab');
      expect(note, isNull);
      expect(failure, isA<ValidationFailure>());
      expect(failure?.message, 'Judul minimal 3 karakter');
      expect(repo.notes, isEmpty);
    });

    test(
      'Skenario sukses: judul valid berhasil disimpan ke repository',
      () async {
        final (note, failure) = await addNote(
          title: '  Praktikum Clean Architecture  ',
          body: 'Implementasi validasi use case',
        );
        expect(failure, isNull);
        expect(note, isNotNull);
        expect(note?.title, 'Praktikum Clean Architecture');
        expect(repo.notes.length, 1);
      },
    );
  });
}
