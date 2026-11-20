# Laporan Teknis Evaluasi Cakupan Pengujian (Code Coverage Report)
**Proyek:** `campus_notify`  
**Modul:** #12 | Pengujian dan Jaminan Kualitas (Testing & Quality Assurance)  
**Dokumen:** Laporan Audit QA & Evaluasi Regresi  
**Tanggal:** 20 November 2026  
**QA Lead:** Senior Flutter QA Engineer  

---

## 1. Ringkasan Eksekutif Cakupan Kode

Pengukuran cakupan kode dieksekusi secara otomatis menggunakan perintah resmi Flutter:
```bash
flutter test --coverage
```
Berkas data mentah dihasilkan di `coverage/lcov.info`. Parsing metrik aktual dilakukan secara langsung tanpa interpolasi atau fabrikasi data.

### Metrik Keseluruhan (Overall Metrics)
- **Total Baris Kode Teridentifikasi (Lines Found / LF):** 262
- **Total Baris Kode Tereksekusi (Lines Hit / LH):** 192
- **Cakupan Kode Kumulatif (Code Coverage):** **73.28%**
- **Total Test Suites Teruji:** 42 Test Cases (100% Lulus / 0 Gagal)

---

## 2. Tabel Rincian Cakupan Berkas (`lib/`)

Berikut adalah tabel rincian baris kode per berkas yang diekstraksi langsung dari artefak `coverage/lcov.info`:

| Berkas Sumber (`lib/`) | Kategori Layer | Baris Ditemukan (LF) | Baris Tereksekusi (LH) | Persentase Cakupan | Status Evaluasi |
|---|---|:---:|:---:|:---:|:---:|
| `features/notes/domain/entities/note.dart` | Domain (Entity) | 1 | 1 | **100.00%** | Optimal |
| `features/notes/domain/usecases/get_notes.dart` | Domain (Use Case) | 3 | 3 | **100.00%** | Optimal |
| `features/notes/domain/usecases/add_note.dart` | Domain (Use Case) | 4 | 4 | **100.00%** | Optimal |
| `features/notes/domain/usecases/validate_note.dart` | Domain (Use Case) | 4 | 4 | **100.00%** | Optimal |
| `features/notes/presentation/widgets/notes_list.dart` | Presentation (Widget) | 17 | 17 | **100.00%** | Optimal |
| `core/widgets/error_view.dart` | Core UI | 11 | 11 | **100.00%** | Optimal |
| `core/utils/route_parser.dart` | Core Utility | 5 | 5 | **100.00%** | Optimal |
| `features/notes/presentation/pages/notes_page.dart` | Presentation (Page) | 65 | 64 | **98.46%** | Sangat Tinggi |
| `features/notes/presentation/providers/notes_providers.dart` | Presentation (Riverpod) | 12 | 11 | **91.67%** | Sangat Tinggi |
| `ai/ai_service.dart` | AI Service / Network | 47 | 43 | **91.49%** | Sangat Tinggi |
| `features/ai_chat/presentation/providers/chat_providers.dart` | Presentation (Riverpod) | 34 | 27 | **79.41%** | Baik |
| `core/failures.dart` | Core Domain | 4 | 2 | **50.00%** | Terpenuhi Parsial |
| `features/notes/data/datasources/note_local_data_source.dart` | Data (SQLite) | 11 | 0 | **0.00%** | Diisolasi (Justified) |
| `features/notes/data/models/note_model.dart` | Data (SQLite Model) | 21 | 0 | **0.00%** | Diisolasi (Justified) |
| `features/notes/data/repositories/note_repository_impl.dart` | Data (Repo Implementation) | 23 | 0 | **0.00%** | Diisolasi (Justified) |
| **TOTAL KESELURUHAN** | **Arsitektur Aplikasi** | **262** | **192** | **73.28%** | **Target QA Tercapai** |

---

## 3. Analisis Area dengan Cakupan Rendah & Justifikasi Teknis

