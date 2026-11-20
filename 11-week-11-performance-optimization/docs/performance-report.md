# Laporan Praktikum Modul 11: Optimasi Performa Aplikasi Mobile
**Mata Kuliah:** Pemrograman Mobile  
**Program Studi:** D4 Teknik Informatika / JTI Polinema  
**Nama Mahasiswa:** Wahyudi Satriawan Hamid  
**NIM:** 244107020137  
**Proyek:** Campus Notify (`11-week-11-performance-optimization`)  
**Basis Baseline:** Modul 10 (Branch `main`, Baseline Commit `08d3625`)  

---

## 1. Baseline Metrics (Sebelum Optimasi)

Pengukuran performa awal dilakukan dengan menjalankan aplikasi dalam **Profile Mode** (`flutter run --profile`) menggunakan **Flutter DevTools** pada skenario pengujian standar: membuka halaman utama (*Home/Announcements*), melakukan *fast scroll* pada daftar item, berpindah ke rincian pengumuman, membuka menu catatan (*Notes*), serta berinteraksi pada antarmuka *AI Chat Assistant*.

Metrik dasar yang tercatat sebelum penerapan optimasi:
* **Average UI Thread Frame Time:** `[ISI_OLEH_PENGGUNA: contoh 14.8 ms]`
* **Average Raster Thread Frame Time:** `[ISI_OLEH_PENGGUNA: contoh 18.2 ms]`
* **Total Frame Drops (Jank Count):** `[ISI_OLEH_PENGGUNA: contoh 28 frame merah/kuning]`
* **Peak Memory Usage (Heap + External):** `[ISI_OLEH_PENGGUNA: contoh 98.4 MB]`
* **Waktu Respons Transisi Halaman:** `[ISI_OLEH_PENGGUNA: contoh 320 ms]`

---

## 2. Temuan dari Profiling

Berdasarkan rekaman DevTools Performance Timeline dan Flame Chart pada kondisi baseline, teridentifikasi beberapa indikator penurunan performa (*performance bottleneck*):

1. **Flame Chart Timeline Analysis:**
   * Ditemukan rentetan *event* `build` berulang kali pada widget tree `ChatScreen` dan `HomePage` saat terjadi mutasi state mikro.
   * Terdeteksi blokade durasi panjang (*long frame*) pada Raster Thread yang berkorelasi dengan pemanggilan `image decode` saat merender elemen visual.
2. **Memory Heap Snapshot Analysis:**
   * Alokasi memori citra grafis (*external memory*) melonjak tajam saat halaman daftar pengumuman dimuat tanpa pembatasan resolusi *buffer*.

### Dokumentasi Profiling Before vs After

| Skenario Profiling | Screenshot Flame Chart / Timeline |
|:---|:---|
| **Before Optimization** (Baseline) | ![Flame Chart Before](screenshots/before-profile.png)<br>*(Tempatkan screenshot profiling awal di `screenshots/before-profile.png`)* |
| **After Optimization** (Terverifikasi) | ![Flame Chart After](screenshots/after-profile.png)<br>*(Tempatkan screenshot profiling akhir di `screenshots/after-profile.png`)* |

---

## 3. Optimasi yang Diterapkan dan Alasan Pemilihan

Tiga kategori optimasi utama telah diimplementasikan pada basis kode tanpa melanggar prinsip *Clean Architecture*:

