# Laporan Praktikum Minggu 08: Mid-Project Review & Code Review
### Portofolio Aplikasi: Campus Notify

---

## 👤 Identitas Mahasiswa

| Informasi | Keterangan |
| :--- | :--- |
| **Nama Mahasiswa** | Wahyudi Satriawan Hamid |
| **NIM** | 244107020137 |
| **Mata Kuliah** | Pemrograman Mobile |
| **Semester / Kelas** | 5 |
| **Modul** | Codelab Minggu 08 - Mid-Project Review & Code Review |
| **Repository** | [244107020137-mobile-course](https://github.com/Wahyudi-Satriawan/244107020137-mobile-course) |
| **Branch Utama** | `main` |
| **Branch Kolaborasi** | `develop` & `feat/notes-validation` |

---

## 📌 1. Status Paruh Semester (Mid-Project Overview)

Proyek **Campus Notify** merupakan aplikasi mobile kampus berbasis arsitektur bersih (*Feature-First Clean Architecture*) yang menggabungkan berbagai kapabilitas inti:
- **Presentation Layer**: Dibangun menggunakan UI deklaratif Flutter dengan Riverpod sebagai State Management dan GoRouter untuk navigasi berorientasi URL/rute.
- **Domain Layer**: Mengisolasi logika bisnis dan use case ke dalam kode murni Dart (*Pure Dart*), 100% bebas dari framework UI, database SQLite, maupun HTTP network client.
- **Data Layer**: Mengelola persistensi data menggunakan SQLite lokal (`sqflite`), sinkronisasi token FCM, serta API client wrapper berbasis Dio.

Pada evaluasi tengah semester (Minggu 8) ini, fokus ditekankan pada penguatan disiplin kolaborasi industri (*Git Flow*), pemecahan issue menjadi PR kecil terisolasi (< 300 baris diff), penambahan fitur validasi judul catatan, pembuatan unit test komprehensif, otomasi verifikasi CI melalui GitHub Actions, serta evaluasi kode kritis melalui *Peer Review* dan *AI Code Review*.

---

## 🎯 2. Ringkasan Pelaksanaan Praktikum 1 s/d 3

### Praktikum 1: Hygiene Branch & Git Flow
- Melakukan audit riwayat git (`git log --oneline -20`, `git branch -a`, dan `git status`).
- Menginisialisasi cabang kolaborasi utama `develop` dari `main`.
- Membuat branch fitur terisolasi `feat/notes-validation` untuk mengerjakan penambahan use case validasi input catatan.
- Mengidentifikasi commit riwayat lama yang belum memenuhi standar dan menulis ulang menjadi format *Conventional Commits* pada dokumen audit.

### Praktikum 2: Implementasi Fitur Validasi, Peer Review, & PR Workflow
- Menganalisis struktur Clean Architecture modul Notes (`presentation -> domain <- data`).
- Membuat use case validasi `ValidateNote` dan `AddNote` pada layer `domain` murni Dart dengan pengecekan judul tidak boleh null, kosong, whitespace-only, atau kurang dari 3 karakter.
- Menyambungkan pesan kegagalan (`ValidationFailure`) ke form dialog pada `NotesPage` (layer `presentation`) melalui properti `errorText` TextField dan notifikasi SnackBar.
- Menyusun unit test lengkap pada `test/validate_note_test.dart` menguji skenario gagal dan sukses.
- Mensimulasikan tinjauan kode sejawat (*Peer Review* 15 menit) dengan 5 temuan berformat **Observasi $\to$ Dampak $\to$ Usulan Konkret**.

### Praktikum 3: Mesin Hijau & CI GitHub Actions
- Mengonfigurasi alur kerja otomasi pada `.github/workflows/ci.yml`.
- Menjalankan standarisasi format otomatis dengan `dart format .`.
- Memastikan analisis statis bersih dengan `flutter analyze` (**0 issues found**).
- Memastikan seluruh unit test lulus dengan `flutter test` (**13/13 tests passed**).
- Mengintegrasikan hasil kerja ke branch `develop` dan `main`.

---

## 🗺️ 3. Peta Issue & Pull Request

| No | Tipe | ID / Branch | Judul / Deskripsi | Target Branch | Status |
| :-: | :---: | :--- | :--- | :---: | :---: |
| 1 | **Issue** | `#1` | `[Bug]: Pengguna dapat menyimpan catatan tanpa judul` | - | **Closed via PR** |
| 2 | **PR** | `feat/notes-validation` | `feat(notes): validasi judul kosong + test` | `develop` | **Merged & Closed** |

### Detail Pull Request
- **Judul**: `feat(notes): validasi judul kosong + test`
- **Masalah**: Pengguna dapat menyimpan catatan tanpa judul atau hanya spasi, menyebabkan database SQLite terisi catatan sampah tanpa identitas.
- **Solusi**: Validasi bisnis diletakkan pada domain use case (`ValidateNote` & `AddNote`) dan pesan kegagalan disambungkan ke antarmuka dialog (`NotesPage`).
- **Cara Uji**:
  1. *Manual UI*: Buka form tambah catatan $\to$ simpan kosong $\to$ error merah muncul.
  2. *Automated Test*: `flutter test test/validate_note_test.dart` $\to$ 7/7 test passed.
- **Referensi**: `Closes #1`

---

## 🚀 4. Fitur Utama & Stack Teknologi

### Fitur Utama Aplikasi:
1. **Autentikasi & Manajemen Sesi**: Login mahasiswa/dosen dengan penyimpanan token aman dan verifikasi sesi token store.
2. **Dashboard Pengumuman Kampus**: Daftar pengumuman dinamis terintegrasi dengan Firebase Cloud Messaging (FCM).
3. **Penyimpanan Catatan Offline (Local SQLite)**: Fitur catatan lokal dengan SQLite DataSource terenkapsulasi.
4. **Validasi Input Bisnis Catatan (Fitur Minggu 8)**: Validasi judul tidak boleh kosong, bukan spasi, dan minimal 3 karakter dengan feedback instan di antarmuka pengguna.

### Stack Teknologi:
- **Framework**: Flutter 3.x (Material 3) / Dart SDK ^3.6.0
- **Arsitektur**: Feature-First Clean Architecture (`presentation -> domain <- data`)
- **State Management**: `flutter_riverpod` (`Provider`, `FutureProvider`, `Notifier`)
- **Routing**: `go_router` (URL-based routing & persistent route listener)
- **Networking**: `dio` (Clean client wrapper dengan translation error)
- **Local Database**: `sqflite` & `path`
- **Testing**: `flutter_test` (Unit testing use cases, fake repositories, dan boundary check)
- **CI / Automation**: GitHub Actions (`.github/workflows/ci.yml`), `dart format`, `flutter analyze`

---

## 🛡️ 5. Bukti Sterilitas Layer Domain

Pemeriksaan sterilitas membuktikan layer `lib/features/notes/domain` **100% murni Dart**:
```powershell
# 1. Verifikasi bebas dari UI Flutter
Get-ChildItem -Recurse lib/features/notes/domain/*.dart | Select-String "package:flutter"
# Hasil: 0 temuan

# 2. Verifikasi bebas dari network Dio
Get-ChildItem -Recurse lib/features/notes/domain/*.dart | Select-String "dio"
# Hasil: 0 temuan

# 3. Verifikasi bebas dari database engine SQLite
Get-ChildItem -Recurse lib/features/notes/domain/*.dart | Select-String "sqflite"
# Hasil: 0 temuan
```

---

## 🧪 6. Bukti Mesin Hijau (Green Checks)

### A. Static Analysis (`flutter analyze`)
```text
Analyzing campus_notify...                                      
No issues found! (ran in 5.1s)
```

### B. Otomasi Formatter (`dart format`)
```text
Formatted 36 files (0 changed) in 0.19 seconds.
```

### C. Unit Testing Suite (`flutter test` — 13 Tests Passed)
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

## 📸 7. Bukti Visual (Screenshots)

### Bukti Mesin Hijau Terminal (Analyze, Format, Test 13 Passed)
![Bukti Mesin Hijau Terminal](screenshots/ci_analyze_test_passed.png)

### Bukti Mockup Antarmuka Validasi Error UI (Notes Page)
![Tampilan Validasi Error UI](screenshots/notes_validation_error_ui.png)

---

## 🧠 8. Jawaban Refleksi Minggu 8

### 1. Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?
- **LGTM Buta (*Looks Good To Me*)**: Menyetujui pull request secara dangkal hanya berdasarkan judul atau ringkasan tanpa memeriksa logika baris kode, tanpa mengecek pelanggaran batas Clean Architecture, dan tanpa memastikan hasil pengujian unit test.
- **Approve Bertanggung Jawab**: Meninjau setiap baris perubahan kode secara kritis, memastikan tidak ada ketergantungan yang bocor (*boundary leak*), memvalidasi penanganan kasus batas (*edge-case*), serta memastikan seluruh mesin CI lokal maupun remote berstatus hijau.
- **Risiko bagi Tim**: LGTM buta membuka celah masuknya *regression bugs*, utang teknis (*technical debt*), perusakan modularitas arsitektur, dan penurunan kualitas perangkat lunak saat aplikasi semakin berskala besar.

### 2. Kapan komentar wajib berstatus `request changes`, dan kapan cukup `saran`?
- **Wajib `request changes`**: Diberikan ketika ditemukan kesalahan fatal (*blocker*), seperti pelanggaran batas arsitektur (misal layer domain mengimpor UI Flutter atau database SQLite), bug yang merusak data atau menyebabkan *runtime exception*, serta ketiadaan unit test untuk logika bisnis baru.
- **Cukup `saran` (Non-blocking)**: Diberikan untuk perbaikan kosmetik ringan yang tidak mengubah fungsionalitas, usulan penamaan identifier yang lebih idiomatis, atau dokumentasi tambahan yang dapat diterapkan pada iterasi berikutnya tanpa menahan proses rilis.

### 3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?
- **Saran AI yang Ditolak**:
  1. AI menyarankan untuk mengimpor `package:flutter/material.dart` dan memasukkan `TextEditingController` ke use case `AddNote` pada layer domain. Saran ini **ditolak mentah-mentah** karena melanggar prinsip *Clean Architecture*: layer domain wajib murni Dart agar dapat diuji secara independen tanpa dependensi widget tree.
  2. AI mendebatkan spasi indentasi dan koma trailing secara manual. Saran ini **ditolak** karena formatting visual sudah ditangani otomatis oleh `dart format`.
- **Alasan**: Saran AI wajib disaring secara kritis menggunakan prinsip arsitektur agar tidak merusak keterpisahan layer sistem.

### 4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?
- **Hal Konkret**: Menambahkan assertion `expect(repo.notes, isEmpty)` pada pengujian kegagalan input di `test/validate_note_test.dart`.
- **Dampak Nyata**: Memberikan kepastian otomatis bahwa use case `AddNote` benar-benar menghentikan proses (*short-circuit*) sebelum proses I/O penyimpanan database lokal dipanggil, mencegah kebocoran data jika ada perubahan implementasi di masa mendatang.

---

## 🛠️ 9. Cara Menjalankan Proyek & Pengujian

### Prasyarat
- Flutter SDK (>= 3.27.0)
- Dart SDK (>= 3.6.0)

### Langkah Operasional:
```bash
# 1. Pindah ke direktori proyek Clean Architecture
cd "07-week-7-clean-architecture/campus_notify"

# 2. Unduh seluruh dependensi paket
flutter pub get

# 3. Jalankan pemformatan kode dan analisis statis
dart format --output=none --set-exit-if-changed .
flutter analyze

# 4. Jalankan seluruh pengujian unit test
flutter test

# 5. Jalankan aplikasi pada emulator atau perangkat fisik
flutter run
```

---

## 📂 10. Indeks Dokumen Terkait

Dokumentasi detail pelengkap dapat diakses langsung pada tautan berikut:
1. 📄 [Checklist Kesiapan & Audit Git (`docs/review-checklist.md`)](docs/review-checklist.md) — Memuat data git log asli, tabel pemulihan commit Conventional Commits, bukti 3 grep sterilitas domain, dan checklist evaluasi.
2. 🤖 [Tinjauan AI Challenge vs Keputusan Rekayasa (`docs/ai-review-vs-keputusan.md`)](docs/ai-review-vs-keputusan.md) — Memuat prompt AI senior Flutter dev, temuan AI, serta tabel penerimaan dan penolakan saran arsitektural.
3. 👥 [Dokumentasi PR & Peer Review (`docs/pr-dan-peer-review.md`)](docs/pr-dan-peer-review.md) — Memuat template PR lengkap, 5 catatan review sejawat berbasis Observasi-Dampak-Usulan, dan refleksi mendalam.
