Refleksi



1\. Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika aturan ini dilanggar?

UI dilarang memanggil Dio secara langsung untuk menjaga prinsip pemisahan tanggung jawab dalam kode. Jika aturan ini dilanggar, pengujian unit pada aplikasi akan menjadi sangat sulit dilakukan karena logika UI terikat langsung dengan logika jaringan. Selain itu, kode penanganan kesalahan seperti koneksi terputus akan menumpuk dan berulang di setiap halaman antarmuka, sehingga aplikasi menjadi tidak efisien untuk dipelihara.





2\. Kapan pagination client-side cukup, dan kapan harus mengandalkan pagination server (\_page/\_limit)?

Pagination client-side sudah cukup memadai apabila jumlah data relatif sedikit dan tidak membebani memori perangkat. Sebaliknya, pagination dari sisi server yang menggunakan parameter \_page dan \_limit wajib digunakan ketika menghadapi data dalam jumlah yang sangat besar. Hal ini bertujuan untuk meringankan beban memori pada perangkat agar tidak kelebihan muatan, serta mempercepat proses pemuatan data awal.





3\. Bagaimana exception repository berubah menjadi AsyncError tanpa try/catch di setiap widget? Kapan try/catch eksplisit tetap dibutuhkan?

Provider dari Riverpod secara otomatis menangkap exception yang tidak tertangani dari lapisan repository dan mengubah statusnya menjadi AsyncError. Karena mekanisme ini, kita tidak perlu menyertakan blok try/catch secara manual pada setiap widget. Namun, penggunaan try/catch eksplisit tetap dibutuhkan ketika kita menangani aksi asinkron di luar siklus status utama, contohnya saat pengguna menekan tombol tertentu, agar sistem dapat memunculkan notifikasi kegagalan secara langsung.





4\. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

Pada hasil awal yang diberikan oleh alat AI, kode hanya menyarankan metode casting konvensional yang rentan terhadap masalah tipe data kosong. Hal ini berisiko menyebabkan aplikasi berhenti paksa jika data yang diterima dari API bernilai null. Oleh karena itu, saya memperbaiki bagian tersebut dengan menerapkan teknik defensive casting agar variabel selalu memiliki nilai bawaan standar yang aman dari null. Saya juga memindahkan konfigurasi waktu tunggu maksimal (timeout) agar terpusat dengan baik pada klien utama.







Verifikasi AI Challenge



\* Antarmuka pengguna (UI) memanggil data melalui perantara repository, bukan memanggil Dio secara langsung.





\* Fungsi penguraian JSON telah dipastikan aman dari kemungkinan adanya data yang bernilai null.





\* Seluruh pengecualian teknis seperti masalah koneksi atau waktu tunggu yang habis telah dipetakan menjadi pesan kesalahan yang mudah dipahami.





\* Pengaturan alamat utama dan batas waktu eksekusi telah dipusatkan pada satu klien jaringan.





\* Hasil pengecekan lokal menggunakan analisis statis telah bersih tanpa adanya peringatan, dan semua unit pengujian telah berhasil dilewati.

