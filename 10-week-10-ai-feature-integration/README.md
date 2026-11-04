# Modul 10: Integrasi Fitur AI Chat Assistant pada Campus Notify

## Identitas Mahasiswa

| Atribut | Keterangan |
| --- | --- |
| **Nama** | Wahyudi Satriawan Hamid |
| **NIM** | 244107020137 |
| **Proyek** | Campus Notify (Integrasi Fitur AI) |
| **Mata Kuliah** | Pemrograman Mobile |
| **Cabang Git** | feat/ai-chat-integration |
| **Repositori** | [244107020137-mobile-course](https://github.com/Wahyudi-Satriawan/244107020137-mobile-course) |

## Deskripsi Implementasi

Pada modul ini, aplikasi Campus Notify dikembangkan dengan menambahkan fitur asisten percakapan berbasis kecerdasan buatan (Chat Assistant). Fitur ini dirancang untuk memfasilitasi mahasiswa dalam memperoleh informasi terkait jadwal perkuliahan, pengumuman akademik, dan informasi kampus secara langsung di dalam aplikasi. Integrasi dilakukan menggunakan layanan Google Gemini API melalui protokol REST (`HTTP POST`).

### Komponen Utama

1. **Layanan AI** (lib/ai/ai_service.dart)
Komponen ini menangani seluruh komunikasi jaringan ke Google Gemini API. Untuk menjaga keamanan kredensial, kunci API tidak disimpan secara langsung di dalam kode sumber, melainkan dikelola menggunakan pustaka `flutter_secure_storage` agar tersimpan secara terenkripsi pada penyimpanan aman sistem operasi. Selain itu, diterapkan instruksi sistem (*system prompt*) untuk membatasi konteks respons model:
> "Kamu adalah asisten kampus ramah untuk aplikasi Campus Notify. Jawab singkat dalam Bahasa Indonesia, maksimal 2 kalimat. Jangan pernah meminta atau menyimpan data pribadi."


Penanganan kesalahan diimplementasikan menggunakan blok `try-catch`. Apabila kode status respons bukan 200 atau terjadi kegagalan koneksi jaringan, layanan akan melempar pengecualian `AiServiceException` dengan pesan spesifik agar dapat dikelola oleh lapisan presentasi.
2. **Antarmuka Percakapan** (lib/features/ai_chat/chat_screen.dart)
Antarmuka pengguna dibangun menggunakan `ConsumerWidget` dan manajemen *state* Riverpod. Halaman ini menampilkan daftar pesan pengguna dan respons asisten AI, dilengkapi indikator pemuatan `CircularProgressIndicator` selama proses pengambilan respons berlangsung, serta menu konfigurasi kunci API pada bilah aplikasi. Apabila `AiServiceException` tertangkap oleh `ChatNotifier`, aplikasi akan menampilkan komponen `AlertDialog` sebagai mekanisme *fallback* dengan pesan:
> "Layanan AI Sibuk. Coba lagi nanti atau gunakan mode offline."


3. **Konfigurasi Navigasi** (lib/routes.dart)
Rute navigasi `/chat` dan `/ai-chat` ditambahkan pada konfigurasi rute utama. Halaman percakapan dapat diakses melalui tombol aksi pada bilah atas halaman utama maupun melalui komponen `FloatingActionButton`.

## Dokumentasi Antarmuka

*Tampilan antarmuka percakapan saat berhasil menjawab pertanyaan pengguna beserta indikator pemuatan.*

*Tampilan dialog fallback saat layanan AI mengalami gangguan atau tidak tersedia.*

## Analisis Risiko dan Mitigasi

| Risiko | Dampak Utama | Strategi Mitigasi |
| --- | --- | --- |
| **Kebocoran data** | Eksposur privasi pengguna | Enkripsi `flutter_secure_storage` dan pembatasan *prompt* |
| **Lonjakan biaya** | Konsumsi token berlebih | Pembatasan panjang respons dan model `gemini-1.5-flash` |
| **Kegagalan layanan** | Aplikasi berhenti merespons | Penanganan `try-catch` dan dialog *fallback* |
| **Respons menyimpang** | Informasi luar konteks | Penetapan persona akademik pada *system prompt* |

Mitigasi risiko difokuskan pada empat aspek operasional utama:

* **Keamanan Privasi**: Instruksi sistem melarang model meminta atau menyimpan data sensitif, sementara kunci API diamankan melalui `flutter_secure_storage`.
* **Efisiensi Biaya**: Respons dibatasi maksimal dua kalimat dan tombol pengiriman dinonaktifkan selama status pemuatan aktif untuk mencegah permintaan berulang.
* **Keandalan Sistem**: Kegagalan jaringan atau layanan ditangani melalui blok `try-catch` yang memicu dialog informasi tanpa menghentikan jalannya aplikasi.
* **Relevansi Konteks**: Batasan domain percakapan ditetapkan secara eksplisit pada instruksi sistem agar model hanya merespons topik seputar kegiatan kampus.

## Refleksi Pembelajaran

**1. Pemilihan Fitur AI dan Alasan Implementasi**
Fitur yang diintegrasikan pada proyek ini adalah Chat Assistant berbasis Google Gemini. Pemilihan fitur ini didasarkan pada kebutuhan pengguna aplikasi Campus Notify yang memerlukan akses cepat terhadap informasi akademik. Melalui antarmuka percakapan, mahasiswa dapat menanyakan jadwal, pengumuman, maupun informasi perkuliahan dalam satu halaman terpadu tanpa harus berpindah ke banyak menu. Penggunaan varian model Flash juga memberikan waktu respons yang cepat dengan efisiensi biaya yang sesuai untuk skala pengembangan aplikasi kampus.

**2. Perlindungan Privasi Pengguna pada Penggunaan AI API**
Perlindungan privasi diterapkan melalui tiga lapisan pengamanan. Pertama, kunci autentikasi API disimpan secara terenkripsi pada penyimpanan sistem menggunakan `flutter_secure_storage` sehingga tidak terekspos pada kode sumber. Kedua, instruksi sistem dirancang secara eksplisit untuk mencegah model meminta atau memproses informasi identitas pribadi. Ketiga, data yang dikirimkan pada muatan permintaan (*request payload*) hanya berisi teks pertanyaan pengguna tanpa menyertakan token sesi, alamat surel, maupun identitas perangkat.

**3. Mekanisme Fallback saat Layanan AI Mengalami Gangguan**
Mekanisme *fallback* diimplementasikan dengan memisahkan logika penangkapan kesalahan pada lapisan layanan dan lapisan presentasi. Seluruh potensi kegagalan seperti ketiadaan koneksi internet, kunci API yang belum diatur, batas waktu permintaan habis (*timeout*), maupun kode status HTTP di luar kondisi sukses dikonversi menjadi objek `AiServiceException`. Objek ini kemudian ditangkap oleh `ChatNotifier` untuk memicu tampilan `AlertDialog` yang menginformasikan kondisi layanan kepada pengguna, sehingga aplikasi tetap stabil dan pengguna dapat beralih ke fitur luring lainnya.

**4. Pembelajaran Terkait Pengalaman Pengguna (UX) Fitur AI pada Perangkat Mobile**
Aspek terpenting dalam perancangan pengalaman pengguna untuk fitur berbasis LLM pada perangkat bergerak adalah pengelolaan masa tunggu (*latency*). Permintaan jaringan menuju model AI memerlukan waktu pemrosesan beberapa detik, sehingga ketiadaan umpan balik visual dapat membuat pengguna mengira aplikasi mengalami kegagalan fungsi dan menekan tombol kirim secara berulang. Penerapan komponen `CircularProgressIndicator` yang dipadukan dengan penonaktifan tombol kirim melalui variabel `isLoading` terbukti efektif untuk menjaga kejelasan status sistem selama proses komunikasi berlangsung.

## Hasil Pengujian dan Analisis Statis

### Analisis Statis (Flutter Analyze)

```bash
$ flutter analyze
Analyzing 244107020137-mobile-course...
No issues found! (ran in 121.0s)

```

```bash
$ cd 07-week-7-clean-architecture/campus_notify
$ flutter analyze
Analyzing campus_notify...
No issues found! (ran in 4.2s)

```

### Pengujian Unit (Flutter Test)

```bash
$ flutter test
00:00 +0: loading test/ai_service_test.dart
00:00 +1: AiService Unit Tests Gagal jika API Key belum tersedia di storage
00:00 +2: AiService Unit Tests Gagal jika pertanyaan kosong
00:00 +3: AiService Unit Tests Sukses parsing respon Gemini saat status 200
00:00 +4: AiService Unit Tests Melempar AiServiceException spesifik jika API mengembalikan status error
00:00 +5: AiService Unit Tests Melempar AiServiceException jika terjadi kegagalan jaringan (offline)
00:00 +6: AiService Unit Tests Simpan dan baca API Key di Secure Storage berjalan dengan baik
00:00 +7: ChatNotifier & Fallback Logic Tests Mengirim pesan sukses memperbarui list pesan dan status loading
00:00 +8: ChatNotifier & Fallback Logic Tests Menangkap error dan mengisi errorMessage saat AI gagal merespons (Fallback)
00:00 +9: ValidateNote Domain Logic Tests...
00:00 +15: All tests passed!

```

Seluruh pengujian pada repositori utama dan modul aplikasi telah lulus verifikasi tanpa temuan kesalahan.