Refleksi

1\. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?

SharedPreferences menyimpan data dalam bentuk berkas XML teks polos (plain text) tanpa enkripsi di direktori internal aplikasi (/data/data/<package\_name>/shared\_prefs/). Pada perangkat yang di-root, atau melalui eksploitasi vulnerability backup OS, berkas ini dapat dibaca oleh aplikasi lain atau malware.



Jika Refresh Token bocor, penyerang memperoleh kredensial sesi berumur panjang. Penyerang dapat secara kontinu meminta Access Token baru ke server otentikasi atas nama korban tanpa perlu mengetahui password, yang merusak seluruh skema keamanan otentikasi. flutter\_secure\_storage mengatasi risiko ini dengan memanfaatkan Android Keystore / iOS Keychain yang mengenkripsi data berbasis hardware (TEE/SE).



2\. Apa yang rusak bila onTokenRefresh diabaikan selama satu semester perkuliahan?

FCM Registration Token bersifat dinamis dan dapat berubah karena berbagai kondisi (misalnya instalasi ulang aplikasi, pengosongan data/cache, pemulihan cadangan, atau rotasi kunci internal FCM).



Jika listener onTokenRefresh diabaikan, backend kampus akan terus menyimpan token lama yang sudah tidak aktif (stale token). Dampaknya:



Server FCM akan mengembalikan respons error NotRegistered saat backend mencoba mengirimkan notifikasi.



Mahasiswa tidak akan menerima notifikasi penting sepanjang semester (seperti perubahan jadwal kuliah, pengumuman ujian, atau status pengajuan KRS).



3\. Kapan memakai topik dan kapan memakai token perangkat? Beri contoh pesan kampus untuk masing-masing.

Topik (Topic Messaging): Digunakan untuk komunikasi publik/broadcast (one-to-many) ke seluruh pengguna yang terdaftar pada kategori tertentu tanpa membedakan identitas personal.



Contoh Pesan Topik: Pengumuman edaran libur semester atau jadwal pemeliharaan portal SIAKAD yang dikirim ke topik pengumuman-kampus.



Token Perangkat (Device Registration Token): Digunakan untuk komunikasi personal/spesifik (one-to-one) yang memuat informasi sensitif dan hanya boleh diterima oleh individu tertentu.



Contoh Pesan Token Perangkat: Notifikasi persetujuan KRS oleh Dosen Pembimbing Akademik atau rincian tagihan UKT individual.



4\. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?

Draf AI awal mengusulkan pemanggilan logika parsing rute yang terikat langsung dengan kelas RemoteMessage serta menempatkan pemicu navigasi UI di dalam Dio Interceptor.



Bagian tersebut ditolak dan diperbaiki karena:



Testability: Kelas parsing rute diubah menjadi fungsi murni (routeFromMessage(Map<String, dynamic> data)) agar dapat diuji secara kilat melalui Unit Test tanpa memanggil modul native Firebase.



Single Responsibility Principle: Navigasi UI dipisahkan dari layer Network Interceptor agar Interceptor hanya fokus pada pengelolaan token HTTP 401 dan pembaruan TokenStore.

