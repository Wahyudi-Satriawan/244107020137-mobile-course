# Review Checklist & Audit Kesiapan Tengah Semester

Dokumen ini memuat audit git, pengujian batas arsitektur (*Clean Architecture*), bukti verifikasi mesin (*CI / Static Analysis*), serta *checklist* kesiapan kode untuk evaluasi tengah semester (*Mid-Project Review*).

---

## 1. Audit Git & Tabel Perbaikan Commit (Praktikum 1)

### Log Riwayat Git Asli (20 Commit Terakhir)
```text
59842ed feat(validation): cegah simpan input kosong + unit test
48b766e week 9
675e833 week 7
beb36fa refactor: perbaiki batas Clean Architecture dan DI untuk modul Auth
11711d1 modul 7
14b0220 chore: snapshot before clean architecture
9370413 Persiapan Modul 7
c3cd0c2 Delete Kuis 1 directory
92d371e Merge branch 'main' of https://github.com/Wahyudi-Satriawan/244107020137-mobile-course
21adc6f Penyelesaian Praktikum 6
677f6eb Kuis
a649d49 JS 5
d695707 Js 4
152422f Praktikum 1-2
b0f5e82 setup sebelum praktikum (flutter pub add dio flutter_riverpod)
525c513 AI Chalange, Refactoring, Testing dan refleksi
d8fa600 Menyelesaikan Praktikum 1,2,3
c60fba2 flutter create week3_navigation & week3_todo
3d25fb5 Menyelesaikan Praktikum week 02
a3db3d7 flutter create responsive_dashboard
14883cc Menyelesaikan aplikasi profil, week 1 beserta refleksi dan screenshot
```

### Tabel Perbaikan Commit (Sebelum vs Sesudah Conventional Commits)

| Hash Commit | Pesan Awal (Sebelum) | Revisi Conventional Commit (Sesudah) | Alasan Teknis & Standar Disiplin |
| :--- | :--- | :--- | :--- |
| `beb36fa` | `refactor: perbaiki batas Clean Architecture dan DI untuk modul Auth` | `refactor(auth): pisahkan abstraksi interface dan batasi di use case login` | Penamaan scope `(auth)` lebih spesifik. Memperjelas bahwa perubahan kode memisahkan abstraction contract `AuthRepository` dari implementasinya dan membungkus logic auth ke `LoginUseCase`. |
| `675e833` | `week 7` | `chore(week-7): integrasi push notification fcm dan konfigurasi rute` | Pesan `week 7` tidak informatif dan ambigu di riwayat git tim. Revisi menjelaskan bahwa commit berfokus pada setup service `PushService`, routing GoRouter, dan konfigurasi Gradle. |
| `48b766e` | `week 9` | `feat(notes): implementasi pencarian catatan realtime dan empty state view` | Pesan `week 9` tidak mencerminkan fungsionalitas. Revisi mengikuti format `feat(scope)` yang mendeskripsikan penambahan use case pencarian judul catatan beserta UI empty state. |

---

## 2. Bukti Sterilitas Arsitektur (Grep Minggu 7)

Layer `domain` pada Feature-First Clean Architecture (`lib/features/notes/domain`) dirancang **100% murni Dart**, steril tanpa ketergantungan pada SDK Flutter UI, HTTP client (Dio), maupun SQLite storage engine (Sqflite).

### Perintah dan Output Terminal:

```powershell
PS E:\AKULIAH\Semester 5\Pemrograman Mobile\244107020137-mobile-course\07-week-7-clean-architecture\campus_notify>
# 1. Verifikasi bebas dari ketergantungan UI Flutter
Get-ChildItem -Recurse lib/features/notes/domain/*.dart | Select-String "package:flutter"

# 2. Verifikasi bebas dari ketergantungan network Dio
Get-ChildItem -Recurse lib/features/notes/domain/*.dart | Select-String "dio"

# 3. Verifikasi bebas dari database engine SQLite
Get-ChildItem -Recurse lib/features/notes/domain/*.dart | Select-String "sqflite"
```

**Hasil Pemeriksaan:**
```text
=== 1. Grep package:flutter pada layer domain ===
(0 baris ditemukan - Steril)

=== 2. Grep dio pada layer domain ===
(0 baris ditemukan - Steril)

=== 3. Grep sqflite pada layer domain ===
(0 baris ditemukan - Steril)
Pemeriksaan sterilitas domain selesai (0 temuan).
```

