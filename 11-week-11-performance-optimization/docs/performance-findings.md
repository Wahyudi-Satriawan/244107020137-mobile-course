# Laporan Temuan Bottleneck Performa Aplikasi
**Mata Kuliah:** Pemrograman Mobile  
**Modul:** Minggu 11 — Optimasi Performa  
**Proyek:** Campus Notify (`11-week-11-performance-optimization`)  
**Penyusun:** Wahyudi Satriawan Hamid (NIM: 244107020137)  

---

## 1. Pendahuluan

Evaluasi performa perangkat lunak bergerak berfokus pada efisiensi pemanfaatan sumber daya perangkat keras (CPU, GPU, dan memori) demi menjaga rendering antarmuka pengguna tetap berada di dalam *frame budget* (16,67 ms untuk 60 FPS atau 8,33 ms untuk 120 FPS). Berdasarkan penelusuran arsitektural dan analisis kode sumber pada proyek *Campus Notify*, ditemukan tiga *bottleneck* performa kritis sebelum tahapan optimasi dilakukan.

---

## 2. Rincian Temuan Masalah

### Temuan 1: Rebuild Berlebih (*Excessive Widget Rebuild*) dan Polusi Repaint pada Fitur Percakapan AI
* **Nama File:** `lib/features/ai_chat/presentation/pages/chat_screen.dart`
* **Lokasi / Baris:** 
  * Baris 140: Deklarasi `final chatState = ref.watch(chatNotifierProvider);` pada root method `build()`.
  * Baris 183: Pemanggilan `_buildInputBar(chatState.isLoading)`.
  * Baris 342: Pemanggilan `CircularProgressIndicator` di dalam `_buildLoadingBubble()` tanpa batas repaint.
* **Analisis Bottleneck Performa secara Teoritis:**
  * **UI Thread (Dart VM):**  
    Pemanggilan `ref.watch(chatNotifierProvider)` tanpa filter seleksi (*granular selection*) menyebabkan seluruh *widget tree*—termasuk `Scaffold`, `AppBar`, kolom utama, dan seluruh daftar riwayat percakapan—di-rebuild setiap kali terjadi perubahan state sekecil apa pun. Sebagai contoh, saat status `isLoading` berubah dari `false` ke `true`, atau ketika ada pembaruan daftar pesan, seluruh layar dievaluasi ulang. Eksekusi metode `build()` yang tidak perlu memakan siklus komputasi UI Thread dan memicu pembuatan objek *Widget* sementara secara berlebihan, mempercepat tekanan *Garbage Collection* (GC).
  * **Raster Thread (GPU):**  
    Komponen animasi `CircularProgressIndicator` berputar secara terus-menerus pada frekuensi 60 frame per detik. Tanpa adanya pemisahan layer melalui `RepaintBoundary`, engine rendering Flutter menandai render object induk beserta elemen tetangga sebagai *dirty repaint*. Akibatnya, GPU (Raster Thread) dipaksa menggambar ulang (*re-rasterize*) teks dan gelembung chat statis di sekitarnya pada setiap frame animasi, memicu pemborosan daya baterai dan potensi *jank* (frame drop).

---

### Temuan 2: Tekanan Memori Grafis (*Heap/Raster Cache Blowup*) akibat Gambar Resolusi Tinggi Tanpa Pembatasan Ukuran Decode
* **Nama File:** `lib/features/announcements/presentation/widgets/announcement_tile.dart` dan `lib/features/announcements/presentation/pages/announcement_page.dart`
* **Lokasi / Baris:** Implementasi visual awal pada kartu pengumuman kampus dan halaman rincian.
* **Analisis Bottleneck Performa secara Teoritis:**
  * **Konsumsi Memori (RAM & Heap):**  
    Saat aplikasi memuat berkas gambar jaringan (misalnya poster kegiatan akademik dari CDN/URL eksternal dengan resolusi asli $3840 \times 2160$ atau $4000 \times 3000$ piksel), Flutter secara *default* akan men-decode seluruh representasi piksel ke dalam memori bitmap mentah terkompresi (format 32-bit ARGB_8888). Satu gambar beresolusi $4000 \times 3000$ membutuhkan ruang memori:
    $$\text{Ukuran RAM} = 4000 \times 3000 \times 4\text{ byte} \approx 48\text{ MB}$$
    Padahal dimensi tampilan pada *list tile* hanya $48 \times 48$ piksel fisik di layar. Memuat 10 gambar pada daftar pengumuman berisiko mengonsumsi ratusan megabyte RAM seketika, yang memicu pembersihan agresif oleh sistem operasi (*low-memory killer*) hingga menyebabkan *crash* (OOM).
  * **Raster Thread (GPU Jank):**  
    Proses dekompresi data citra biner JPEG/PNG berskala jutaan piksel menjadi matriks piksel mentah membebani *Raster Thread*. Jika proses decoding terjadi saat pengguna melakukan *fast scrolling*, *Raster Thread* akan terblokir melampaui toleransi 16,67 ms, menghasilkan patah-patah visual (*scroll stuttering*).

---

### Temuan 3: I/O Disk Berulang (*Redundant Storage I/O*) pada Lapisan Database Lokal
* **Nama File:** `lib/features/notes/data/repositories/note_repository_impl.dart`
* **Lokasi / Baris:** Baris 14–23 (Metode `fetchNotes()`)
* **Analisis Bottleneck Performa secara Teoritis:**
  * **Latensi UI Thread & I/O Thread Pool:**  
    Implementasi awal memanggil `db.query('notes', orderBy: 'updated_at DESC')` ke database SQLite pada setiap kali repositori diakses, misalnya saat pengguna berpindah tab dari pengumuman ke catatan, atau saat widget penyedia (*provider*) di-rebuild.
  * Operasi pembacaan media penyimpanan fisik (*disk storage*) memiliki *overhead* latensi kontekstual berkisar 2–10 ms tergantung kecepatan memori flash perangkat. Ketiadaan mekanisme *in-memory cache* (seperti pola *Stale-While-Revalidate*) membuat aplikasi membuang siklus I/O sistem operasi secara sia-sia untuk data statis yang belum mengalami mutasi, memicu status *loading indicator* singkat yang menurunkan kenyamanan pengalaman pengguna (*UX friction*).

---

## 3. Kesimpulan

Ketiga temuan di atas mengonfirmasi bahwa kendala performa pada aplikasi mobile modern jarang disebabkan oleh keterbatasan bahasa pemrograman Dart itu sendiri, melainkan oleh strategi pengelolaan *lifecycle widget*, pemanfaatan cache memori grafis, dan efisiensi komunikasi layer data. Solusi perbaikan harus diarahkan pada:
1. Isolasi *rebuild scope* dengan `select` dan widget splitting.
2. Isolasi *rasterization* animasi berulang menggunakan `RepaintBoundary`.
3. Penerapan `CachedNetworkImage` disertai pembatasan `memCacheWidth` & `memCacheHeight`.
4. Implementasi *in-memory caching* pada *repository layer*.
