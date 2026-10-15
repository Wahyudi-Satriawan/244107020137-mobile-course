##### Laporan Praktikum Modul 07 - Clean Architecture (Campus Notify)

##### 1\. Tujuan Praktikum

Merapikan struktur kode proyek Flutter `campus\_notify`. Kode awal yang masih mencampur UI, API, dan database lokal ditata ulang menggunakan pola Clean Architecture berbasis fitur (feature-first).



##### 2\. Riwayat Refactoring File

Berikut ringkasan perubahan dari file lama ke struktur baru:

* `pages/home\_page.dart` (Presentation)
Masalah: Menggunakan data dummy statis, mengambil token FCM lewat variabel global, dan memakai `pushNamed` padahal sudah ada GoRouter.
Solusi: Dipindah ke `features/announcements/presentation/pages/home\_page.dart`. Widget dipecah jadi `FcmTokenCard` dan `AnnouncementTile`, lalu navigasinya disesuaikan ke `GoRouter`.
* `pages/login\_page.dart` (Presentation)
Masalah: Indikator loading dan pesan error ditulis langsung di dalam widget.
Solusi: Dipindah ke `features/auth/presentation/pages/login\_page.dart`. Logika UI diserahkan ke komponen `AppLoadingView` dan `AppErrorView`.
* `pages/announcement\_page.dart` (Presentation)
Masalah: Detail pengumuman belum dikelompokkan per modul fitur.
Solusi: Dipindah ke `features/announcements/presentation/pages/announcement\_page.dart`.
* `providers/auth\_provider.dart` (Presentation)
Masalah: Ada kebocoran dependensi karena memanggil `AuthRepository()` dan `TokenStore()` langsung di provider UI.
Solusi: Dipindah ke `features/auth/presentation/providers/auth\_providers.dart`. Provider disesuaikan agar hanya memanggil `LoginUseCase` dari domain.
* `data/auth\_repository.dart` (Data)
Masalah: Model sesi (`AuthSession`), interface, dan implementasi kodenya dicampur di satu file.
Solusi: Dipisah. Entitas `AuthSession` dan interface `AuthRepository` ditaruh di `domain`, sedangkan `AuthRepositoryImpl` ditempatkan di `data`.
* `data/api\_client.dart` (Data)
Masalah: Bergantung langsung ke kelas konkret `AuthRepository`.
Solusi: Dipindah ke `core/network/api\_client.dart` dan diubah agar bergantung ke interface abstrak `AuthRepository`.
* `data/token\_store.dart` (Data)
Masalah: Penyimpanan token belum masuk ke folder core.
Solusi: Dipindah ke `core/storage/token\_store.dart`.
* `main.dart` (Bootstrap)
Masalah: Fungsi `build()` menjalankan listener FCM berulang kali dan menginstansi GoRouter tiap kali render.
Solusi: Listener FCM dipindah ke fungsi `main()` sebelum render. GoRouter dikelola lewat `routerProvider` agar `build()` tetap bersih.
* `features/notes/` (Inkomplit)
Masalah: Ada file kosong `note\_repository\_impl.dart` di domain, import `note\_model.dart` salah, dan `openDb` SQLite belum diisi kodenya.
Solusi: File kosong di domain dihapus, import dibetulkan, lalu dibuatkan `NoteLocalDataSource` buat buka SQLite (`openDatabase`) yang dihubungkan ke `NoteRepositoryImpl`.



##### 3\. Pengecekan Aturan Arsitektur (Terminal Grep)

Pengujian dilakukan via terminal untuk memastikan tidak ada batas layer yang dilanggar:

1. Layer Presentation bebas dari panggilan DB dan Network langsung:
Pengecekan kata kunci `Dio`, `openDatabase`, `getDatabasesPath`, dan `FlutterSecureStorage` pada folder `presentation`.
Hasil: 0 temuan.
2. Layer Domain bebas dari library eksternal:
Pengecekan kata kunci `package:flutter`, `dio`, dan `sqflite` pada folder `domain` dan file `failures.dart`.
Hasil: 0 temuan (murni Dart).
3. Fungsi `build()` bebas dari side-effect:
Listener notifikasi dan inisialisasi DI sudah dipindah ke luar fungsi `build()`.
Hasil: 0 temuan.



##### 4\. Hasil Pengujian

* `flutter analyze`:
Analyzing campus\_notify...
No issues found! (ran in 5.3s)
* `flutter test`:
Semua 6 unit test berhasil, termasuk pengujian `GetNotes` memakai fake repository saat sukses maupun saat database terkunci:
00:00 +0: Testing Route Parser FCM Payload Route parser menangani route kosong atau null tanpa crash
00:00 +1: Testing Route Parser FCM Payload Route parser memformat string route dengan benar
00:00 +2: Testing Logika Sesi Token Store Status sesi dianggap aktif jika access token tersimpan
00:00 +3: Testing Logika Sesi Token Store Wajib login ulang jika refresh token kosong
00:00 +4: GetNotes meneruskan daftar dari repository
00:00 +5: GetNotes meneruskan failure tanpa melempar
00:00 +6: All tests passed!



##### 6\. Pembahasan dan Jawaban Tugas

1. Mengapa interface repository ditaruh di domain?
Karena aturan Clean Architecture melarang layer bisnis (domain) bergantung pada detail teknis di luar (data). Domain cuma menentukan data apa yang dibutuhkan, sedangkan layer data yang menentukan cara mengambilnya. Kalau dibalik, layer domain terpaksa mengimpor folder data, sehingga arsitekturnya menyatu dan susah diuji dengan mock/fake repository.
2. Kapan butuh use case dan kapan cukup pemanggilan langsung ke repository?
Use case dibutuhkan kalau ada logika bisnis, seperti validasi input, penggabungan dua sumber data, atau manipulasi data sebelum sampai ke UI. Kalau operasinya cuma CRUD 1 baris tanpa aturan khusus, dari StateNotifier langsung panggil repository sudah cukup.
3. Biaya over-engineering jika semua CRUD dibuatkan use case:
Bikin banyak file berulang yang memperlambat pengerjaan, terutama di tim kecil. Navigasi kode jadi rumit tanpa ada nilai tambah. Biaya ini baru sepadan kalau aplikasinya besar, logikanya kompleks, dan dikerjakan banyak orang sekaligus.
4. Penyesuaian terhadap saran AI:
Saran AI untuk membuat file use case di setiap fungsi CRUD ditolak karena membuat proyek terlalu rumit. Pemanggilan repository secara langsung dari notifier dipakai pada fitur yang sederhana. Pendaftaran listener FCM di dalam method `build()` juga ditolak dan dipindahkan ke fungsi `main()` untuk mencegah memori bocor.



##### 7\. Cara Menjalankan Proyek

1. Masuk ke folder proyek:
cd campus\_notify
2. Jalankan analisis kode:
flutter analyze
3. Jalankan unit test:
flutter test
4. Jalankan aplikasi:
flutter run

