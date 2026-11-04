# Modul 10: Integrasi Fitur AI (Campus Notify Chat Assistant)

Laporan pengerjaan Modul 10: Integrasi Fitur AI pada proyek aplikasi **Campus Notify** menggunakan Google Gemini REST API, Riverpod 3.x, dan `flutter_secure_storage`.

---

## 👤 Identitas Mahasiswa

| Informasi | Keterangan |
| :--- | :--- |
| **Nama Mahasiswa** | Wahyudi Satriawan Hamid |
| **NIM** | 244107020137 |
| **Mata Kuliah** | Pemrograman Mobile |
| **Semester / Kelas** | 5 |
| **Modul** | Modul 10 - Integrasi Fitur AI |
| **Repository** | [244107020137-mobile-course](https://github.com/Wahyudi-Satriawan/244107020137-mobile-course) |
| **Branch Utama** | `develop` |
| **Branch Fitur** | `feat/ai-chat-integration` |

---

## 🚀 Fitur yang Dikembangkan: Campus AI Chat Assistant

Pada modul ini, aplikasi `campus_notify` dilengkapi dengan asisten cerdas berbasis Google Gemini yang dirancang sesuai prinsip *Clean Architecture* dan keamanan data seluler:

1. **AI Service Layer (`lib/ai/ai_service.dart`)**:
   - Memanggil endpoint Gemini REST API (`generateContent`) via HTTP POST.
   - Menggunakan `flutter_secure_storage` untuk menyimpan dan membaca Gemini API Key secara aman di keychain/keystore OS, sehingga kunci **tidak pernah di-hardcode** dalam basis kode.
   - Dilengkapi *System Prompt* ketat: *"Kamu adalah asisten kampus ramah untuk aplikasi Campus Notify. Jawab singkat dalam Bahasa Indonesia, maksimal 2 kalimat. Jangan pernah meminta atau menyimpan data pribadi."*
   - Penanganan error komprehensif menggunakan `try-catch` dengan melempar `AiServiceException` untuk kondisi offline, timeout, kegagalan jaringan, atau status non-200.

2. **Presentation & Fallback UI (`lib/features/ai_chat/`)**:
   - `chat_screen.dart`: Antarmuka percakapan interaktif dengan pemisahan gelembung pesan user (kanan) dan respons AI (kiri).
   - Tampilan indikator *loading* (`CircularProgressIndicator`) saat menunggu jawaban AI.
   - Dialog pengaturan API Key via tombol kunci di AppBar untuk mempermudah konfigurasi pengguna/penguji secara mandiri.
   - **Mekanisme Fallback Ramah Pengguna**: Menangkap kegagalan jaringan atau limit kuota dari `ChatNotifier`, kemudian memunculkan `AlertDialog` ("Layanan AI Sibuk: Coba lagi nanti atau gunakan mode offline").

3. **Routing GoRouter**:
   - Rute `/chat` dan `/ai-chat` ditambahkan ke `lib/routes.dart`.
   - Tombol akses instan ditaruh di AppBar `HomePage` dan `FloatingActionButton` ("Tanya AI").

---

## 🛡️ Tabel Risiko dan Mitigasi (Privasi & Biaya)

Sesuai materi Modul 10 slide 5, berikut adalah mitigasi yang diimplementasikan:

| Risiko | Dampak | Mitigasi yang Diimplementasikan |
| :--- | :--- | :--- |
| **Bocor data pribadi pengguna** | Pelanggaran privasi jika NIK, password, atau nomor telepon terkirim ke LLM cloud. | 1. *System Prompt Guardrail*: Instruksi eksplisit melarang meminta/menyimpan data pribadi.<br>2. Tidak pernah mengirim token otentikasi maupun data identitas pribadi ke payload prompt.<br>3. Penyimpanan API Key terenkripsi di `flutter_secure_storage`. |
| **Biaya API melonjak** | Token usage tak terkendali akibat prompt terlalu panjang atau looping request. | 1. Pembatasan respons maksimal 2 kalimat pada *System Prompt*.<br>2. Tombol kirim dinonaktifkan (`disabled`) saat state `isLoading`.<br>3. Pemilihan model efisien (`gemini-1.5-flash`). |
| **API Error / Service Down** | Pengguna mengalami aplikasi crash (*freeze*) atau layar putih saat jaringan mati. | Menerapkan `try-catch` di service dan notifier. Memunculkan `AlertDialog` fallback yang ramah ("Layanan AI Sibuk, silakan coba lagi atau gunakan mode offline"). |
| **Respons AI Halusinasi / Tidak Relevan** | Jawaban AI menyimpang dari konteks perkuliahan. | Menetapkan *Persona* dan *Batas Domain* kampus secara jelas pada *System Instruction*. |

---

## 💡 Refleksi Modul 10

1. **Fitur AI mana yang Anda integrasikan dan mengapa?**
   - **Jawaban**: Fitur yang diintegrasikan adalah **Chat Assistant (Gemini)**. Fitur ini sangat relevan untuk aplikasi `Campus Notify` karena mahasiswa membutuhkan sarana cepat dan interaktif untuk bertanya mengenai perkuliahan, memahami pengumuman, dan mendapatkan bantuan belajar tanpa harus menelusuri menu secara manual.

2. **Bagaimana Anda melindungi privasi pengguna saat menggunakan AI API?**
   - **Jawaban**: 
     - API key tidak pernah dimasukkan ke dalam source code, melainkan dibaca dinamis melalui `flutter_secure_storage`.
     - *System Prompt* dipasangi pembatas (*guardrail*) yang melarang model meminta atau mencatat data personal.
     - Payload yang dikirim hanya teks pertanyaan murni yang diinput pengguna tanpa menyertakan metadata sensitif seperti token auth, email, atau device ID.

3. **Fallback apa yang Anda sediakan jika layanan AI error?**
   - **Jawaban**: Jika API mengembalikan error (misalnya API key kosong, kuota habis, atau status non-200) atau perangkat dalam kondisi offline, sistem menangkapnya dengan `try-catch` dan memicu `AlertDialog` fallback bertuliskan *"Layanan AI Sibuk - Coba lagi nanti atau gunakan mode offline."* Dengan cara ini, UI aplikasi tidak mengalami crash dan pengguna diberi opsi alternatif.

4. **Satu hal yang Anda pelajari tentang UX fitur AI di mobile?**
   - **Jawaban**: Respon model bahasa (LLM) memerlukan latensi jaringan (*network latency*), sehingga *feedback visual* seperti `CircularProgressIndicator` atau animasi "Asisten sedang mengetik..." sangat krusial agar pengguna merasa yakin bahwa pesan mereka sedang diproses dan aplikasi tidak membeku (*freeze*).

---

## 🧪 Bukti Mesin Hijau (Testing & Analysis)

### 1. Static Analysis (`flutter analyze`)
```bash
$ cd 07-week-7-clean-architecture/campus_notify
$ flutter analyze
Analyzing campus_notify...
No issues found! (ran in 4.2s)
```

```bash
$ flutter analyze
Analyzing 244107020137-mobile-course...
No issues found! (ran in 75.4s)
```

### 2. Unit Testing (`flutter test`)
Pengujian mencakup unit test komprehensif pada `AiService` dan `ChatNotifier` dengan teknik mocking `http.Client` dan `FlutterSecureStorage`:
- Skenario validasi: Penolakan pertanyaan kosong.
- Skenario otentikasi: Error spesifik saat API Key belum disetel.
- Skenario sukses: Parsing respons JSON Gemini (status 200).
- Skenario error API: Penanganan status 500 / 503 dengan pesan ramah.
- Skenario offline: Penanganan kegagalan koneksi socket/klien HTTP.
- Skenario persistensi: Simpan dan baca kunci di Secure Storage.
- Skenario integrasi UI Notifier & Fallback: Verifikasi state update dan pengisian `errorMessage` untuk memicu `AlertDialog`.

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
Semua 15 pengujian di root workspace dan 21 pengujian di `campus_notify` **100% HIJAU (PASS)**.
