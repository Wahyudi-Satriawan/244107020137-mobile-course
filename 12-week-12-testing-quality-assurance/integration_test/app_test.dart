import 'package:campus_notify/core/di/injection.dart';
import 'package:campus_notify/core/services/push_service.dart';
import 'package:campus_notify/features/auth/domain/entities/auth_session.dart';
import 'package:campus_notify/features/auth/domain/repositories/auth_repository.dart';
import 'package:campus_notify/features/notes/presentation/pages/notes_page.dart';
import 'package:campus_notify/features/notes/presentation/providers/notes_providers.dart';
import 'package:campus_notify/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/fake_note_repository.dart';

/// Fake Auth Repository agar pengujian integrasi deterministik tanpa backend jaringan
class FakeAuthRepository implements AuthRepository {
  bool _loggedIn = true;

  @override
  Future<bool> isLoggedIn() async => _loggedIn;

  @override
  Future<AuthSession> login({required String email, required String password}) async {
    _loggedIn = true;
    return const AuthSession(access: 'mock_access_token', refresh: 'mock_refresh_token');
  }

  @override
  Future<String> refresh(String refreshToken) async => 'mock_new_access_token';

  @override
  Future<void> logout() async {
    _loggedIn = false;
  }
}

/// Fake Push Service agar tidak mencoba memanggil Firebase Cloud Messaging native di test runner
class FakePushService extends PushService {
  @override
  Future<bool> requestNotificationPermission() async => true;
  @override
  Future<void> initLocalNotifications() async {}
  @override
  void initPushListeners() {}
  @override
  Future<void> initFcmToken({required void Function(String token) onToken}) async {
    onToken('mock_fcm_token_1234567890');
  }
  @override
  Future<void> handleInitialMessage() async {}
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Campus Notify Integration Tests - Alur Fitur Catatan', () {
    testWidgets(
      'Alur Utama: Navigasi Dashboard -> Buka Halaman Catatan -> Validasi Gagal -> Tambah Catatan Sukses',
      (tester) async {
        // Arrange
        final fakeNotesRepo = FakeNoteRepository(initialNotes: []);
        final fakeAuthRepo = FakeAuthRepository();
        final fakePushService = FakePushService();

        // Bangun root app dengan ProviderScope yang di-override
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              noteRepositoryProvider.overrideWithValue(fakeNotesRepo),
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              pushServiceProvider.overrideWithValue(fakePushService),
            ],
            child: const CampusNotifyApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi berada di Dashboard (HomePage)
        expect(find.text('Dashboard Pengumuman'), findsOneWidget);

        // 2. Navigasi ke halaman Catatan via tombol AppBar
        final notesNavButton = find.byTooltip('Catatan');
        expect(notesNavButton, findsOneWidget);
        await tester.tap(notesNavButton);
        await tester.pumpAndSettle();

        // 3. Verifikasi halaman Catatan Kampus berhasil dibuka dan menampilkan state kosong
        expect(find.text('Catatan Kampus'), findsOneWidget);
        expect(find.text('Belum ada catatan.'), findsOneWidget);

        // 4. Buka Dialog Tambah Catatan
        final addNoteFab = find.byKey(const Key('add-note-fab'));
        expect(addNoteFab, findsOneWidget);
        await tester.tap(addNoteFab);
        await tester.pumpAndSettle();

        // 5. Uji Kasus Tepi / Validasi Gagal: Isi judul hanya spasi
        final titleField = find.byKey(const Key('note-title-field'));
        final saveButton = find.byKey(const Key('save-note-button'));
        expect(titleField, findsOneWidget);
        expect(saveButton, findsOneWidget);

        await tester.enterText(titleField, '    ');
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Assert: Validasi mencegah penyimpanan dan dialog tetap terbuka
        expect(find.text('Judul tidak boleh kosong'), findsAtLeastNWidgets(1));
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(fakeNotesRepo.currentNotes, isEmpty);

        // 6. Masukkan data valid
        await tester.enterText(titleField, 'Catatan Integrasi End-to-End');
        final bodyField = find.byKey(const Key('note-body-field'));
        await tester.enterText(bodyField, 'Dibuat dan diverifikasi melalui Flutter Integration Test');

        // Klik Simpan
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // 7. Assert: Dialog tertutup, SnackBar muncul, dan item tampil di daftar
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Catatan berhasil ditambahkan'), findsOneWidget);
        expect(find.text('Catatan Integrasi End-to-End'), findsOneWidget);
        expect(find.text('Dibuat dan diverifikasi melalui Flutter Integration Test'), findsOneWidget);
        expect(find.text('Belum ada catatan.'), findsNothing);
        expect(fakeNotesRepo.currentNotes.length, 1);
      },
    );

    testWidgets(
      'Alur Langsung Halaman Catatan: Menambahkan catatan berurutan dan verifikasi persistensi state',
      (tester) async {
        // Arrange
        final fakeNotesRepo = FakeNoteRepository(initialNotes: []);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              noteRepositoryProvider.overrideWithValue(fakeNotesRepo),
            ],
            child: const MaterialApp(
              home: NotesPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Belum ada catatan.'), findsOneWidget);

        // Tambah Catatan Pertama
        await tester.tap(find.byKey(const Key('add-note-fab')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('note-title-field')), 'Catatan Praktikum 1');
        await tester.enterText(find.byKey(const Key('note-body-field')), 'Isi catatan pertama');
        await tester.tap(find.byKey(const Key('save-note-button')));
        await tester.pumpAndSettle();

        // Tambah Catatan Kedua
        await tester.tap(find.byKey(const Key('add-note-fab')));
        await tester.pumpAndSettle();

        await tester.enterText(find.byKey(const Key('note-title-field')), 'Catatan Praktikum 2');
        await tester.enterText(find.byKey(const Key('note-body-field')), 'Isi catatan kedua');
        await tester.tap(find.byKey(const Key('save-note-button')));
        await tester.pumpAndSettle();

        // Assert: Kedua catatan tampil pada daftar
        expect(find.text('Catatan Praktikum 1'), findsOneWidget);
        expect(find.text('Catatan Praktikum 2'), findsOneWidget);
        expect(fakeNotesRepo.currentNotes.length, 2);
      },
    );
  });
}
