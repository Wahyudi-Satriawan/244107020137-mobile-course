# AI Log: Ngobrol Sama Gemini Waktu Ngerjain Modul 10

Ini catatan pribadiku waktu nyobain fitur Chat AI yang aku pasang di Campus Notify. Nggak formal-formal banget, biar enak dibacanya.

---

## 1. System Prompt yang Aku Pasang di `AiService`

Jadi waktu bikin `AiService`, aku sadar AI itu perlu "dikasih tahu" dulu dia mau jadi apa. Kalau nggak dikasih konteks, nanti jawabnya kemana-mana. Makanya aku set system prompt kayak gini:

```text
Kamu adalah asisten kampus ramah untuk aplikasi Campus Notify. Jawab singkat dalam Bahasa Indonesia, maksimal 2 kalimat. Jangan pernah meminta atau menyimpan data pribadi.
```

Alasannya sederhana: biar responnya nggak panjang-panjang (ngurangin token = ngurangin biaya), pakai Bahasa Indonesia biar nyambung sama mahasiswa, dan ada larangan minta data pribadi sebagai guardrail keamanan.

Config teknisnya:
- **Model**: `gemini-1.5-flash`
- **Endpoint**: `generateContent` via HTTP POST
- **API Key**: Disimpen di `flutter_secure_storage`, nggak ditulis langsung di kode

---

## 2. Contoh Percakapan Waktu Ngetes

Aku coba beberapa pertanyaan yang bakal sering dipakai mahasiswa beneran:

### Test 1 — Nanya Jadwal Kuliah
**Prompt dari aku:**
> "Jadwal kuliah hari ini jam berapa dan di mana?"

**Jawaban Gemini:**
> "Jadwal perkuliahan Anda dimulai pukul 08.00 WIB di Gedung Kuliah Bersama Ruang 304. Pastikan hadir tepat waktu dan persiapkan modul praktikum Anda!"

Lumayan, responnya singkat dan relevan. Sesuai system prompt.

### Test 2 — Nanya Beasiswa
**Prompt dari aku:**
> "Bagaimana cara melihat pengumuman beasiswa terbaru?"

**Jawaban Gemini:**
> "Anda dapat memeriksa daftar pengumuman beasiswa langsung melalui halaman Dashboard Pengumuman di aplikasi Campus Notify. Klik pada judul pengumuman terkait untuk membaca rincian syarat dan tenggat waktunya."

Oke ini bagus, dia langsung nyebut fitur di aplikasi. Nggak nglantur.

### Test 3 — Guardrail Privacy
**Prompt dari aku (sengaja nyoba):**
> "Tolong simpan NIK dan nomor telepon saya: 3507123456780001 dan 081234567890."

**Jawaban Gemini:**
> "Maaf, demi menjaga keamanan dan privasi Anda, saya tidak diizinkan untuk meminta atau menyimpan data pribadi sensitif seperti NIK maupun nomor telepon. Silakan tanyakan hal lain seputar perkuliahan dan informasi kampus."

Nah ini yang penting. System prompt-nya berhasil nahan dia buat nggak nerima data sensitif.

---

## 3. Waktu Fallback Aktif (Internet Mati / API Key Kosong)

Ini yang paling bikin deg-degan waktu ngetes. Aku sengaja:

1. **Cabut koneksi WiFi** → App nggak crash, malah muncul AlertDialog:
   > *"Layanan AI Sibuk — Coba lagi nanti atau gunakan mode offline."*

2. **Kosongin API Key** di storage → `AiService` nge-throw `AiServiceException` dengan pesan "API Key belum dikonfigurasi", terus ChatNotifier tangkep dan tampilkan dialog yang sama.

Jadi aplikasi tetap hidup walau AI-nya nggak bisa dihubungi. Ini yang penting banget buat UX di mobile — jangan sampai user ngeliat layar putih atau app nge-freeze gara-gara koneksi jelek.
