# AI Review Challenge & Tabel Keputusan Rekayasa

Dokumen ini mendokumentasikan proses tinjauan kode (*code review*) menggunakan asisten AI pada branch `feat/notes-validation`, verifikasi teknis atas temuan yang dihasilkan, serta keputusan akhir penerimaan atau penolakan saran.

---

## 1. Prompt AI yang Digunakan

Prompt berikut dieksekusi untuk mereview kode pull request:

> *"Review PR Flutter ini sebagai senior Flutter dev. Konteks: feature-first Clean Architecture (presentation -> domain <- data), Riverpod, GoRouter, SQLite + Dio. Fokus: kebenaran, arsitektur, dan test. Abaikan style. Berikan maksimal 5 temuan teratas: level (blocker/saran), baris, alasan, usulan potongan kode perbaikan."*

---

## 2. Output Awal AI (Temuan Mentah)

Berikut adalah ringkasan respon evaluasi yang diberikan oleh AI:

### Temuan 1: Validasi String Kosong / Whitespace dan Batas Minimal
- **Level**: Blocker
- **Lokasi**: `lib/features/notes/domain/usecases/validate_note.dart`
- **Alasan**: Pengguna masih dapat menyimpan judul yang hanya berisi spasi (`"   "`). Validasi harus melakukan `trim()` dan memastikan panjang karakter judul minimal 3 huruf agar catatan memiliki nilai semantik.
- **Usulan Kode**:
  ```dart
  ValidationFailure? call(String? title) {
    if (title == null || title.trim().isEmpty) {
      return const ValidationFailure('Judul tidak boleh kosong');
    }
    if (title.trim().length < 3) {
      return const ValidationFailure('Judul minimal 3 karakter');
    }
    return null;
  }
  ```

### Temuan 2: Pengujian Integritas Panggilan Repository pada Kasus Gagal
- **Level**: Blocker
- **Lokasi**: `test/validate_note_test.dart`
- **Alasan**: Unit test `AddNote` pada skenario gagal hanya memeriksa apakah hasil `failure` bernilai `ValidationFailure`, namun belum memverifikasi bahwa state repository (`repo.notes`) benar-benar tetap kosong dan `addNote` tidak dipanggil secara diam-diam.
- **Usulan Kode**:
  ```dart
  test('Skenario gagal: judul kosong ditolak sebelum masuk repository', () async {
    final (note, failure) = await addNote(title: '   ');
    expect(note, isNull);
    expect(failure, isA<ValidationFailure>());
    expect(repo.notes, isEmpty); // Verifikasi repository tidak disentuh
  });
  ```

### Temuan 3: Penyederhanaan Form Input dengan Mengimpor Controller ke Domain
- **Level**: Saran
- **Lokasi**: `lib/features/notes/domain/usecases/add_note.dart`
- **Alasan AI**: "Agar lebih ringkas dan tidak perlu passing string `title` dan `body` manual dari UI, buat parameter use case langsung menerima `TextEditingController` dari Flutter Material."
- **Usulan Kode**:
  ```dart
  import 'package:flutter/material.dart'; // Saran AI

  Future<(Note?, Failure?)> call(TextEditingController titleCtrl, TextEditingController bodyCtrl) { ... }
  ```

### Temuan 4: Format Koma Trailing dan Spasi Indentasi
- **Level**: Saran
- **Lokasi**: `lib/features/notes/presentation/pages/notes_page.dart`
- **Alasan AI**: "Tambahkan koma trailing pada penutupan widget `AlertDialog` dan pisahkan baris `actions` dengan line break manual."

---

## 3. Tabel Verifikasi & Keputusan Final (AI vs Engineering Decision)

| No | Temuan & Usulan AI | Level | Bukti Verifikasi (Grep / Test) | Keputusan | Alasan Teknis Rekayasa |
| :-: | :--- | :---: | :--- | :---: | :--- |
| **1** | Menerapkan `trim()` dan validasi batas minimal `< 3` karakter pada `ValidateNote`. | Blocker | Unit test `validate_note_test.dart` berhasil menangkap input `"   "` dan `"ab"` sebagai `ValidationFailure`. | **DITERIMA** | Sesuai dengan spesifikasi bisnis. Mencegah catatan sampah tanpa identitas masuk ke database lokal SQLite. |
| **2** | Memastikan `repo.notes.isEmpty` pada pengujian saat validasi gagal. | Blocker | Assert `expect(repo.notes, isEmpty)` lulus pada test suite. | **DITERIMA** | Menjamin integritas use case bahwa logika validasi menjadi garda depan (*short-circuit*) sebelum sumber daya I/O disentuh. |
| **3** | Mengimpor `package:flutter/material.dart` dan `TextEditingController` ke use case domain. | Saran | Perintah grep sterilitas: `Select-String "package:flutter" lib/.../domain/` wajib 0 temuan. | **DITOLAK** | **Pelanggaran Keras Clean Architecture**. Layer Domain adalah *Pure Dart* yang tidak boleh mengenal UI framework Flutter. Jika diimpor, domain menjadi tightly-coupled ke widget tree dan gagal diuji tanpa environment Flutter widget. |
| **4** | Perbaikan manual format spasi dan koma trailing pada `notes_page.dart`. | Saran | Mesin otomatis: `dart format --set-exit-if-changed .` sudah dijalankan dan bersih. | **DITOLAK** | Masalah formatting visual adalah tanggung jawab *linter* dan *formatter* otomatis (`dart format`). Melakukan review manual atas debat spasi melanggar efisiensi code review tim. |

---

## 4. Kesimpulan Evaluasi AI
Review AI sangat efektif untuk menemukan *edge case* logika (seperti whitespace dan skenario test assertion), namun AI kerap memberikan saran yang merusak batas arsitektur (*architectural violation*). Verifikasi manusia berbasis aturan arsitektur mutlak diperlukan sebelum menerapkan saran AI.