---

## 3. Bukti Mesin Hijau (Praktikum 3)

Sebelum kode di-merge ke branch `develop`, seluruh mesin otomasi validasi lokal dijalankan dengan hasil **100% Hijau**:

### A. Static Analysis (`flutter analyze`)
```text
Analyzing campus_notify...                                      
No issues found! (ran in 5.1s)
```

### B. Otomasi Formatter (`dart format`)
```text
PS E:\AKULIAH\Semester 5\Pemrograman Mobile\244107020137-mobile-course\07-week-7-clean-architecture\campus_notify> dart format --output=none --set-exit-if-changed .
Formatted 36 files (0 changed) in 0.19 seconds.
```
*(Status: Exit Code 0, seluruh file kode telah diformat secara standar)*

### C. Unit Testing Suite (`flutter test`)
```text
00:00 +0: loading test/auth_push_test.dart
00:00 +0: test/auth_push_test.dart: Testing Route Parser FCM Payload Route parser menangani route kosong atau null tanpa crash
00:00 +1: test/auth_push_test.dart: Testing Route Parser FCM Payload Route parser memformat string route dengan benar
00:00 +2: test/auth_push_test.dart: Testing Logika Sesi Token Store Status sesi dianggap aktif jika access token tersimpan
00:00 +3: test/auth_push_test.dart: Testing Logika Sesi Token Store Wajib login ulang jika refresh token kosong
00:00 +4: test/get_notes_test.dart: GetNotes meneruskan daftar dari repository
00:00 +5: test/get_notes_test.dart: GetNotes meneruskan failure tanpa melempar
00:00 +6: test/validate_note_test.dart: ValidateNote Domain Logic Skenario gagal: judul null atau kosong mengembalikan ValidationFailure
00:00 +7: test/validate_note_test.dart: ValidateNote Domain Logic Skenario gagal: judul hanya berisi spasi/whitespace mengembalikan ValidationFailure
00:00 +8: test/validate_note_test.dart: ValidateNote Domain Logic Skenario gagal: judul kurang dari 3 karakter mengembalikan ValidationFailure
00:00 +9: test/validate_note_test.dart: ValidateNote Domain Logic Skenario sukses: judul valid lolos validasi (mengembalikan null)
00:00 +10: test/validate_note_test.dart: AddNote UseCase Integration dengan Validasi Skenario gagal: judul kosong ditolak sebelum masuk repository
00:00 +11: test/validate_note_test.dart: AddNote UseCase Integration dengan Validasi Skenario gagal: judul kurang dari 3 karakter ditolak
00:00 +12: test/validate_note_test.dart: AddNote UseCase Integration dengan Validasi Skenario sukses: judul valid berhasil disimpan ke repository
00:00 +13: All tests passed!
```

---

## 4. Checklist Kesiapan Tengah Semester

| Butir Evaluasi | Status | Bukti Singkat |
| :--- | :---: | :--- |
| **Branching Git Flow** | `[x]` | Branch `develop` aktif, branch fitur `feat/notes-validation` dibuat dari `develop`. |
| **PR Kecil & Terfokus** | `[x]` | PR hanya mencakup fitur validasi judul catatan & unit test (< 300 baris diff fungsional). |
| **Commit Conventional** | `[x]` | Pesan commit berformat `feat(validation): cegah simpan input kosong + unit test`. |
| **Sterilitas Layer Domain** | `[x]` | Layer domain murni Dart, 3 grep menghasilkan 0 temuan. |
| **Static Analysis Bersih** | `[x]` | `flutter analyze` menghasilkan 0 error, 0 warning, 0 info (*No issues found!*). |
| **Format Standar** | `[x]` | `dart format --set-exit-if-changed .` lolos dengan status clean. |
| **Unit Test Lengkap** | `[x]` | 13 test lulus mencakup skenario sukses, skenario gagal (empty & whitespace), dan boundary check. |
| **Pesan Error di Presentation** | `[x]` | Pesan kegagalan dari domain (`ValidationFailure`) tersambung ke `errorText` TextField & SnackBar di UI. |
| **Otomasi CI Workflow** | `[x]` | File `.github/workflows/ci.yml` terkonfigurasi untuk memvalidasi pull request. |
| **Dokumentasi & Refleksi** | `[x]` | Tersedia checklist review, catatan review AI vs keputusan, dan refleksi mid-term. |
