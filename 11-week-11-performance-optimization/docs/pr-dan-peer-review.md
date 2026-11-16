# Dokumentasi Pull Request, Peer Review, dan Refleksi (Praktikum 2)

---

## 1. Template Pull Request Lengkap

### Judul PR: `feat(notes): validasi judul kosong + test`

- **Branch Sumber**: `feat/notes-validation`
- **Branch Target**: `develop`
- **Issue Terkait**: `Closes #1`

### A. Masalah
Sebelum fitur ini diterapkan, modul catatan (`campus_notify`) mengizinkan pengguna untuk menyimpan catatan baru dengan field judul (*title*) yang kosong atau hanya berupa spasi. Hal ini menyebabkan database lokal SQLite terisi oleh catatan kosong tanpa identitas dan menyulitkan pemilahan pengumuman/catatan di UI dashboard.

### B. Solusi
1. **Domain Layer**:
   - Menambahkan class `ValidationFailure` turunan dari `Failure` di `lib/core/failures.dart`.
   - Membuat use case `ValidateNote` di `lib/features/notes/domain/usecases/validate_note.dart` untuk memvalidasi nilai null, string kosong (`trim().isEmpty`), dan batasan minimal 3 karakter.
   - Membuat use case `AddNote` di `lib/features/notes/domain/usecases/add_note.dart` yang memanggil `ValidateNote` sebelum memicu `NoteRepository.addNote()`.
2. **Presentation Layer**:
   - Menghubungkan provider `addNoteProvider` ke dialog *Tambah Catatan* pada `NotesPage`.
   - Menampilkan feedback visual kesalahan secara langsung pada properti `errorText` input TextField judul serta `SnackBar` peringatan merah jika validasi ditolak.
3. **Testing**:
   - Membuat unit test suite komprehensif pada `test/validate_note_test.dart` menguji seluruh variasi validasi.

### C. Cara Uji
1. **Pengujian Manual (UI)**:
   - Buka aplikasi `campus_notify` dan login.
   - Dari AppBar Dashboard Pengumuman, klik ikon catatan untuk membuka `NotesPage`.
   - Klik tombol FloatingActionButton (`+`) untuk memunculkan dialog *Tambah Catatan*.
   - Tekan tombol **Simpan** tanpa mengisi judul atau hanya mengisi spasi -> Label error merah *"Judul catatan tidak boleh kosong"* muncul seketika di bawah TextField.
   - Ketik 2 karakter (misal: "ab") lalu simpan -> Label error merah *"Judul minimal 3 karakter"* muncul.
   - Ketik judul yang valid (misal: "Catatan Kuliah Mobile") lalu simpan -> Dialog tertutup, catatan muncul di list, dan SnackBar hijau berhasil ditampilkan.
2. **Pengujian Otomatis (Mesin)**:
   - Jalankan unit test via terminal:
     ```bash
     flutter test test/validate_note_test.dart
     ```
   - Hasil: 7/7 test passed (100% Green).

### D. Bukti Screenshot
- Bukti Mesin Hijau: `../screenshots/ci_analyze_test_passed.png`
- Bukti Mockup Error UI: `../screenshots/notes_validation_error_ui.png`

---

## 2. Rekapitulasi Komentar Peer Review (Sesi 15 Menit)

Berikut adalah 5 temuan peer review yang menerapkan pola **Observasi -> Dampak -> Usulan Konkret**:

### Komentar 1 (Kebenaran - Edge Case Whitespace)
- **Observasi**: Pengecekan judul di awal hanya memakai `title.isEmpty`.
- **Dampak**: Jika pengguna menekan tombol spasi beberapa kali lalu menekan tombol simpan, sistem meloloskan catatan dengan judul kosong ke database lokal.
- **Usulan Konkret**: Gunakan `title.trim().isEmpty` pada use case `ValidateNote` agar string yang hanya berisi karakter spasi/tab dianggap tidak valid.
- **Tindak Lanjut**: Diterapkan pada `validate_note.dart` baris 7.

### Komentar 2 (Kebenaran - UI State Reset)
- **Observasi**: Pesan error merah di `NotesPage` dialog tetap bertahan meskipun pengguna sudah mulai mengetik karakter baru di TextField.
- **Dampak**: Pengguna merasa inputnya masih salah padahal sedang mengoreksi judul.
- **Usulan Konkret**: Pasang callback `onChanged: (_)` pada TextField untuk mereset `errorMessage = null` dan trigger `setState()`.
- **Tindak Lanjut**: Diterapkan pada `notes_page.dart` dalam event `onChanged`.