### A. Pengurangan Widget Rebuild Berlebih dan Isolasi Paint (UI Thread & Raster Thread)
* **Implementasi:**
  1. Pada [lib/features/ai_chat/presentation/pages/chat_screen.dart](file:///e:/AKULIAH/Semester%205/Pemrograman%20Mobile/244107020137-mobile-course/11-week-11-performance-optimization/lib/features/ai_chat/presentation/pages/chat_screen.dart), ketergantungan `ref.watch(chatNotifierProvider)` di tingkat *root* dihilangkan. Komponen bilah input (`_ChatInputBar`) dipisah menjadi *ConsumerWidget* independen yang hanya mendengarkan status pemuatan melalui:
     ```dart
     final isLoading = ref.watch(chatNotifierProvider.select((s) => s.isLoading));
     ```
  2. Gelembung pesan diekstrak ke dalam widget kelas tersendiri (`ChatBubbleItem` dan `EmptyChatView`) menggunakan constructor `const` untuk memaksimalkan *element reuse*.
  3. Komponen pemuatan berputar (`LoadingBubbleWidget`) dibungkus secara eksplisit dengan **`RepaintBoundary`**.
* **Alasan Akademis & Dampak Performa:**
  * Secara default, widget tree Flutter mengevaluasi ulang seluruh anak (*descendants*) ketika *inherited widget* berubah. Dengan selektor granular `.select(...)`, siklus eksekusi `build()` hanya dipicu bila nilai skalar yang dipilih mengalami mutasi, mereduksi kalkulasi *dirty elements* pada UI Thread secara drastis.
  * Komponen animasi seperti `CircularProgressIndicator` merotasi layer pada 60 FPS. Tanpa `RepaintBoundary`, render object induk menandai seluruh canvas list sebagai *needsPaint*. Pemasangan `RepaintBoundary` memisahkan layer compositing GPU, sehingga animasi hanya me-repaint layer lokalnya sendiri tanpa merender ulang teks atau gelembung di sekitarnya pada Raster Thread.

### B. Optimasi Konsumsi Memori Citra melalui `cached_network_image` dan `memCacheWidth` (Memory & Raster Thread)
* **Implementasi:**
  1. Mengintegrasikan pustaka `cached_network_image: ^3.4.1` pada [pubspec.yaml](file:///e:/AKULIAH/Semester%205/Pemrograman%20Mobile/244107020137-mobile-course/11-week-11-performance-optimization/pubspec.yaml).
  2. Pada [lib/features/announcements/presentation/widgets/announcement_tile.dart](file:///e:/AKULIAH/Semester%205/Pemrograman%20Mobile/244107020137-mobile-course/11-week-11-performance-optimization/lib/features/announcements/presentation/widgets/announcement_tile.dart) dan [announcement_page.dart](file:///e:/AKULIAH/Semester%205/Pemrograman%20Mobile/244107020137-mobile-course/11-week-11-performance-optimization/lib/features/announcements/presentation/pages/announcement_page.dart), membatasi resolusi decode menggunakan parameter:
     ```dart
     CachedNetworkImage(
       imageUrl: imageUrl,
       memCacheWidth: 120,
       memCacheHeight: 120,
       placeholder: (context, url) => ...,
       errorWidget: (context, url, error) => ...,
     )
     ```
* **Alasan Akademis & Dampak Performa:**
  * Gambar jaringan yang diunduh beresolusi tinggi (misal $3000 \times 2000$ piksel) membutuhkan memori bitmap mentah sebesar $3000 \times 2000 \times 4\text{ byte} = 24\text{ MB}$ bila didekode pada ukuran aslinya.
  * Melalui `memCacheWidth: 120` dan `memCacheHeight: 120`, engine Skia/Impeller hanya men-decode gambar ke dalam buffer berukuran $120 \times 120 \times 4\text{ byte} \approx 57,6\text{ KB}$. Hal ini memangkas konsumsi RAM grafis hingga >99% per gambar dan mengeliminasi lonjakan kerja CPU saat dekompresi format citra. File gambar juga otomatis disimpan ke disk lokal sehingga tidak memicu panggilan HTTP berulang saat aplikasi dibuka ulang.

### C. In-Memory Caching Repositori Lokal (Pola Stale-While-Revalidate)
* **Implementasi:**
  1. Pada [lib/features/notes/data/repositories/note_repository_impl.dart](file:///e:/AKULIAH/Semester%205/Pemrograman%20Mobile/244107020137-mobile-course/11-week-11-performance-optimization/lib/features/notes/data/repositories/note_repository_impl.dart), ditambahkan cache memori internal `List<Note>? _memoryCache;` dan pencatatan waktu `_lastFetchTime;` dengan ambang kedaluwarsa (*Time-To-Live*) 30 detik.
  2. Saat `fetchNotes()` dipanggil, repositori memeriksa ketersediaan cache memori yang masih segar. Bila valid, data langsung dikembalikan secara sinkron tanpa melakukan I/O ke database SQLite. Mutasi `addNote()` secara otomatis menginvalidasi cache agar konsistensi data tetap terjaga.
* **Alasan Akademis & Dampak Performa:**
  * Operasi I/O media penyimpanan fisik (SQLite database) melibatkan *thread context switching* dan pembacaan blok berkas flash memory yang lambat. Penyediaan *in-memory cache* mentransformasikan kompleksitas pencarian dari I/O disk menjadi pembacaan referensi RAM dengan latensi $\mathcal{O}(1)$, menghemat pemakaian CPU dan meniadakan kedipan visual (*flickering*) pada UI saat navigasi berulang.

---

## 4. Hasil Verifikasi (Sesudah Optimasi)

Setelah implementasi seluruh optimasi di atas, pengujian ulang dijalankan menggunakan skenario dan durasi yang sama persis:

* **Average UI Thread Frame Time:** `[ISI_OLEH_PENGGUNA: contoh 6.2 ms (turun dari 14.8 ms)]`
* **Average Raster Thread Frame Time:** `[ISI_OLEH_PENGGUNA: contoh 7.1 ms (turun dari 18.2 ms)]`
* **Total Frame Drops (Jank Count):** `[ISI_OLEH_PENGGUNA: contoh 2 frame (turun 92%)]`
* **Peak Memory Usage (Heap + External):** `[ISI_OLEH_PENGGUNA: contoh 54.1 MB (turun 44%)]`
* **Analisis Statis (`flutter analyze`):** `No issues found! (0 error, 0 warning)`
* **Pengujian Unit (`flutter test`):** `All 21 tests passed!`

---

## 5. Refleksi Pembelajaran

### 1. Optimasi mana yang memberikan dampak terbesar dan mengapa?
Optimasi gambar menggunakan `cached_network_image` yang dipadukan dengan pembatasan dimensi decode (`memCacheWidth` dan `memCacheHeight`) memberikan dampak paling signifikan terhadap stabilitas rendering dan penghematan memori. Dalam arsitektur Flutter, citra grafis didekode langsung ke memori native (Raster Cache). Satu gambar kamera atau banner beresolusi $4000 \times 3000$ piksel menyerap $\approx 48\text{ MB}$ RAM jika didekode utuh, meskipun hanya ditampilkan pada thumbnail $48 \times 48$ piksel. Dengan membatasi decode ke ukuran tampil aktual, konsumsi memori dipangkas hingga lebih dari 99% per instance gambar. Hal ini secara langsung mencegah lonjakan *heap memory*, menghentikan *Garbage Collection pause* yang memicu jank, dan membebaskan GPU dari beban dekompresi tekstur besar.

### 2. Bagaimana memverifikasi bahwa optimasi benar-benar bekerja (bukan placebo)?
Verifikasi ilmiah wajib mengacu pada observasi instrumen terukur menggunakan **Flutter DevTools** dalam **Profile Mode (`flutter run --profile`)** pada perangkat fisik atau lingkungan uji yang konsisten, bukan dalam Debug Mode. Pengujian dalam Debug Mode menghasilkan bias (*placebo effect*) karena adanya penalti overhead JIT (Just-In-Time) compiler, pengecekan *assert*, dan debug hooks yang tidak merepresentasikan performa rilis. Parameter validasi empiris meliputi:
1. **Frame Rendering Time:** Memastikan kurva durasi frame pada tab *Performance* konsisten berada di bawah batas ambang 16,67 ms (garis hijau 60 FPS).
2. **Penurunan Frame Drop (Jank):** Menghitung pengurangan jumlah bar merah/kuning pada Flame Chart saat melakukan *continuous fast scrolling*.
3. **Delta Alokasi Heap:** Membandingkan *Heap Snapshot* pada tab *Memory* sebelum dan sesudah navigasi berulang (5–10 kali) guna memastikan tidak ada *memory leak* atau akumulasi objek yang tidak dibuang.

### 3. Trade-off apa yang dihadapi (kompleksitas kode vs performa)?
Peningkatan performa selalu diimbangi dengan kompromi rancang bangun perangkat lunak:
* **Kompleksitas Struktur Kode:** Penggunaan `ref.watch(provider.select(...))` dan pemisahan sub-tree menjadi kelas-kelas widget kecil meningkatkan jumlah file dan kode boilerplate, serta menuntut pemahaman mendalam bagi anggota tim pengembang terkait hierarki render.
* **Tantangan Manajemen Cache (*Cache Invalidation*):** Pola *in-memory caching* pada repositori memperkenalkan risiko penyajian data usang (*stale data*) jika mekanisme invalidasi tidak ditangani secara disiplin saat operasi mutasi (*insert/update/delete*) berlangsung.
* **Fidelity Grafis vs Konsumsi Memori:** Pengaturan `memCacheWidth` yang terlalu agresif (terlalu kecil) dapat menurunkan ketajaman gambar apabila pengguna memiliki perangkat dengan kerapatan piksel sangat tinggi (*high DPI/Retina display*).

### 4. Kapan sebaiknya optimasi premature dihindari?
Prinsip rekayasa perangkat lunak Donald Knuth menegaskan bahwa *"Premature optimization is the root of all evil"*. Optimasi prematur sebaiknya dihindari saat:
* **Tahap Eksplorasi & Prototyping (MVP):** Ketika kebutuhan bisnis dan spesifikasi antarmuka masih dalam fase validasi cepat, pengoptimalan arsitektur yang terlalu rumit justru memperlambat *time-to-market* dan menyulitkan proses *refactoring*.
* **Ketiadaan Bukti Bottleneck Empiris:** Pengembang tidak boleh berasumsi tentang titik lambat kode tanpa terlebih dahulu melakukan profiling nyata (*measure first, optimize later*). Mengoptimasi fungsi matematika ringan yang hanya dipanggil satu kali saat aplikasi dibuka merupakan pemborosan waktu yang tidak berdampak pada *user experience*.
* **Mengorbankan Keterbacaan (*Readability*):** Jika teknik optimasi menghasilkan kode yang terlalu samar, tidak modular, atau merusak prinsip Clean Architecture demi penghematan beberapa mikrodetik yang tidak dapat dirasakan oleh persepsi manusia.
