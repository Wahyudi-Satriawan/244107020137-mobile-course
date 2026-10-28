# Catatan Praktikum Week 9: AI-Assisted Development (Fitur Search Notes)

Dokumentasi ini nyatet proses pengerjaan fitur pencarian catatan (*Search Notes by Title*) dan tampilan status kosong (*Empty State*) pada aplikasi catatan berbasis Clean Architecture dan Riverpod 3.x, dibantu AI coding assistant.

---

## 1. Prompt Inti

Prompt utama yang saya lempar ke AI waktu mulai ngerjain tugas ini:

> **Prompt Inti:**  
> "Tolong buatkan fitur pencarian catatan berdasarkan judul dengan clean architecture dan implementasikan UI empty state. Arsitektur harus feature-first Clean Architecture (Presentation -> Domain <- Data), state management pakai Riverpod 3.x, dan penyimpanan SQLite. Logika filter wajib ditaruh di pure Domain Use Case (bukan di widget UI atau Notifier), UI hanya boleh mengamati state dari Notifier, dan hasil kode harus lolos `flutter analyze` 0 warnings serta ada unit test untuk logika pencarian."

Detail instruksi pelengkap yang saya sertakan ke AI:
```text
[Role]: Senior Flutter Developer
[Task]: Implementasi fitur "Search Notes by Title" + UI "Empty State"
[Constraints]:
1. Jangan acak-acak arsitektur yang sudah ada.
2. Logika filtering search WAJIB murni di Domain Use Case (SearchNotesUseCase), jangan numpang di widget UI ataupun dicampur aduk di UI Notifier.
3. Widget UI hanya bertugas observe state dari Riverpod Notifier.
4. Kode wajib 0 warnings di `flutter analyze`.
5. Bikin unit test di test/search_filter_test.dart (minimal skenario hasLength dan isEmpty).
```

---

## 2. Tabel Terima/Tolak Saran AI

Selama sesi tanya jawab dan ngoding bareng AI, ada beberapa saran yang saya saring dulu sebelum dipakai:

| No | Saran dari AI | Keputusan | Catatan / Alasan Mahasiswa |
|:--:|---|:---:|---|
| 1 | AI menyarankan untuk menaruh logika filter (search) langsung di dalam Notifier UI. | ❌ **Ditolak** | Saya menolak saran ini dan memindahkan logika tersebut menjadi `SearchNotesUseCase` di layer Domain murni agar arsitektur tetap bersih. Kalau ditaruh di Notifier apalagi widget, prinsip Clean Architecture jadi rusak dan use case-nya nggak bisa diuji secara terisolasi tanpa framework. |
| 2 | AI membuatkan struktur test yang rapi untuk skenario `hasLength()` dan `isEmpty`. | ✅ **Diterima** | Saya menerima ini karena kodenya terstruktur dengan baik. Pengelompokan kasus ujinya jelas (query kosong, whitespace, case-insensitive, partial match, sampai keyword yang nggak ketemu sama sekali). |
| 3 | AI sempat menyarankan bikin query `LIKE %keyword%` langsung lewat method di data source SQLite tiap kali user ngetik satu karakter. | ❌ **Ditolak** | Untuk skop catatan lokal yang ukurannya relatif kecil, bolak-balik query SQLite per keystroke malah bikin disk I/O boros dan arsitektur lebih rumit. Lebih pas kalau data yang udah di-*fetch* di memori difilter lewat Domain Use Case yang *pure Dart*. |
| 4 | AI menyarankan pemisahan widget `EmptyStateView` ke dalam `core/widgets/empty_state_view.dart`. | ✅ **Diterima** | Komponen UI untuk state kosong ini jadi *reusable*, parameternya fleksibel (bisa ganti icon dan pesan teks), sehingga `NotesPage` tetap ringkas dan fokus menyusun layout utama. |

---

## 3. Refleksi Pengerjaan

### Halusinasi AI yang Ditemukan
Halusinasi paling nyata yang sempat muncul adalah waktu AI menyarankan pemakaian `StateProvider` bawaan Riverpod lama buat nampung teks pencarian:
```dart
// Saran awal AI yang bikin error:
final searchQueryProvider = StateProvider<String>((ref) => '');
```
Padahal di project ini kita pakai `flutter_riverpod` versi 3.x, di mana `StateProvider` sudah resmi dihapus (*deprecated / removed*). Efeknya, waktu pertama kali di-analyze langsung muncul error `The function 'StateProvider' isn't defined`. Dari situ saya harus refactor manual ke pola Riverpod 3.x yang benar memakai subclass `Notifier<String>`:
```dart
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) => state = query;
  void clear() => state = '';
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);
```
Pelajaran pentingnya: AI sering kali masih memakai ingatan sintaks library versi lama, jadi kita sebagai developer tetap wajib paham breaking changes di library yang kita pakai.

### Prompt Mana yang Paling Membantu
Prompt yang paling ngebantu adalah saat saya memberikan batasan layer (*layer boundary constraints*) secara eksplisit:
> *"The search/filter logic MUST be placed in a pure Domain Use Case, NOT in the UI widget or UI Notifier. The UI widget must only observe state from the Notifier."*

Waktu instruksi arsitekturnya dikunci dari awal, AI nggak ngasih kode jalan pintas (seperti filter instan di `setState` atau `.where` langsung di dalam method `build` widget). AI langsung fokus men-generate class `SearchNotesUseCase` murni tanpa import `package:flutter`.

### Keputusan Paling Sulit
Keputusan paling menantang ada di pembagian peran antara `SearchNotesUseCase` dengan Riverpod provider:
- Apakah use case harus memegang instance repository dan memanggil database lagi?
- Atau use case cukup menerima `List<Note>` yang sudah ada di memory lalu mengembalikan list hasil filter?

Akhirnya saya putuskan opsi kedua: `SearchNotesUseCase` dibuat murni bertindak sebagai fungsi transformasi data (`allNotes` + `query` -> `filteredNotes`). Alasan utamanya adalah testability: unit test bisa dijalankan super cepat tanpa perlu mock SQLite database atau mock asynchronous stream, dan presentation layer tetap rapi menggabungkan `allNotesProvider` dengan `searchQueryProvider`.
