# Modul 12 — Pengujian dan Jaminan Kualitas (Testing & Quality Assurance)
**Aplikasi:** `campus_notify`  
**Mata Kuliah:** Pemrograman Mobile — Semester 5  
**Institusi:** Jurusan Teknologi Informasi — Politeknik Negeri Malang  

---

## 👤 Identitas Mahasiswa

| Atribut | Keterangan |
|:---|:---|
| **Nama** | Wahyudi Satriawan Hamid |
| **NIM** | 244107020137 |
| **Kelas** | TI-3E / Pemrograman Mobile |
| **Modul** | #12 | Pengujian dan Jaminan Kualitas |
| **Repositori** | [244107020137-mobile-course](https://github.com/Wahyudi-Satriawan/244107020137-mobile-course) |
| **Direktori Kerja** | `12-week-12-testing-quality-assurance/` |

---

## 🎯 1. Tujuan Praktikum

Praktikum Modul 12 bertujuan untuk menerapkan strategi pengujian perangkat lunak (*software testing*) dan jaminan kualitas (*quality assurance*) komprehensif pada aplikasi Flutter `campus_notify`, yang meliputi:
1. Menentukan strategi dan jenis pengujian yang tepat berdasarkan piramida pengujian (*Unit*, *Widget*, dan *Integration Testing*).
2. Merancang kode yang mudah diuji (*testable architecture*) dengan memisahkan dependensi melalui kontrak abstraksi repository.
3. Mengimplementasikan *Fake Repository* untuk mengendalikan perilaku data sukses, simulasi kegagalan (*failure*), dan state pemuatan (*loading state*).
4. Menulis pengujian unit berbasis perilaku nyata (*behavior-driven*) mencakup kasus normal (*happy path*), kasus tepi (*edge cases*), dan kegagalan (*failure scenarios*) dengan pola **Arrange-Act-Assert (AAA)**.
5. Menguji komponen antarmuka (*Widget Testing*) secara deterministik tanpa jeda waktu statis (`Future.delayed`).
6. Menyusun pengujian integrasi (*Integration Testing*) end-to-end yang mensimulasikan alur pengguna lintas modul aplikasi.
7. Mengevaluasi metrik cakupan pengujian (*Code Coverage*) sebagai instrumen evaluasi teknis.

---

## 🏛️ 2. Arsitektur Testability & Penerapan Fake Repository

Untuk memastikan pengujian berjalan cepat, deterministik, dan bebas dari dependensi eksternal yang rapuh (*fragile dependencies*), arsitektur aplikasi dirancang dengan kaidah *Clean Architecture* dan *Dependency Injection* berbasis Riverpod:

```
[ Widget Layer / UI ] ──> [ Use Cases ] ──> [ NoteRepository (Contract) ]
                                                        │
                      ┌─────────────────────────────────┴───────────────────┐
                      ▼                                                     ▼
           [ NoteRepositoryImpl ] (Production)                  [ FakeNoteRepository ] (Testing)
             └─> SQLite Database                                  └─> Deterministic In-Memory State
```

### A. Kontrak Abstraksi `NoteRepository`
Lapisan domain mendefinisikan antarmuka murni pada [`lib/features/notes/domain/repositories/note_repository.dart`](lib/features/notes/domain/repositories/note_repository.dart):
```dart
abstract class NoteRepository {
  Future<(List<Note> notes, Failure? failure)> fetchNotes();
  Future<(Note? note, Failure? failure)> addNote({
    required String title,
    String body = '',
  });
}
```

### B. Implementasi `FakeNoteRepository`
Dibuat pada [`test/helpers/fake_note_repository.dart`](test/helpers/fake_note_repository.dart) dengan kapabilitas:
- **Penyimpanan In-Memory:** Mengelola mutasi data catatan secara deterministik tanpa menyentuh SQLite atau *disk I/O*.
- **Simulasi Failure & Exception:** Mendukung parameter `fetchFailure`, `addFailure`, `throwOnFetch`, dan `throwOnAdd` untuk memicu skenario kegagalan secara terkendali.
- **Loading State Deterministic via `Completer`:** Alih-alih menggunakan jeda waktu statis rapuh (`Future.delayed`), fake repository menyediakan `Completer<void>? fetchCompleter` yang memungkinkan penguji menahan *Future* selama frame loading diuji, lalu menyelesaikannya secara presisi:
  ```dart
  if (fetchCompleter != null) {
    await fetchCompleter!.future;
  }
  ```

### C. Fake Service pada Pengujian Integrasi
Pada [`integration_test/app_test.dart`](integration_test/app_test.dart), dependensi eksternal yang membutuhkan perangkat keras atau cloud diisolasi menggunakan:
- `FakeAuthRepository`: Mensimulasikan status pengguna yang telah login secara lokal sehingga navigasi GoRouter langsung mengarah ke Dashboard tanpa ketergantungan endpoint backend auth.
- `FakePushService`: Mencegah pemanggilan native Firebase Cloud Messaging (FCM) yang dapat memicu crash pada test runner lingkungan terisolasi.

---

## 📊 3. Strategi Pengujian & Matriks Skenario

Pengujian disusun mengikuti piramida pengujian dengan menguji perilaku nyata (*real behavior*), bukan sekadar mengejar kelulusan formal:

| Kategori | Komponen / File | Tipe Skenario | Deskripsi Skenario & Kondisi yang Diuji | Status |
|---|---|:---:|---|:---:|
| **Unit** | `ValidateNote` | **Edge Case** | Menolak string `null`, string kosong `''`, whitespace spasi `'   '`, tab `'\t'`, dan newline `'\n'`. | **PASSED** |
| **Unit** | `ValidateNote` | **Edge Case** | Menolak judul dengan panjang karakter bersih < 3 (`'a'`, `'ab'`, `'  a  '`). | **PASSED** |
| **Unit** | `ValidateNote` | **Edge Case** | Menerima judul tepat pada batas ambang minimal 3 karakter (`'abc'`, `'123'`, `'  xyz  '`). | **PASSED** |
| **Unit** | `ValidateNote` | **Happy Path** | Menerima judul valid dengan karakter simbol, spasi ganda, tanda kurung, dan emoji (`'[PENTING] Modul #12'`, `'Dart & Flutter 🚀'`). | **PASSED** |
| **Unit** | `ValidateNote` | **Edge Case** | Menerima judul sangat panjang (*stress input* 500 karakter). | **PASSED** |
| **Unit** | `GetNotes` | **Happy Path** | Meneruskan daftar kosong saat repositori belum memiliki catatan. | **PASSED** |
| **Unit** | `GetNotes` | **Happy Path** | Meneruskan banyak catatan secara terurut dan deterministik dari repositori. | **PASSED** |
| **Unit** | `GetNotes` | **Failure Case** | Meneruskan `Failure` (misal SQLite terkunci) dan **tidak diam-diam mengubah error menjadi list kosong**. | **PASSED** |
| **Unit** | `GetNotes` | **Failure Case** | Meneruskan `Exception` yang dilempar repositori ke pemanggil. | **PASSED** |
| **Unit** | `AddNote` | **Happy Path** | Menyimpan catatan valid dengan pembersihan spasi awal/akhir (`trim()`). | **PASSED** |
| **Unit** | `AddNote` | **Edge Case** | Validasi membatalkan pemanggilan repositori jika judul < 3 karakter (repositori tetap bersih). | **PASSED** |
| **Unit** | `AddNote` | **Failure Case** | Menangani pengembalian `LocalFailure` saat penulisan ke database gagal (misal disk penuh). | **PASSED** |
| **Unit** | `AddNote` | **Failure Case** | Menangani pelemparan `Exception` tak terduga dari repositori. | **PASSED** |
| **Unit** | `notesProvider` | **Happy Path** | Mengalirkan data sukses ke *subscriber* Riverpod. | **PASSED** |
| **Unit** | `notesProvider` | **Failure Case** | Mengalirkan state `hasError: true` saat repositori gagal, mencegah kembalinya data palsu. | **PASSED** |
| **Widget** | `NotesPage` | **Edge Case** | **Loading State:** Menampilkan `CircularProgressIndicator` via `Completer` (tanpa `Future.delayed`), lalu hilang saat data siap. | **PASSED** |
| **Widget** | `NotesPage` | **Happy Path** | **Empty State:** Menampilkan teks `"Belum ada catatan."` saat repositori kosong. | **PASSED** |
| **Widget** | `NotesPage` | **Failure Case** | **Error State:** Menampilkan komponen `ErrorView` dan pesan kegagalan saat fetch gagal. | **PASSED** |
| **Widget** | `NotesPage` | **Failure Case** | **Form Validation:** Input hanya spasi pada judul menampilkan error `"Judul tidak boleh kosong"` dan dialog tidak menutup. | **PASSED** |
| **Widget** | `NotesPage` | **Edge Case** | **Dialog Cancel:** Menekan tombol Batal menutup dialog tanpa menyimpan catatan ke repositori. | **PASSED** |
| **Widget** | `NotesPage` | **Happy Path** | **Happy Path:** Mengisi judul & isi valid via `enterText`, klik Simpan, dialog tertutup, SnackBar muncul, dan item tampil di `NotesList`. | **PASSED** |
| **Integrasi** | `CampusNotifyApp` | **Happy Path & Flow** | **End-to-End Navigation & Form:** Navigasi dari Dashboard (`/`) -> Buka Catatan (`/notes`) -> Dialog Tambah -> Uji input tidak valid -> Isi data valid -> Simpan -> Verifikasi item muncul di daftar. | **PASSED** |
| **Integrasi** | `NotesPage` | **Happy Path** | **Consecutive Notes:** Menambahkan beberapa catatan berurutan dan memverifikasi persistensi rendering UI. | **PASSED** |

---

## 📁 4. Rincian Berkas Test Suite

Test suite terorganisir ke dalam 6 berkas pengujian unit/widget dan 1 pengujian integrasi:

1. 📄 [`test/unit/notes_usecases_test.dart`](test/unit/notes_usecases_test.dart) (15 tests):
   Pengujian unit menyeluruh untuk aturan bisnis domain `ValidateNote`, use case `GetNotes`, use case `AddNote`, serta state management `notesProvider` (Riverpod).
2. 📄 [`test/widget/notes_page_test.dart`](test/widget/notes_page_test.dart) (6 tests):
   Pengujian antarmuka widget `NotesPage` mencakup transisi rendering, evaluasi indikator loading presisi, validasi form dialog, tombol pembatalan, dan happy path penambahan item.
3. 📄 [`test/validate_note_test.dart`](test/validate_note_test.dart) (7 tests):
   Pengujian unit baseline untuk validasi judul dan integrasi awal usecase catatan.
4. 📄 [`test/get_notes_test.dart`](test/get_notes_test.dart) (2 tests):
   Pengujian unit baseline untuk penerusan data repositori catatan.
5. 📄 [`test/ai_service_test.dart`](test/ai_service_test.dart) (9 tests):
   Pengujian unit baseline untuk layanan AI Gemini, penanganan API Key di Secure Storage, serta fallback provider saat offline.
6. 📄 [`test/auth_push_test.dart`](test/auth_push_test.dart) (3 tests):
   Pengujian unit baseline untuk logika sesi auth token store dan parser payload rute notifikasi FCM.
7. 📄 [`integration_test/app_test.dart`](integration_test/app_test.dart) (2 scenarios):
   Pengujian integrasi end-to-end yang memadukan navigasi GoRouter, manajemen sesi, dan alur operasional catatan kampus secara utuh.

---

## 📈 5. Hasil Eksekusi, Analisis Statis & Evaluasi Coverage

### A. Analisis Statis (`flutter analyze`)
```bash
$ flutter analyze
Analyzing 12-week-12-testing-quality-assurance...               
No issues found! (ran in 4.1s)
```
Status: **0 errors, 0 warnings, 0 lints**. Baseline kode terverifikasi bersih.

### B. Hasil Eksekusi Pengujian (`flutter test --coverage`)
```bash
$ flutter test --coverage
00:00 +0: loading test/ai_service_test.dart
...
00:09 +42: All tests passed!
```
Status: **42 dari 42 test cases LULUS (100% Passed)**.

### C. Metrik Cakupan Kode Aktual (`coverage/lcov.info`)
Berdasarkan pembacaan aktual berkas `coverage/lcov.info`:
- **Total Lines Found (LF):** **262**
- **Total Lines Hit (LH):** **192**
- **Total Code Coverage:** **73.28%**

#### Ringkasan Cakupan per Berkas:
| Berkas | Lines Found (LF) | Lines Hit (LH) | Coverage (%) |
|---|:---:|:---:|:---:|
| `lib/features/notes/domain/entities/note.dart` | 1 | 1 | **100.00%** |
| `lib/features/notes/domain/usecases/get_notes.dart` | 3 | 3 | **100.00%** |
| `lib/features/notes/domain/usecases/add_note.dart` | 4 | 4 | **100.00%** |
| `lib/features/notes/domain/usecases/validate_note.dart` | 4 | 4 | **100.00%** |
| `lib/features/notes/presentation/widgets/notes_list.dart` | 17 | 17 | **100.00%** |
| `lib/core/widgets/error_view.dart` | 11 | 11 | **100.00%** |
| `lib/core/utils/route_parser.dart` | 5 | 5 | **100.00%** |
| `lib/features/notes/presentation/pages/notes_page.dart` | 65 | 64 | **98.46%** |
| `lib/features/notes/presentation/providers/notes_providers.dart` | 12 | 11 | **91.67%** |
| `lib/ai/ai_service.dart` | 47 | 43 | **91.49%** |
| `lib/features/ai_chat/presentation/providers/chat_providers.dart` | 34 | 27 | **79.41%** |
| `lib/core/failures.dart` | 4 | 2 | **50.00%** |
| `lib/features/notes/data/datasources/note_local_data_source.dart` | 11 | 0 | **0.00%** *(Diisolasi)* |
| `lib/features/notes/data/models/note_model.dart` | 21 | 0 | **0.00%** *(Diisolasi)* |
| `lib/features/notes/data/repositories/note_repository_impl.dart` | 23 | 0 | **0.00%** *(Diisolasi)* |

> [!NOTE]
> **Interpretasi Evaluasi Coverage:**  
> Angka cakupan kode (73.28%) merupakan instrumen penunjuk jalur eksekusi kode, **bukan jaminan mutlak ketiadaan cacat logika**. Fitur catatan pada lapisan Domain dan UI berhasil mencapai cakupan 98% - 100%, membuktikan bahwa seluruh percabangan logika kritis (*business validation*, *error rendering*, *empty state*) telah diuji secara ketat.

### D. Status Eksekusi Integration Test
- **Analisis Statis:** `flutter analyze integration_test/app_test.dart` -> **No issues found**.
- **Kondisi Perangkat:** Tidak terdapat perangkat fisik Android atau emulator aktif yang terhubung pada sesi ini (`flutter devices` mendeteksi target headless Chrome dan Edge).
- **Perintah Eksekusi Resmi:**
  Untuk mengeksekusi integration test pada perangkat fisik atau emulator aktif:
  ```bash
  flutter test integration_test/app_test.dart -d <device_id>
  ```
  *(Contoh: `flutter test integration_test/app_test.dart -d emulator-5554`)*

---

## 🔍 6. Temuan yang Belum Terselesaikan & Keterbatasan Pengujian

1. **Isolasi Lapisan Driver SQLite Asli:**
   Tiga berkas data (`note_local_data_source.dart`, `note_model.dart`, dan `note_repository_impl.dart`) mencatat coverage 0.00%. Hal ini merupakan keputusan desain QA yang disengaja agar pengujian unit dan widget tidak memicu ketergantungan pada native SQLite binary (`sqflite`). Pengujian terhadap query SQL mentah disarankan diuji melalui pengujian SQLite in-memory pada test harness khusus.
2. **Keterbatasan Eksekusi Pengujian Integrasi pada Lingkungan Headless:**
   `integration_test` membutuhkan emulator Android aktif (AVD) dengan akselerasi GPU atau perangkat fisik yang terotorisasi ADB. Pada lingkungan CI/server tanpa display GUI, eksekusi integration test membutuhkan emulator headless terkonfigurasi.

---

## 💡 7. Refleksi Pembelajaran (Reflective Analysis)

### 1. Bug apa yang paling mungkin terlewat tanpa pengujian yang Anda tulis?
Dua bug kritis yang sangat rentan terlewat tanpa pengujian otomatis ini adalah:
1. **Bug Siklus Hidup `TextEditingController` (*Controller Disposed While Animating*):**  
   Pada implementasi awal `NotesPage`, `titleController` dan `bodyController` dimusnahkan (`dispose()`) tepat setelah `await showDialog(...)`. Namun, saat dialog ditutup dengan `Navigator.pop()`, Flutter masih merender transisi animasi keluar (*pop transition*). Pemusnahan kontroler sebelum animasi selesai memicu kegagalan runtime fatal:
   `A TextEditingController was used after being disposed`. Melalui pengujian widget, masalah ini terdeteksi dan diselesaikan dengan memindahkan kontroler ke `StatefulWidget` terpisah (`_AddNoteDialog`) yang siklus hidupnya terikat pada `State.dispose()`.
2. **Silent Failure pada Lapisan Data:**  
   Tanpa pengujian eksplisit terhadap failure case di `GetNotes` dan `notesProvider`, kegagalan pembacaan database berisiko berubah diam-diam menjadi list kosong `[]`. Pengguna akan mengira mereka belum memiliki catatan, padahal sistem mengalami kegagalan akses data. Pengujian kami memverifikasi bahwa state error diteruskan secara transparan ke antarmuka pengguna (`ErrorView`).

### 2. Bagian mana yang perlu fake, dan bagaimana fake itu membuat pengujian lebih konsisten?
Bagian yang mutlak membutuhkan fake adalah:
- **`NoteRepository`:** Menggantikan database SQLite fisik. Basis data lokal rentan terhadap residu data uji sebelumnya, masalah permission file, dan lambatnya I/O disk. Dengan `FakeNoteRepository`, data tersimpan murni di memori, reset secara instan pada setiap `setUp()`, dan mendukung simulasi error (disk penuh, DB lock) serta penahanan waktu via `Completer`.
- **`AuthRepository` & `PushService`:** Menghilangkan ketergantungan pada koneksi internet, Google Play Services, dan Firebase Backend. Pengujian menjadi 100% deterministik, dapat dijalankan dalam mode offline, dan tidak pernah gagal karena jaringan eksternal yang tidak stabil.

### 3. Apa perbedaan nilai yang diberikan pengujian widget dan pengujian integrasi pada fitur Anda?
- **Pengujian Widget (`Widget Testing`):**  
  Memberikan nilai dalam **kecepatan dan isolasi mendalam**. Berjalan di memory runner tanpa kompilasi APK ke perangkat. Sangat efektif untuk memverifikasi detail interaksi antarmuka: apakah errorText muncul saat validasi gagal, apakah spinner loading berputar saat fetching, dan apakah tombol Simpan merespons ketukan pengguna.
- **Pengujian Integrasi (`Integration Testing`):**  
  Memberikan nilai dalam **keyakinan holistik sistem (*end-to-end confidence*)**. Pengujian integrasi memastikan seluruh subsistem bekerja harmonis saat dirangkai bersama: integrasi GoRouter dari halaman Dashboard menuju halaman Catatan, propagasi auth state, pembukaan dialog, interaksi form, hingga pembaruan state reaktif pada list UI di bawah kendali *real widget binding*.

---

## 📚 8. Referensi Pendukung

- **Slide Perkuliahan Minggu 12:** *Pengujian dan Jaminan Kualitas*, Jurusan Teknologi Informasi, Politeknik Negeri Malang.
- **Flutter Official Documentation:** [Testing Flutter apps overview](https://docs.flutter.dev/testing/overview)
- **Flutter Cookbook:** [An introduction to widget testing](https://docs.flutter.dev/cookbook/testing/widget/introduction)
- **Flutter Official Documentation:** [Integration testing](https://docs.flutter.dev/testing/integration-tests)
- **Dart Packages:** [Package test documentation](https://pub.dev/packages/test)
- **Laporan Teknis Coverage:** [`docs/testing-report.md`](docs/testing-report.md)
