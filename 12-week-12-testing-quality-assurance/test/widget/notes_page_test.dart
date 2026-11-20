import 'dart:async';

import 'package:campus_notify/core/failures.dart';
import 'package:campus_notify/features/notes/domain/entities/note.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_notify/features/notes/presentation/widgets/notes_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_note_repository.dart';

void main() {
  Widget buildTestableWidget(FakeNoteRepository fakeRepo) {
    return ProviderScope(
      overrides: [
        noteRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(
        home: NotesPage(),
      ),
    );
  }

  group('NotesPage Widget Tests - Rendering States', () {
    testWidgets(
      'Loading state: menampilkan CircularProgressIndicator secara deterministik via Completer tanpa Future.delayed',
      (tester) async {
        // Arrange: Siapkan completer untuk mengontrol transisi loading secara presisi
        final fetchCompleter = Completer<void>();
        final fakeRepo = FakeNoteRepository(
          initialNotes: [
            Note(id: 1, title: 'Catatan Tes', body: 'Isi', updatedAt: DateTime.now()),
          ],
          fetchCompleter: fetchCompleter,
        );

        // Act: Render widget pertama kali
        await tester.pumpWidget(buildTestableWidget(fakeRepo));
        // Pump 1 frame tanpa settle agar async future tertahan di state loading
        await tester.pump();

        // Assert: Loading indicator harus tampil di tengah layar
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Catatan Tes'), findsNothing);

        // Act: Selesaikan asynchronous fetch
        fetchCompleter.complete();
        await tester.pumpAndSettle();

        // Assert: Loading indicator hilang, item catatan telah dirender
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Catatan Tes'), findsOneWidget);
      },
    );

    testWidgets('Empty state: menampilkan pesan "Belum ada catatan." saat repositori kosong', (tester) async {
      // Arrange
      final fakeRepo = FakeNoteRepository(initialNotes: []);

      // Act
      await tester.pumpWidget(buildTestableWidget(fakeRepo));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Belum ada catatan.'), findsOneWidget);
      expect(find.byType(NotesList), findsNothing);
      expect(find.byKey(const Key('add-note-fab')), findsOneWidget);
    });

    testWidgets('Error state: menampilkan pesan error saat fetchNotes mengembalikan Failure', (tester) async {
      // Arrange
      final fakeRepo = FakeNoteRepository(
        fetchFailure: const LocalFailure('Gagal memuat catatan dari database lokal'),
      );

      // Act
      await tester.pumpWidget(buildTestableWidget(fakeRepo));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Gagal memuat catatan dari database lokal'), findsOneWidget);
      expect(find.text('Belum ada catatan.'), findsNothing);
      expect(find.byType(NotesList), findsNothing);
    });
  });

  group('NotesPage Widget Tests - Form Interaction & Validation', () {
    testWidgets('Validasi Form: Menolak judul kosong/spasi dan menampilkan pesan error', (tester) async {
      // Arrange
      final fakeRepo = FakeNoteRepository(initialNotes: []);
      await tester.pumpWidget(buildTestableWidget(fakeRepo));
      await tester.pumpAndSettle();

      // Act: Buka dialog tambah catatan
      await tester.tap(find.byKey(const Key('add-note-fab')));
      await tester.pumpAndSettle();

      // Verifikasi dialog terbuka
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Tambah Catatan'), findsOneWidget);

      // Masukkan input tidak valid (hanya spasi)
      await tester.enterText(find.byKey(const Key('note-title-field')), '    ');
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      // Assert: Pesan validasi muncul dan dialog tetap terbuka
      expect(find.text('Judul tidak boleh kosong'), findsAtLeastNWidgets(1));
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(fakeRepo.currentNotes, isEmpty);

      // Coba masukkan judul terlalu pendek (< 3 karakter)
      await tester.enterText(find.byKey(const Key('note-title-field')), 'ab');
      await tester.tap(find.byKey(const Key('save-note-button')));
      await tester.pumpAndSettle();

      expect(find.text('Judul minimal 3 karakter'), findsAtLeastNWidgets(1));
      expect(fakeRepo.currentNotes, isEmpty);
    });

    testWidgets('Interaksi Dialog: Tombol Batal menutup dialog tanpa menyimpan catatan', (tester) async {
      // Arrange
      final fakeRepo = FakeNoteRepository(initialNotes: []);
      await tester.pumpWidget(buildTestableWidget(fakeRepo));
      await tester.pumpAndSettle();

      // Act: Buka dialog
      await tester.tap(find.byKey(const Key('add-note-fab')));
      await tester.pumpAndSettle();

      // Isi teks lalu klik batal
      await tester.enterText(find.byKey(const Key('note-title-field')), 'Rencana Batal');
      await tester.tap(find.byKey(const Key('cancel-note-button')));
      await tester.pumpAndSettle();

      // Assert: Dialog tertutup dan tidak ada catatan tersimpan
      expect(find.byType(AlertDialog), findsNothing);
      expect(fakeRepo.currentNotes, isEmpty);
      expect(find.text('Belum ada catatan.'), findsOneWidget);
    });

    testWidgets(
      'Happy Path: Pengguna mengisi judul dan isi valid, catatan tersimpan, dan muncul di daftar',
      (tester) async {
        // Arrange
        final fakeRepo = FakeNoteRepository(initialNotes: []);
        await tester.pumpWidget(buildTestableWidget(fakeRepo));
        await tester.pumpAndSettle();

        expect(find.text('Belum ada catatan.'), findsOneWidget);

        // Act: Buka dialog
        await tester.tap(find.byKey(const Key('add-note-fab')));
        await tester.pumpAndSettle();

        // Masukkan data valid
        await tester.enterText(
          find.byKey(const Key('note-title-field')),
          'Tugas Testing Minggu 12',
        );
        await tester.enterText(
          find.byKey(const Key('note-body-field')),
          'Pengujian Unit, Widget, dan Integrasi Flutter',
        );

        // Klik tombol Simpan
        await tester.tap(find.byKey(const Key('save-note-button')));
        await tester.pumpAndSettle();

        // Assert: Dialog tertutup, SnackBar sukses tampil, dan item baru ter-render di ListView
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Catatan berhasil ditambahkan'), findsOneWidget);
        expect(find.text('Tugas Testing Minggu 12'), findsOneWidget);
        expect(find.text('Pengujian Unit, Widget, dan Integrasi Flutter'), findsOneWidget);
        expect(find.text('Belum ada catatan.'), findsNothing);
        expect(fakeRepo.currentNotes.length, 1);
      },
    );
  });
}