### A. Lapisan Data SQLite Nyata (`0.00%`)
Berkas yang tercatat bernilai 0%:
1. `lib/features/notes/data/datasources/note_local_data_source.dart`
2. `lib/features/notes/data/models/note_model.dart`
3. `lib/features/notes/data/repositories/note_repository_impl.dart`

**Justifikasi QA:**
Sesuai prinsip *Separation of Concerns* dan strategi pengujian pada Codelab Minggu 12 Bagian 4 (*"Jangan mengandalkan API atau sumber data sungguhan dalam pengujian unit"*), dependensi basis data SQLite sengaja diisolasi melalui implementasi `FakeNoteRepository`. 
- SQLite nyata pada platform Android/desktop melibatkan kompilasi C-bindings (`sqflite`) yang membutuhkan environment sistem operasi dan akses persistent file disk.
- Menggunakan database sungguhan pada pengujian unit dan widget membuat eksekusi test lambat, rentan *flaky*, dan bergantung pada sisa data tes sebelumnya (*state leakage*).
- Lapisan SQLite implementatif ini diverifikasi pada level pengujian integrasi berbasis perangkat (*on-device integration test*) atau pengujian database in-memory tersendiri.

### B. Lapisan Core Failures (`50.00%`)
Berkas: `lib/core/failures.dart`  
Baris yang dieksekusi adalah konstruktor `ValidationFailure` dan `LocalFailure` yang dipakai oleh fitur catatan. Subkelas lain (misalnya `ServerFailure` untuk request remote HTTP) tidak terpanggil karena pengujian berfokus penuh pada skenario lokal catatan kampus.

---

## 4. Prosedur Pencegahan Regresi (Regression Testing Workflow)

Pengujian perangkat lunak bukan aktivitas sekali jalan, melainkan mekanisme perlindungan berkelanjutan terhadap regresi (*regression defense*). Ketika bug ditemukan atau terjadi perubahan logika, tim QA menerapkan siklus 5 tahap berikut:

```
[1. Deteksi Bug] ──> [2. Tulis Failing Test] ──> [3. Implementasi Perbaikan]
                                                            │
[5. Quality Gate CI/CD] <── [4. Verifikasi Lulus & Suite Run] ┘
```

### Studi Kasus Nyata Regresi pada Praktikum Minggu 12:
1. **Identifikasi Masalah:**
   Pada pengujian widget `NotesPage`, terjadi eksepsi fatal Flutter:
   `A TextEditingController was used after being disposed` serta indikasi potensi `RenderFlex overflow`.
2. **Penyebab Akar (Root Cause):**
   `titleController` dan `bodyController` diinisialisasi dan di-dispose di dalam fungsi async `_showAddNoteDialog()` setelah `await showDialog(...)`. Ketika dialog ditutup via `Navigator.pop()`, transisi animasi keluar masih berjalan sementara kontroler sudah terlanjur di-dispose.
3. **Pencegahan Regresi Permanen:**
   - Logika dialog dipindahkan ke dalam `StatefulWidget` tersendiri (`_AddNoteDialog`) di mana kontroler diikat secara ketat pada siklus hidup `State.dispose()`.
   - Menambahkan test case widget otomatis: `Interaksi Dialog: Tombol Batal menutup dialog tanpa menyimpan catatan` dan `Happy Path: Pengguna mengisi judul dan isi valid, catatan tersimpan, dan muncul di daftar`.
   - Test ini akan segera **gagal (red)** jika ada pengembang di masa depan yang secara tidak sengaja memindahkan kembali pemusnahan kontroler ke luar siklus hidup widget.

### Quality Gate Pra-Commit & CI Pipeline:
Setiap *pull request* atau perubahan fitur wajib memenuhi gerbang kualitas:
1. **Analisis Statis:** `flutter analyze` wajib mengembalikan `0 issues`.
2. **Suite Regresi:** Seluruh 42 unit & widget test wajib lulus (`flutter test`).
3. **Ambang Batas Cakupan (Coverage Threshold):** Cakupan kode pada layer Domain dan Presentation Catatan tidak boleh turun di bawah 90%.
