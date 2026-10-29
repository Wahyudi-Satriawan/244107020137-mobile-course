# Campus Notify (Feature-First Clean Architecture)

Aplikasi mobile pengumuman dan catatan kampus yang dibangun menggunakan arsitektur bersih berbasis fitur (*Feature-First Clean Architecture*), state management Riverpod, deklaratif routing GoRouter, penyimpanan lokal SQLite, dan push notification Firebase Cloud Messaging (FCM).

---

## 🏗️ Struktur Arsitektur

Struktur proyek menerapkan aturan dependensi Clean Architecture: `presentation -> domain <- data`.

```text
lib/
├── core/                         # Komponen global lintas fitur
│   ├── di/                       # Dependency Injection (Riverpod)
│   ├── network/                  # Network client abstraction (Dio)
│   ├── services/                 # Firebase Messaging Push Service
│   ├── storage/                  # TokenStore persistensi
│   ├── utils/                    # Route parser & helper
│   ├── widgets/                  # Reusable UI (LoadingView, ErrorView)
│   └── failures.dart             # Pure Dart Failure classes
├── features/
│   ├── announcements/            # Fitur Pengumuman Kampus
│   │   ├── domain/               # Entity Announcement
│   │   └── presentation/         # HomePage, AnnouncementPage, Widgets
│   ├── auth/                     # Fitur Autentikasi Pengguna
│   │   ├── data/                 # AuthRepositoryImpl
│   │   ├── domain/               # AuthSession entity, AuthRepository contract, LoginUseCase
│   │   └── presentation/         # LoginPage, AuthProviders
│   └── notes/                    # Fitur Catatan Kampus (Local SQLite)
│       ├── data/                 # NoteModel, NoteLocalDataSource, NoteRepositoryImpl
│       ├── domain/               # Note entity, NoteRepository contract, UseCases (GetNotes, AddNote, ValidateNote)
│       └── presentation/         # NotesPage, NotesProviders, NotesList
├── main.dart                     # Bootstrap & FCM listener initialization
└── routes.dart                   # GoRouter declarative navigation configuration
```

---

## 🛡️ Sterilitas Layer Domain

Layer `domain` pada setiap modul (termasuk `lib/features/notes/domain`) adalah **100% Pure Dart**:
- Tidak mengimpor `package:flutter`
- Tidak mengimpor `dio`
- Tidak mengimpor `sqflite`

Hal ini memastikan logika bisnis tidak bergantung pada detail framework UI atau database dan dapat diuji secara murni menggunakan fake/mock repository.

---

## 🧪 Bukti Mesin Hijau & Kualitas Kode

Proyek ini telah diverifikasi dengan seluruh pemeriksaan otomasi lokal:

1. **Static Analysis**:
   ```bash
   flutter analyze
   # Output: No issues found! (ran in 5.1s)
   ```
2. **Code Formatter**:
   ```bash
   dart format --output=none --set-exit-if-changed .
   # Output: Formatted 36 files (0 changed) in 0.19 seconds.
   ```
3. **Unit Testing Suite**:
   ```bash
   flutter test
   # Output: 00:00 +13: All tests passed!
   ```

### Bukti Screenshot:
- Hasil Test & Analyze: `screenshots/ci_analyze_test_passed.png`
- Tampilan Error UI Catatan: `screenshots/notes_validation_error_ui.png`

---

## 🚀 Cara Menjalankan

```bash
# 1. Unduh dependensi
flutter pub get

# 2. Jalankan analisis & test
flutter analyze
flutter test

# 3. Jalankan aplikasi
flutter run
```

---

## 📚 Dokumen Terkait Mid-Project Review
- [Review Checklist & Audit Git](docs/review-checklist.md)
- [Tinjauan AI Challenge vs Keputusan Rekayasa](docs/ai-review-vs-keputusan.md)
- [Dokumentasi PR & Refleksi](docs/pr-dan-peer-review.md)
