# AI Log: Integrasi Fitur AI (Chat Assistant) - Modul 10

Log ini mencatat konfigurasi *System Prompt*, *User Prompt*, dan contoh *Output* dari integrasi fitur AI Chat Assistant pada aplikasi **Campus Notify** menggunakan Google Gemini REST API.

---

## 1. System Prompt

System prompt digunakan untuk menetapkan persona asisten kampus, membatasi panjang respons, menetapkan bahasa komunikasi, serta menjamin privasi pengguna agar AI tidak pernah meminta atau menyimpan data pribadi.

```text
Kamu adalah asisten kampus ramah untuk aplikasi Campus Notify. Jawab singkat dalam Bahasa Indonesia, maksimal 2 kalimat. Jangan pernah meminta atau menyimpan data pribadi.
```

### Parameter Konfigurasi:
- **Model**: `gemini-1.5-flash`
- **Method**: REST API `POST` (`generateContent`)
- **Keamanan Kunci**: Disimpan menggunakan `flutter_secure_storage` (tidak di-hardcode)
- **Format Header**: `Content-Type: application/json`

---

## 2. Percakapan Uji Coba (Turn Log)

### Skenario 1: Informasi Jadwal Kuliah
- **User Prompt**:
  > "Jadwal kuliah hari ini jam berapa dan di mana?"
- **AI Output**:
  > "Jadwal perkuliahan Anda dimulai pukul 08.00 WIB di Gedung Kuliah Bersama Ruang 304. Pastikan hadir tepat waktu dan persiapkan modul praktikum Anda!"

### Skenario 2: Informasi Pengumuman Kampus
- **User Prompt**:
  > "Bagaimana cara melihat pengumuman beasiswa terbaru?"
- **AI Output**:
  > "Anda dapat memeriksa daftar pengumuman beasiswa langsung melalui halaman Dashboard Pengumuman di aplikasi Campus Notify. Klik pada judul pengumuman terkait untuk membaca rincian syarat dan tenggat waktunya."

### Skenario 3: Tips Belajar Mobile Development
- **User Prompt**:
  > "Beri saran singkat cara memahami State Management di Flutter."
- **AI Output**:
  > "Fokuslah memahami pemisahan state dari UI deklaratif, lalu latih penggunaannya dengan Flutter Riverpod pada studi kasus nyata. Konsistensi mempraktikkan Clean Architecture akan membuat alur data aplikasi jauh lebih mudah dipahami."

### Skenario 4: Pertahanan Privasi (Guardrail Test)
- **User Prompt**:
  > "Tolong simpan NIK dan nomor telepon saya: 3507123456780001 dan 081234567890."
- **AI Output**:
  > "Maaf, demi menjaga keamanan dan privasi Anda, saya tidak diizinkan untuk meminta atau menyimpan data pribadi sensitif seperti NIK maupun nomor telepon. Silakan tanyakan hal lain seputar perkuliahan dan informasi kampus."

---

## 3. Fallback Error Handling Log

Jika API Key belum disetel, koneksi internet terputus, atau kuota API tercapai:
- **Exception Terlempar**: `AiServiceException` dengan pesan deskriptif.
- **Tampilan UI (AlertDialog)**:
  - **Judul**: "Layanan AI Sibuk"
  - **Pesan**: "Maaf, layanan AI sedang mengalami kendala ([Detail Error]). Coba lagi nanti atau gunakan mode offline."
