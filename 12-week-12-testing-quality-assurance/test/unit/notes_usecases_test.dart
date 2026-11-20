import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/domain/usecases/add_note.dart';
import 'package:campus_notify/features/notes/domain/usecases/get_notes.dart';
import 'package:campus_notify/features/notes/domain/usecases/validate_note.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_note_repository.dart';

void main() {
  group('ValidateNote Edge Cases & Boundary Logic', () {
    const validator = ValidateNote();

    test('Menolak string kosong, null, tab, dan newline', () {
      // Arrange & Act & Assert
      expect(validator(null)?.message, 'Judul tidak boleh kosong');
      expect(validator('')?.message, 'Judul tidak boleh kosong');
      expect(validator('   ')?.message, 'Judul tidak boleh kosong');
      expect(validator('\t\n  \r')?.message, 'Judul tidak boleh kosong');
    });

    test('Menolak judul yang memiliki kurang dari 3 karakter setelah di-trim', () {
      // Arrange & Act & Assert
      expect(validator('a')?.message, 'Judul minimal 3 karakter');
      expect(validator('ab')?.message, 'Judul minimal 3 karakter');
      expect(validator('  a  ')?.message, 'Judul minimal 3 karakter');
      expect(validator('  ab \t')?.message, 'Judul minimal 3 karakter');
    });

    test('Menerima judul tepat 3 karakter (boundary minimum valid)', () {
      // Arrange & Act & Assert
      expect(validator('abc'), isNull);
      expect(validator('123'), isNull);
      expect(validator('  xyz  '), isNull);
    });

    test('Menerima judul dengan karakter simbol, spasi ganda, dan karakter khusus', () {
      // Arrange & Act & Assert
      expect(validator('[PENTING] Modul #12 - QA'), isNull);
      expect(validator('Catatan: Tugas (Mobile Programming) v1.0'), isNull);
      expect(validator('Dart & Flutter 🚀'), isNull);
    });

    test('Menerima judul yang sangat panjang (stress input 500 karakter)', () {
      // Arrange
      final longTitle = 'A' * 500;
      // Act & Assert
      expect(validator(longTitle), isNull);
    });
  });

  group('GetNotes UseCase dengan FakeNoteRepository', () {
    test('Berhasil meneruskan daftar catatan kosong saat inisialisasi', () async {
      // Arrange
      final fakeRepo = FakeNoteRepository(initialNotes: []);
      final useCase = GetNotes(fakeRepo);

      // Act
      final (notes, failure) = await useCase();

      // Assert
      expect(failure, isNull);
      expect(notes, isEmpty);
    });

    test('Berhasil meneruskan daftar banyak catatan secara deterministik', () async {
      // Arrange
      final initialData = [
        Note(id: 1, title: 'Catatan 1', body: 'Isi 1', updatedAt: DateTime(2026, 1, 1)),
        Note(id: 2, title: 'Catatan 2', body: 'Isi 2', updatedAt: DateTime(2026, 1, 2)),
      ];
      final fakeRepo = FakeNoteRepository(initialNotes: initialData);
      final useCase = GetNotes(fakeRepo);

      // Act
      final (notes, failure) = await useCase();

      // Assert
      expect(failure, isNull);
      expect(notes.length, 2);
      expect(notes[0].title, 'Catatan 1');
      expect(notes[1].title, 'Catatan 2');
    });

    test('Gagal: meneruskan Failure dan TIDAK diam-diam mengembalikan data sukses', () async {
      // Arrange
      const expectedFailure = LocalFailure('Database SQLite terkunci');
      final fakeRepo = FakeNoteRepository(fetchFailure: expectedFailure);
      final useCase = GetNotes(fakeRepo);

      // Act
      final (notes, failure) = await useCase();

      // Assert
      expect(failure, equals(expectedFailure));
      expect(failure?.message, 'Database SQLite terkunci');
      expect(notes, isEmpty);
    });

    test('Gagal: meneruskan Exception yang dilempar oleh repository', () async {
      // Arrange
      final fakeRepo = FakeNoteRepository(
        throwOnFetch: Exception('Fatal I/O Error pada storage'),
      );
      final useCase = GetNotes(fakeRepo);

      // Act & Assert
      expect(() => useCase(), throwsA(isA<Exception>()));
    });
  });

  group('AddNote UseCase dengan FakeNoteRepository', () {
    late FakeNoteRepository fakeRepo;
    late AddNote addNote;

    setUp(() {
      fakeRepo = FakeNoteRepository();
      addNote = AddNote(fakeRepo);
    });

    test('Sukses menyimpan catatan valid dengan trimming otomatis', () async {
      // Arrange
      const rawTitle = '   Praktikum Flutter QA   ';
      const rawBody = '   Mempelajari Unit & Widget Test   ';

      // Act
      final (note, failure) = await addNote(title: rawTitle, body: rawBody);

      // Assert
      expect(failure, isNull);
      expect(note, isNotNull);
      expect(note?.title, 'Praktikum Flutter QA');
      expect(note?.body, 'Mempelajari Unit & Widget Test');
      expect(fakeRepo.currentNotes.length, 1);
      expect(fakeRepo.currentNotes.first.id, 1);
    });

    test('Gagal: validasi membatalkan pemanggilan repository jika judul tidak valid', () async {
      // Arrange & Act
      final (note, failure) = await addNote(title: ' x ');

      // Assert
      expect(note, isNull);
      expect(failure, isA<ValidationFailure>());
      expect(failure?.message, 'Judul minimal 3 karakter');
      expect(fakeRepo.currentNotes, isEmpty);
    });

    test('Gagal: repository mengembalikan Failure saat operasi penambahan catatan gagal', () async {
      // Arrange
      fakeRepo.addFailure = const LocalFailure('Gagal menulis ke tabel notes: Disk Penuh');

      // Act
      final (note, failure) = await addNote(title: 'Catatan Baru');

      // Assert
      expect(note, isNull);
      expect(failure, isA<LocalFailure>());
      expect(failure?.message, contains('Disk Penuh'));
      expect(fakeRepo.currentNotes, isEmpty);
    });

    test('Gagal: repository melempar Exception tak terduga', () async {
      // Arrange
      fakeRepo.throwOnAdd = Exception('Database Corrupted');

      // Act & Assert
      expect(
        () => addNote(title: 'Catatan Valid'),
        throwsA(isA<Exception>()),
      );
      expect(fakeRepo.currentNotes, isEmpty);
    });
  });

  group('Riverpod notesProvider State & Error Handling', () {
    test('notesProvider mengalirkan data sukses ke subscriber', () async {
      // Arrange
      final fakeRepo = FakeNoteRepository(
        initialNotes: [
          Note(id: 1, title: 'Note Provider Test', body: '', updatedAt: DateTime.now()),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Act
      final notes = await container.read(notesProvider.future);

      // Assert
      expect(notes.length, 1);
      expect(notes.first.title, 'Note Provider Test');
    });

    test('notesProvider mengalirkan state AsyncError saat fetch failure, tidak menjadi empty list palsu', () async {
      // Arrange
      final fakeRepo = FakeNoteRepository(
        fetchFailure: const LocalFailure('Koneksi database terputus'),
      );
      final container = ProviderContainer(
        overrides: [
          noteRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      // Act: trigger provider evaluation
      container.listen(notesProvider, (previous, next) {});
      await pumpEventQueue();

      // Assert: State harus memiliki error dengan pesan kegagalan yang tepat dan tidak memiliki data palsu
      final state = container.read(notesProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('Koneksi database terputus'));
      expect(state.hasValue, isFalse);
    });
  });
}