### Komentar 3 (Arsitektur - Boundary Sterility)
- **Observasi**: Adanya potensi kebocoran dependency jika error validasi dilempar sebagai exception generic atau menggunakan tipe data framework.
- **Dampak**: Layer domain tercemar atau presentation harus menangani exception untyped yang rentan *runtime crash*.
- **Usulan Konkret**: Buat tipe `ValidationFailure` spesifik di `core/failures.dart` murni Dart yang mengembalikan pesan failure secara deklaratif lewat record `(Note?, Failure?)`.
- **Tindak Lanjut**: Diterapkan pada `failures.dart` dan `add_note.dart`. Domain 100% murni Dart tanpa import eksternal.

### Komentar 4 (Testing - Repository Verification)
- **Observasi**: Pengujian kegagalan input di `validate_note_test.dart` awalnya hanya memeriksa output use case tanpa memeriksa status fake repository.
- **Dampak**: Tidak ada bukti otomatis bahwa proses penyimpanan database benar-benar dibatalkan saat validasi gagal.
- **Usulan Konkret**: Tambahkan assert `expect(repo.notes, isEmpty)` pada skenario gagal.
- **Tindak Lanjut**: Diterapkan pada baris 57 dan baris 65 di `test/validate_note_test.dart`.

### Komentar 5 (Keterbacaan - Pemisahan Tanggung Jawab Use Case)
- **Observasi**: Logika validasi dan logika penyimpanan awalnya disatukan dalam satu fungsi panjang.
- **Dampak**: Aturan validasi sulit di-reuse jika ada modul lain (misal form edit catatan) yang membutuhkan aturan serupa.
- **Usulan Konkret**: Pecah menjadi `ValidateNote` (khusus memvalidasi rule) dan `AddNote` (orkestrator use case yang menginjeksi validator).
- **Tindak Lanjut**: Dipecah menjadi dua use case terpisah di folder `features/notes/domain/usecases/`.

**Status Akhir Review Sejawat**: **APPROVED** (Seluruh 5 usulan telah diselesaikan dan diverifikasi mesin).

---

## 3. Jawaban Refleksi Minggu 8

### 1. Apa beda LGTM buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?
- **LGTM Buta**: Menyetujui pull request hanya dengan melihat sekilas judul atau deskripsi tanpa memeriksa diff kode, tidak memeriksa kepatuhan arsitektur, dan tidak memverifikasi apakah test sudah dijalankan.
- **Approve Bertanggung Jawab**: Memeriksa baris demi baris logika kode, memastikan tidak ada boundary leak (misal import UI di domain), memverifikasi penanganan error/edge-cases, serta memastikan mesin lokal/CI sudah berstatus hijau.
- **Risiko bagi Tim**: LGTM buta meloloskan *regression bugs*, utang teknis (*technical debt*), perusakan arsitektur yang berakibat aplikasi rapuh, serta menciptakan budaya tim yang abai pada kualitas kode.

### 2. Kapan komentar wajib berstatus `request changes`, dan kapan cukup `saran`?
- **Wajib `request changes`**: Ketika ditemukan *blocker* yang berakibat fatal:
  - Pelanggaran batas Clean Architecture (misal import Flutter/Dio/SQLite di layer domain).
  - Bug fungsional / *edge case* yang menyebabkan data korup atau aplikasi crash (misal lolosnya judul kosong tanpa validasi).
  - Ketiadaan unit test untuk logika bisnis baru atau rusaknya mesin CI/analyze.
- **Cukup `saran` (Nitpick/Non-blocking)**: Ketika kode sudah benar dan aman, namun ada alternatif penamaan variabel yang lebih ekspresif, saran optimasi kecil yang tidak mendesak, atau dokumentasi tambahan yang dapat dikerjakan pada iterasi berikutnya tanpa menghambat deployment.

### 3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?
- **Yang Ditolak**:
  1. Saran AI untuk mengimpor `package:flutter/material.dart` dan menyuntikkan `TextEditingController` ke dalam use case domain `add_note.dart`. Saran ini ditolak mentah-mentah karena **melanggar prinsip dasar Clean Architecture**. Domain harus 100% murni Dart dan agnostik terhadap UI framework.
  2. Saran AI yang mendebatkan formatting indentasi dan koma trailing secara manual. Saran ini ditolak karena format kode sudah diserahkan sepenuhnya ke mesin otomatis (`dart format`).
- **Alasan**: Menerima saran AI tanpa filter arsitektur akan merusak pemisahan tanggung jawab layer dan mempersulit pengujian unit test.

### 4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?
- **Hal Konkret**: Menambahkan assertion `expect(repo.notes, isEmpty)` pada unit test `AddNote` untuk kasus judul whitespace.
- **Dampaknya**: Memberikan jaminan 100% bahwa logika use case bertindak sebagai pagar kokoh yang memutus alur eksekusi (*short-circuit*) sebelum proses I/O database dijalankan. Jika di masa depan ada pengembang lain yang tidak sengaja memindahkan pemanggilan validasi ke setelah insert database, unit test akan langsung gagal dan menangkap *bug* tersebut secara instan.
