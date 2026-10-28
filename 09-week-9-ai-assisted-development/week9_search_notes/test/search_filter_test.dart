import 'package:flutter_test/flutter_test.dart';
import 'package:week9_search_notes/features/notes/domain/entities/note.dart';
import 'package:week9_search_notes/features/notes/domain/usecases/search_notes_usecase.dart';

void main() {
  late SearchNotesUseCase searchUseCase;
  late List<Note> sampleNotes;

  setUp(() {
    searchUseCase = const SearchNotesUseCase();

    sampleNotes = [
      Note(
        id: 1,
        title: 'Catatan Matematika',
        body: 'Integral dan turunan',
        updatedAt: DateTime(2024, 10, 1),
      ),
      Note(
        id: 2,
        title: 'Catatan Pemrograman Mobile',
        body: 'Flutter dan Dart',
        updatedAt: DateTime(2024, 10, 2),
      ),
      Note(
        id: 3,
        title: 'Resep Masakan',
        body: 'Nasi goreng spesial',
        updatedAt: DateTime(2024, 10, 3),
      ),
      Note(
        id: 4,
        title: 'catatan basis data',
        body: 'Normalisasi 1NF-3NF',
        updatedAt: DateTime(2024, 10, 4),
      ),
    ];
  });

  group('SearchNotesUseCase', () {
    test('mengembalikan semua notes jika query kosong', () {
      final result = searchUseCase.call(
        allNotes: sampleNotes,
        query: '',
      );

      expect(result, hasLength(4));
    });

    test('mengembalikan semua notes jika query hanya whitespace', () {
      final result = searchUseCase.call(
        allNotes: sampleNotes,
        query: '   ',
      );

      expect(result, hasLength(4));
    });

    test('memfilter notes berdasarkan keyword di title (case-insensitive)', () {
      final result = searchUseCase.call(
        allNotes: sampleNotes,
        query: 'catatan',
      );

      // "Catatan Matematika", "Catatan Pemrograman Mobile", "catatan basis data"
      expect(result, hasLength(3));
    });

    test('mengembalikan list kosong jika tidak ada yang cocok', () {
      final result = searchUseCase.call(
        allNotes: sampleNotes,
        query: 'fisika kuantum',
      );

      expect(result, isEmpty);
    });

    test('mendukung pencarian parsial di tengah judul', () {
      final result = searchUseCase.call(
        allNotes: sampleNotes,
        query: 'mobile',
      );

      expect(result, hasLength(1));
      expect(result.first.title, 'Catatan Pemrograman Mobile');
    });

    test('mengembalikan list kosong dari list notes kosong', () {
      final result = searchUseCase.call(
        allNotes: [],
        query: 'apapun',
      );

      expect(result, isEmpty);
    });
  });
}
