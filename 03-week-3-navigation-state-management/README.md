AI Verification Checklist

1. State diubah secara immutable
Data tidak diubah secara langsung dan menggunakan const. Tidak ada penggunaan state.add(), state.remove(), atau mutasi list lainnya.

2. Penggunaan ref.watch dan ref.read
ref.watch digunakan di dalam build(), sedangkan aksi tombol menggunakan ref.invalidate() melalui callback.

3. Penanganan AsyncValue
Kondisi loading, error, dan data sudah ditangani menggunakan when(). Saat terjadi error juga tersedia tombol untuk mencoba lagi.

4. Deklarasi provider
Provider sudah menggunakan tipe data yang jelas yaitu AsyncNotifierProvider<StatsNotifier, List<String>> dan tidak ada provider yang duplikat.

5. Penggunaan API Riverpod
Kode sudah menggunakan AsyncNotifier dan ConsumerWidget, sehingga tidak menggunakan pola lama seperti StateProvider atau StateNotifierProvider.

6. Hasil flutter analyze dan flutter test
Test untuk kondisi loading, error, dan success sudah berhasil dijalankan. flutter analyze juga tidak menemukan error atau warning.


Refleksi

1. SetState cukup untuk state lokal di satu widget saja, misalnya toggle sembunyikan password atau animasi tombol. State harus naik ke Riverpod kalau datanya dipakai bersama antar halaman seperti daftar tugas dan filter, mengurus data asinkron dari internet, atau saat logikanya mau diuji lewat unit test tanpa render UI.

2. Context.go mengganti tumpukan halaman mengikuti alur rute utama, jadi pas untuk pindah tab di menu bawah seperti halaman tugas dan statistik biar riwayat halaman tidak menumpuk. Sedangkan context.push menumpuk halaman baru di atas halaman saat ini, cocok untuk buka form tambah data atau detail yang butuh tombol kembali ke halaman sebelumnya.

3. Pakai tiga boolean terpisah sering memicu kondisi bentrok, misalnya status loading dan error aktif bersamaan karena lupa mereset variabel. AsyncValue memastikan statusnya hanya satu antara loading, error, atau data. Fitur when juga memaksa kita menangani ketiga kondisi itu sejak awal sehingga aplikasi tidak gampang crash karena data bernilai null.

4. Bagian yang diperbaiki adalah jalur import di file test yang awalnya memicu peringatan linter karena mengarah langsung ke folder luar, diubah memakai nama package aplikasi. Logika acak error juga dimodifikasi supaya nilainya bisa dikontrol saat unit test agar hasilnya konsisten dan tidak berubah-ubah. Selain itu tampilan list tugas di halaman utama sempat hilang saat memasang tombol navigasi dan langsung dikembalikan lagi.