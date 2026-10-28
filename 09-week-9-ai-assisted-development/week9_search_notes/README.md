# week9_search_notes — Fitur Pencarian Catatan (Week 9)

Proyek Flutter ini merupakan bagian dari tugas Week 9: *AI-Assisted Development*.

Untuk dokumentasi lengkap, panduan arsitektur, dan log interaksi AI, silakan cek:
- File dokumentasi utama: [../README.md](../README.md)
- Log AI dan refleksi teknis: [../docs/ai-log.md](../docs/ai-log.md)

### Ringkasan Cepat
- **Fitur**: Pencarian Catatan (*Search Notes by Title*) + Tampilan Kosong (*Empty State*)
- **Arsitektur**: Feature-First Clean Architecture (`Domain` <- `Data`, `Domain` <- `Presentation`)
- **State Management**: `flutter_riverpod: ^3.4.3` (`NotifierProvider`, `Notifier`)
- **Database**: SQLite (`sqflite`)
- **Status Analisis**: ✅ `flutter analyze` (0 issues)
- **Status Uji**: ✅ `flutter test test/search_filter_test.dart` (Passed)
