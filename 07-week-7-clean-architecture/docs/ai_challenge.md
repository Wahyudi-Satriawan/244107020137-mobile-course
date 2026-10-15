##### Dokumentasi AI Challenge - Modul 07 Clean Architecture

##### 1\. Prompt Awal

Project Flutter saya: campus\_notify (auth + FCM + daftar pengumuman).
Kondisi kini: folder lib/{data, providers, pages, messaging}, repository tercampur dengan implementasi, widget memanggil Dio langsung.
Tugas:

1. Usulkan struktur feature-first Clean Architecture (presentation/domain/data) untuk fitur auth + announcements.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana, dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan). Jelaskan trade-off setiap keputusan.



##### 2\. Ringkasan Saran Awal AI

1. Membagi struktur folder per fitur (auth, announcements, notes) dengan 3 sub-layer: domain, data, dan presentation.
2. Membuat kelas Use Case terpisah untuk semua operasi (Login, Logout, RefreshToken, GetAnnouncements, AddNote, DeleteNote, dll).
3. Memisah `AuthRepository` menjadi interface di domain dan implementasi di data.
4. Menggunakan Riverpod Provider bawaan untuk Dependency Injection.



##### 3\. Evaluasi Saran AI vs Keputusan Akhir

* Pemisahan Interface dan Implementasi
Saran AI: Buat `AuthRepository` di domain dan `AuthRepositoryImpl` di data.
Keputusan: Diterima. Menerapkan Dependency Inversion agar layer domain tetap murni dan gampang diuji dengan fake repository.
* Jumlah Use Case
Saran AI: Buat Use Case untuk setiap fungsi CRUD 1 baris.
Keputusan: Disesuaikan. Terlalu banyak file yang tidak perlu. Use Case cuma dipakai di fitur yang ada validasi atau alur bisnis (seperti `LoginUseCase` dan `GetNotes`). Sisanya langsung panggil repo dari notifier.
* Pemisahan Entity dan Model
Saran AI: Pisahkan entitas domain dari metode serialisasi (`toMap`/`fromMap`).
Keputusan: Diterima. Format konversi data adalah urusan layer data, sehingga entitas di domain tetap bersih.
* Wiring Dependency Injection
Saran AI: Gunakan Riverpod Provider tanpa package tambahan.
Keputusan: Diterima. Fitur bawaan Riverpod sudah cukup sebagai DI container tanpa perlu menambah package seperti GetIt.
* Penanganan Listener FCM
Saran AI: Biarkan listener FCM dipanggil di dalam widget UI.
Keputusan: Ditolak. Memanggil listener di method `build()` bikin listener terdaftar berkali-kali saat render ulang. Listener dipindahkan ke fungsi `main()`.



##### 4\. Verifikasi Sterilitas Layer

1. Layer Presentation bebas dari import data dan DB mentah:
Get-ChildItem -Path "campus\_notify/lib/features/\*/presentation" -Recurse | Select-String -Pattern "dio", "sqflite", "dart:io"
Hasil: 0 temuan.
2. Layer Domain bebas dari library eksternal:
Get-ChildItem -Path "campus\_notify/lib/features/\*/domain", "campus\_notify/lib/core/failures.dart" -Recurse | Select-String -Pattern "package:flutter", "dio", "sqflite"
Hasil: 0 temuan.
3. Hasil Analisis dan Test:
flutter analyze: No issues found!
flutter test: 6 tests passed!

