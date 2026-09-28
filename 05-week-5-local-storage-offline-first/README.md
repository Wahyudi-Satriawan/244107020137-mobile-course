Refleksi



1\. Mengapa daftar catatan tidak boleh disimpan di SharedPreferences? Apa yang rusak jika aturan ini dilanggar?



SharedPreferences tidak dirancang untuk menyimpan kumpulan data koleksi yang kompleks. Jika daftar catatan dipaksakan untuk disimpan di dalamnya, setiap perubahan kecil akan memaksa aplikasi untuk memproses ulang seluruh data menjadi satu teks panjang. Hal ini akan membuang memori, menurunkan performa secara drastis seiring bertambahnya data, dan menghilangkan kemampuan pencarian data secara efisien yang dimiliki oleh basis data relasional.





2\. Kapan cache-first cukup, dan kapan Anda membutuhkan strategi lain (misalnya network-first untuk data harga real-time)?



Strategi cache-first memadai untuk data yang tidak memerlukan pembaruan instan, seperti bacaan atau catatan pribadi, sehingga aplikasi tetap dapat menampilkan data dengan seketika saat luring. Sebaliknya, strategi network-first mutlak diperlukan untuk data dinamis yang menuntut keakuratan waktu nyata, seperti pergerakan harga saham, ketersediaan tiket, atau status transaksi keuangan.





3\. Bagaimana dirty flag berubah menjadi antrean sync tanpa memblokir UI? Kapan antrean terpisah (tabel outbox) menjadi perlu?



Penanda kotor (dirty flag) pada tabel dibaca secara asinkron di latar belakang oleh sistem penyingkron. Proses ini mengirimkan data yang belum tersinkronisasi ke peladen tanpa menghentikan atau mengganggu interaksi antarmuka pengguna. Penggunaan antrean terpisah seperti tabel outbox menjadi perlu ketika urutan modifikasi data sangat krusial, misalnya saat sebuah catatan dibuat, diubah, lalu dihapus secara berurutan saat luring, agar peladen dapat mengeksekusi instruksi tersebut dengan urutan yang tepat dan tidak memicu konflik.





4\. Bagian mana dari rekomendasi AI yang Anda tolak, dan mengapa?



Saya secara tegas menolak rekomendasi sistem AI jika menyarankan penempatan daftar catatan ke dalam SharedPreferences. SharedPreferences sangat rapuh dan tidak efisien untuk menyimpan tipe data koleksi yang rutin dimodifikasi. Oleh karena itu, saya memutuskan untuk menggunakan kombinasi yang tepat, yaitu pengaturan preferensi tema pada SharedPreferences dan pengelolaan rekam data catatan pada SQLite.







Verifikasi AI Challenge



\* Antarmuka pengguna tidak memanggil SharedPreferences atau SQLite secara langsung, melainkan semua akses dilewatkan melalui perantara lapisan repository dan provider.





\* Aplikasi tetap berfungsi secara penuh dalam mode pesawat untuk keperluan membaca, menambah, dan menghapus catatan.





\* Lencana penanda kotor (dirty flag) bekerja secara akurat baik sebelum maupun sesudah proses sinkronisasi, serta cache catatan tetap tampil meskipun tanpa jaringan internet.





\* Skema basis data yang dirancang telah mendukung sistem antrean sinkronisasi melalui penggunaan penanda kotor (dirty flag) dan waktu pembaruan (updated\_at).





\* Hasil pengecekan lokal menggunakan analisis statis telah bersih tanpa adanya masalah, dan semua unit pengujian telah berhasil dilewati.

