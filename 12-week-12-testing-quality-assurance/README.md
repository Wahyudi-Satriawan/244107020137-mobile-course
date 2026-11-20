# Modul 11 — Optimasi Performa Aplikasi Mobile (Campus Notify)

---

## 👤 Identitas Mahasiswa

| Atribut | Keterangan |
|:---|:---|
| **Nama** | Wahyudi Satriawan Hamid |
| **NIM** | 244107020137 |
| **Proyek** | Campus Notify — Optimasi Performa (Week 11) |
| **Mata Kuliah** | Pemrograman Mobile Semester 5 |
| **Repositori** | [244107020137-mobile-course](https://github.com/Wahyudi-Satriawan/244107020137-mobile-course) |
| **Direktori Modul** | `11-week-11-performance-optimization` |

---

## 🚀 Ringkasan Pelaksanaan Modul 11

Pada modul praktikum ini, aplikasi **Campus Notify** dioptimalkan secara komprehensif untuk meningkatkan efisiensi komputasi pada **UI Thread**, mengurangi beban *rendering* pada **Raster Thread**, serta menekan konsumsi **Memory (RAM/Heap)**. Seluruh optimasi diterapkan tanpa merusak kaidah *Clean Architecture* dan manajemen state Riverpod.

### Teknik Optimasi yang Diterapkan:

1. **Pengurangan Widget Rebuild & Isolasi Paint (`ChatScreen`)**:
   * Menghilangkan pembacaan *state* global `ref.watch(chatNotifierProvider)` di tingkat *root build*.
   * Menggunakan selektor granular `ref.watch(chatNotifierProvider.select((s) => s.isLoading))` dan `ref.watch(chatNotifierProvider.select((s) => s.messages))` agar *rebuild* hanya terjadi pada komponen yang mengalami perubahan nilai.
   * Mengekstrak sub-tree antarmuka ke widget kelas terpisah (`_ChatInputBar`, `_ChatMessagesView`, `ChatBubbleItem`, dan `EmptyChatView`) serta menerapkan constructor `const`.
   * Membungkus komponen animasi pemuatan berputar (`CircularProgressIndicator`) dengan **`RepaintBoundary`** untuk mengisolasi *dirty repaint* 60 FPS agar tidak memicu komposit ulang pada layer obrolan di sekitarnya.

2. **Optimasi Memori Grafis & Disk Caching (`CachedNetworkImage`)**:
   * Mengintegrasikan pustaka `cached_network_image` pada [pubspec.yaml](pubspec.yaml).
   * Menerapkan parameter pembatas dimensi decode: `memCacheWidth: 120` dan `memCacheHeight: 120` pada thumbnail [announcement_tile.dart](lib/features/announcements/presentation/widgets/announcement_tile.dart) serta `memCacheWidth: 600` pada banner [announcement_page.dart](lib/features/announcements/presentation/pages/announcement_page.dart).
   * Mencegah pemborosan memori grafis hingga >99% per gambar (menghindari decoding gambar mentah $4000 \times 3000$ yang memakan ~48 MB RAM) dan mengeliminasi jank saat scrolling.

3. **Optimasi List Rendering & Lazy Loading (`NotesList` & `HomePage`)**:
   * Memastikan seluruh daftar item dirender menggunakan `ListView.builder` dengan konfigurasi `addAutomaticKeepAlives: false` dan `addRepaintBoundaries: true`.
   * Mengekstrak `NoteItemTile` menjadi widget mandiri untuk memfasilitasi *widget reuse* dan pembuangan instans di luar *viewport*.

4. **In-Memory Caching Repositori (Stale-While-Revalidate di `NoteRepositoryImpl`)**:
   * Menambahkan *in-memory cache* dengan durasi kedaluwarsa 30 detik pada layer repositori catatan.
   * Menghilangkan operasi I/O berulang ke database SQLite saat navigasi tab atau *rebuild*, mentransformasikan pencarian disk menjadi pembacaan referensi RAM berkecepatan $\mathcal{O}(1)$.

---

## 📑 Dokumen Hasil Analisis dan Laporan

Laporan akademis dan analisis temuan performa telah disusun secara lengkap pada folder `docs/`:
1. 📄 **[Laporan Temuan Bottleneck (docs/performance-findings.md)](docs/performance-findings.md)**: Analisis teoritis 3 masalah performa (UI Thread, Raster Thread, Memory) sebelum optimasi.
2. 📄 **[Laporan Utama Praktikum (docs/performance-report.md)](docs/performance-report.md)**: Draf laporan praktikum resmi berisi baseline metrics, panduan screenshot Flame Chart, penjelasan teknis, dan jawaban refleksi pembelajaran.

---

## 🧪 Bukti Validasi Mesin Hijau

### 1. Analisis Statis (`flutter analyze`)
```bash
$ flutter analyze
Analyzing 11-week-11-performance-optimization...
No issues found! (ran in 98.1s)
```

### 2. Pengujian Unit (`flutter test`)
```bash
$ flutter test
00:00 +0: loading test/ai_service_test.dart
...
00:00 +21: All tests passed!
```

### 3. Kompilasi Profile Mode (`flutter build apk --profile`)
```bash
$ flutter build apk --profile
Running Gradle task 'assembleProfile'...
√ Built build\app\outputs\flutter-apk\app-profile.apk (71.2MB)
```

---

## 📂 Struktur Berkas Modul 11

```text
11-week-11-performance-optimization/
├── docs/
│   ├── performance-findings.md      # Laporan analisis 3 bottleneck awal
│   └── performance-report.md        # Laporan utama praktikum & refleksi
├── lib/
│   ├── ai/
│   ├── core/
│   ├── features/
│   │   ├── ai_chat/
│   │   │   └── presentation/pages/chat_screen.dart   # Dioptimasi: select, widget splitting, RepaintBoundary
│   │   ├── announcements/
│   │   │   ├── domain/entities/announcement.dart     # Ditambahkan properti imageUrl
│   │   │   ├── presentation/pages/home_page.dart     # Dioptimasi: ListView.builder
│   │   │   ├── presentation/pages/announcement_page.dart # Dioptimasi: CachedNetworkImage (memCacheWidth: 600)
│   │   │   └── presentation/widgets/announcement_tile.dart # Dioptimasi: CachedNetworkImage (memCacheWidth: 120)
│   │   ├── auth/
│   │   └── notes/
│   │       ├── data/repositories/note_repository_impl.dart # Dioptimasi: in-memory cache Stale-While-Revalidate
│   │       └── presentation/widgets/notes_list.dart       # Dioptimasi: NoteItemTile & lazy properties
│   ├── main.dart
│   └── routes.dart
├── screenshots/
│   ├── before-profile.png           # Tempatkan screenshot DevTools Flame Chart sebelum optimasi
│   └── after-profile.png            # Tempatkan screenshot DevTools Flame Chart setelah optimasi
├── test/
├── pubspec.yaml                     # Ditambahkan cached_network_image: ^3.4.1
└── README.md
```
