# Laporan Teknis Pipeline CI/CD & Analisis Evaluasi (Minggu 13)

**Modul:** #13 | CI/CD dan Otomatisasi  
**Aplikasi:** `campus_notify`  
**Penyusun:** Wahyudi Satriawan Hamid (NIM: 244107020137)  
**Program Studi:** D-IV Teknik Informatika — Politeknik Negeri Malang  
**File Workflow:** [`.github/workflows/flutter-ci.yml`](../../.github/workflows/flutter-ci.yml)

---

## 1. Post-Mortem Insiden Teknis: SDK Version Drift (Run #1 vs Run #2)

### A. Ringkasan Insiden (Executive Summary)
Pada eksekusi pipeline perdana (**Run #1**, commit `2dd85bc`), pipeline GitHub Actions mengalami kegagalan pada tahap pengujian statis (*Static Code Analysis*), padahal seluruh rangkaian pengujian di mesin pengembangan lokal lulus 100% tanpa kendala (*0 issues*). Investigasi menemukan bahwa ketidakcocokan versi Flutter SDK (*SDK Version Drift*) antara lingkungan lokal dan runner CI berbasis cloud menyebabkan munculnya 13 *informational diagnostics* baru yang memicu penghentian build karena konfigurasi flag `--fatal-infos`.

### B. Kronologi Insiden (Timeline)
* **20:43:16 UTC+7 (Commit `3e7388f`):** Baseline Minggu 13 disiapkan dan diverifikasi lokal (`flutter analyze --fatal-infos` lulus 0 issues).
* **21:22:31 UTC+7 (Commit `2dd85bc`):** Workflow `.github/workflows/flutter-ci.yml` ditambahkan dengan konfigurasi `subosito/flutter-action@v2` menggunakan `channel: stable` tanpa menyertakan nomor versi eksplisit.
* **Run #1 Terpicu:** Runner `ubuntu-latest` mengeksekusi workflow selama 1 menit 8 detik.
* **Titik Kegagalan:** Pada detik ke-11 dari step `Analyze code` (`flutter analyze --fatal-infos`), proses terhenti dengan exit code 1.

### C. Analisis Akar Masalah (Root Cause Analysis - RCA)
Penyebab utama insiden dianalisis melalui metode 5-Whys:
1. **Mengapa workflow Run #1 gagal?**  
   Perintah `flutter analyze --fatal-infos` menghasilkan 13 temuan isu (*issues*) dan keluar dengan exit code 1.
2. **Mengapa muncul 13 isu analisis?**  
   Pustaka `package:flutter/material.dart` terdeteksi usang (*deprecated*) pada 13 file dengan pesan:  
   `Info • 'package:flutter/material.dart' is deprecated and shouldn't be used. Use package:material_ui/material_ui.dart instead. This feature was deprecated after v3.47.0-0.0.pre.`
3. **Mengapa isu tersebut tidak terdeteksi saat pengujian lokal?**  
   Lingkungan lokal menggunakan Flutter SDK versi **3.47.1**, sedangkan runner GitHub Actions menarik rilis kanal `stable` terbaru yang lebih tinggi dari versi lokal.
4. **Mengapa runner CI mengunduh versi yang berbeda?**  
   Konfigurasi `subosito/flutter-action@v2` hanya menetapkan parameter `channel: stable` tanpa parameter `flutter-version`. Hal ini memberikan fleksibilitas dinamis (*floating version*) yang justru melanggar prinsip determinisme build.
5. **Akar Masalah Fundamental:**  
   Ketiadaan **Version Pinning** pada SDK Flutter di runner CI, diperparah dengan flag `--fatal-infos` yang memperlakukan level diagnostik `info` sebagai kegagalan kritis (*hard blocker*).

### D. Tindakan Korektif & Validasi (Corrective Action & Resolution)
Sebagai engineer QA & DevOps senior, kualitas *quality gate* tidak boleh dilemahkan (dilarang keras menghapus `--fatal-infos` atau menonaktifkan aturan linter). Langkah mitigasi dilakukan melalui standardisasi lingkungan:
1. Memeriksa versi Flutter lokal secara presisi via `flutter --version`: teridentifikasi `Flutter 3.47.1` (tools Dart 3.13.1).
2. Memperbarui `.github/workflows/flutter-ci.yml` (Commit `25f7724`):
   ```yaml
   - name: Set up Java JDK 17
     uses: actions/setup-java@v5
     with:
       distribution: 'temurin'
       java-version: '17'

   - name: Set up Flutter SDK
     uses: subosito/flutter-action@v2
     with:
       flutter-version: '3.47.1'
       channel: 'stable'
       cache: true
   ```
3. Meng-upgrade `actions/setup-java@v4` ke `@v5` guna menghilangkan deprecation warning bawaan runner GitHub Actions.
4. **Hasil Validasi (Run #2):** Seluruh step Quality Gate lulus 100% hijau, waktu eksekusi `flutter analyze` hanya 12 detik dengan 0 issues, dan build APK/AAB berhasil diproduksi.

---

## 2. Analisis Efisiensi Waktu Build Pipeline (Performance Metrics)

Berdasarkan data telemetri aktual dari eksekusi **Run #2** (Total Durasi Job: 6m 23s), berikut adalah dekomposisi waktu per tahapan:

| Tahapan Pipeline | Durasi Aktual | Proporsi Waktu (%) | Karakteristik Beban Kerja | Potensi Optimasi Lanjutan |
| :--- | :---: | :---: | :--- | :--- |
| **Set up job & Checkout** | 3s | 0.8% | I/O Git fetch | Shallow checkout (`fetch-depth: 1`) sudah optimal. |
| **Set up Java JDK 17** | 0s | 0.0% | Cache hit sistem | Sudah menggunakan cache internal runner. |
| **Set up Flutter SDK (3.47.1)** | 29s | 7.6% | Jaringan / Cache restore | Menggunakan cache Flutter SDK bawaan action. |
| **Install Dependencies** | 7s | 1.8% | Resolusi pub dependencies | Sangat cepat; memanfaatkan `pubspec.lock`. |
| **Check Formatting** | 1s | 0.3% | CPU bound (AST parsing) | Lolos instan karena format lokal sudah bersih. |
| **Analyze Code** | 12s | 3.1% | CPU bound (Dart analyzer) | Analisis menyeluruh seluruh modul & file test. |
| **Unit & Widget Tests** | 14s | 3.7% | CPU/RAM (Flutter tester) | Eksekusi 42 skenario pengujian & generasi lcov. |
| **Prepare Firebase Config** | 0s | 0.0% | Shell script eksekusi | Injeksi JSON instan. |
| **Build Release APK** | **4m 30s** | **70.5%** | **Kompilasi berat (Gradle/R8/DEX)** | **Bottleneck utama pipeline.** |
| **Build Release AAB** | **26s** | **6.8%** | Kompilasi incremental | **Dramatis lebih cepat (efisiensi caching Gradle).** |
| **Upload Artifacts** | 3s | 0.8% | I/O Jaringan | Kompresi dan upload 102.8 MB artefak. |
| **Post steps & Cleanup** | 15s | 3.9% | Housekeeping runner | Standar cleanup GitHub Actions. |
| **Total Job Duration** | **6m 23s** | **100.0%** | **End-to-End Delivery** | Target SLA rilis CI terpenuhi (< 10 menit). |

### Temuan Analisis Kinerja:
1. **Bottleneck Utama:** Tahap `Build Release APK` menghabiskan 4 menit 30 detik (70.5% dari seluruh durasi). Hal ini wajar karena Gradle harus melakukan kompilasi Java/Kotlin awal, desugaring dependensi pihak ketiga (`firebase_core`, `sqflite`), dan minifikasi kode rilis melalui R8.
2. **Efisiensi Caching Gradle:** Tahap `Build Release AAB` hanya memakan waktu 26 detik (penurunan waktu sebesar **90.4%** dibandingkan build APK). Hal ini membuktikan bahwa *incremental compilation* dan *task output caching* Gradle bekerja secara efektif pada runner Linux.

---

## 3. Daftar Periksa Kesiapan Rilis Produksi & Keamanan (Readiness & Security Checklist)

Sebelum aplikasi `campus_notify` dipublikasikan ke Google Play Store atau lingkungan pengguna akhir, tim engineering wajib memenuhi matriks kesiapan berikut:

| Kategori | Item Pemeriksaan | Status Saat Ini | Tindakan yang Harus Dilakukan Sebelum Rilis Produksi |
| :--- | :--- | :---: | :--- |
| **Keamanan Kunci** | Android Release Keystore Signing | ⚠️ **Belum Siap** | `buildTypes.release` saat ini masih menggunakan `signingConfigs.getByName("debug")`. Wajib membuat keystore produksi (`upload-keystore.jks`), mengenkripsinya ke GitHub Secrets (`RELEASE_KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`), dan mengonfigurasinya di Gradle. |
| **Kredensial Firebase** | `google-services.json` Injection | ⚠️ **Sebagian** | Pipeline saat ini memiliki fallback dummy agar kompilasi lolos di runner publik. Sebelum rilis produksi, secret `GOOGLE_SERVICES_JSON_BASE64` wajib disetel di repositori dengan file konfigurasi Firebase yang valid. |
| **Manajemen Secret** | Pembatasan Nilai `--dart-define` | ✅ **Aman** | Tidak menaruh API Key privat atau secret database di dalam argumen `--dart-define` karena dapat diekstrak via reverse engineering APK/AAB. |
| **Integritas Branch** | Branch Protection Rules pada `main` | ⚠️ **Perlu Dikonfigurasi** | Menerapkan aturan GitHub: wajib pull request, wajib lolos status check `Quality Gate & Android Release Build`, dan minimal 1 peer review sebelum merge. |
| **Pemisahan Pipeline** | Pemisahan CI Pengujian vs CD Rilis | ⚠️ **Rekomendasi Arsitektur** | Saat ini build APK & AAB dieksekusi pada setiap push ke `main`. Ke depan, pipeline harus dipisah: CI (format, lint, test) berjalan pada PR, sedangkan CD (build APK/AAB, signing, deployment) hanya dipicu oleh Git Tag `v*.*.*`. |
| **Manajemen Izin** | Audit AndroidManifest Permissions | ✅ **Aman** | Izin `INTERNET`, `POST_NOTIFICATIONS`, dan `VIBRATE` telah diminimalkan sesuai kebutuhan notifikasi kampus. |
| **Runner Runtime** | Transisi Runtime Node.js 24 | ℹ️ **Catatan Pemeliharaan** | Memantau pembaruan `subosito/flutter-action` dan `actions/upload-artifact` menuju adopsi Node.js 24 untuk mengeliminasi warning transisi Node.js 20. |

---

## 4. Kesimpulan Evaluasi DevOps

Implementasi pipeline CI/CD pada Praktikum Minggu 13 berhasil membuktikan bahwa otomatisasi pengujian mampu menangkap inkonsistensi lingkungan (*version drift*) dan menjaga standar integritas kode tanpa kompromi. Dengan mengunci versi SDK pada `3.47.1` dan memvalidasi kompilasi ganda (APK dan AAB), repositori `244107020137-mobile-course` telah memiliki fondasi Continuous Integration yang tangguh, deterministik, dan siap diadopsi dalam skala tim profesional.
