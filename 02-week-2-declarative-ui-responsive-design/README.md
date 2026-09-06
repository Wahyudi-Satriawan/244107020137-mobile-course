Hasil screenshot terletak pada folder screenshots

Hasil Test terletak pada folder test



AI Prompt Challenge



1\. Perbandingan Desain: GridView vs LayoutBuilder + Column

Trade-off Responsif:



Versi GridView (Murni): Sangat efisien untuk menampilkan sekumpulan item yang bentuk dan ukurannya seragam. Menjadikannya responsif cukup mudah, biasanya hanya dengan mengubah properti crossAxisCount berdasarkan ukuran layar. Namun, tata letak ini kurang fleksibel. Jika Anda perlu menambahkan elemen dengan struktur berbeda di halaman yang sama (misalnya, menambahkan header profil di atas deretan kartu), penggunaan GridView murni akan menyulitkan karena seluruh layar terikat pada aturan grid yang sama.



Versi LayoutBuilder + Column: Menawarkan fleksibilitas tinggi. Column memungkinkan Anda membagi layar menjadi beberapa bagian vertikal (misal: bagian atas untuk profil, bagian bawah untuk informasi). LayoutBuilder kemudian dapat digunakan secara spesifik di bagian bawah untuk mengatur tata letak yang berubah secara dinamis (dari 1 kolom menjadi 2 kolom) berdasarkan ketersediaan lebar layar. Trade-off-nya adalah kode menjadi lebih bersarang (nested) dan membutuhkan manajemen batas ruang (constraints) yang lebih teliti (contohnya: keharusan menggunakan Expanded pada area konten agar tidak terjadi overflow di dalam Column).



Trade-off Aksesibilitas:

Kedua arsitektur tata letak ini bersifat netral terhadap aksesibilitas. Baik GridView maupun kombinasi LayoutBuilder + Column tidak secara bawaan meningkatkan atau menurunkan aksesibilitas pembaca layar (screen reader). Kualitas aksesibilitas sepenuhnya bergantung pada apakah pengembang membungkus komponen-komponen visual dan informatif di dalam layout tersebut dengan widget Semantics (beserta label yang deskriptif) atau tidak.



2\. Penguatan Konsep: Expanded menyebabkan Overflow

Fungsi utama Expanded adalah memaksa widget di dalamnya untuk membesar dan mengisi seluruh sisa ruang yang tersedia di dalam parent-nya (sepanjang sumbu utama / main axis).



Penggunaan Expanded akan menyebabkan error berupa overflow (RenderFlex children have non-zero flex but incoming width constraints are unbounded) jika diletakkan di dalam Row, tetapi Row tersebut dibungkus oleh widget yang memberikan lebar tidak terbatas (unbounded width).



Kasus yang paling sering terjadi adalah saat sebuah Row dimasukkan ke dalam area yang bisa digulir ke samping, seperti SingleChildScrollView dengan arah scroll horizontal. Dalam kondisi ini, Expanded akan bingung menghitung "sisa ruang" karena ruang scroll secara teoritis tidak memiliki batas akhir (tak terhingga).



Contoh Kode yang Gagal:

// GAGAL: SingleChildScrollView memberikan ruang horizontal tak terbatas.

SingleChildScrollView(

&#x20; scrollDirection: Axis.horizontal,

&#x20; child: Row(

&#x20;   children: \[

&#x20;     Expanded( // <-- Memicu error RenderFlex (Unbounded width)

&#x20;       child: Container(color: Colors.red, height: 50),

&#x20;     ),

&#x20;     Container(width: 100, color: Colors.blue, height: 50),

&#x20;   ],

&#x20; ),

)



Perbaikannya:

Pilih salah satu pendekatan berdasarkan tujuannya. Jika memang membutuhkan fitur scroll ke samping, jangan gunakan Expanded; biarkan widget menentukan ukuran pastinya sendiri (misal dengan SizedBox). Namun, jika tujuannya adalah agar elemen memenuhi layar tanpa scroll, hapus SingleChildScrollView agar Row memiliki batas lebar yang pasti dari layar perangkat.



// DIPERBAIKI: Menghapus scroll agar lebar Row terbatas oleh ukuran layar.

Row(

&#x20; children: \[

&#x20;   Expanded( // Aman: Akan mengambil sisa lebar layar dikurangi 100px.

&#x20;     child: Container(color: Colors.red, height: 50),

&#x20;   ),

&#x20;   Container(width: 100, color: Colors.blue, height: 50),

&#x20; ],

)



3\. Verification Prompt (Audit Layout AI)

Melakukan audit terhadap rekomendasi penggunaan kombinasi LayoutBuilder + Column untuk dashboard akademik:



Apakah tetap responsif di bawah 600px? Ya. Dengan menerapkan pengkondisian pada LayoutBuilder (seperti constraints.maxWidth >= 600 ? 2 : 1), sistem akan mendeteksi ketika layar menyusut di bawah 600px. Tata letak akan secara otomatis terdegradasi menjadi satu kolom vertikal, sehingga mencegah konten terpotong atau mengalami overflow horizontal pada layar smartphone yang sempit.



Apakah mengurangi aksesibilitas? Tidak. Penggunaan widget struktural murni seperti Column, Row, dan LayoutBuilder tidak merusak Semantic Tree yang dibaca oleh layanan aksesibilitas (seperti TalkBack atau VoiceOver). Struktur ini sepenuhnya aman selama elemen konten di dalamnya tetap dikonfigurasi dengan properti aksesibilitas.



Apakah ada widget yang tidak tersedia di Flutter stabil saat ini? Tidak ada. Seluruh komponen inti yang dibutuhkan untuk tata letak ini (Scaffold, Column, Row, Expanded, Container, LayoutBuilder, GridView) adalah widget dasar bawaan (built-in) yang sudah sangat stabil dan sepenuhnya didukung di versi stabil (stable channel) Flutter saat ini.





**Refactoring challenge**

telah menjalankan flutter analyze dan hasilnya "Analyzing responsive\_dashboard...

No issues found! (ran in 1.2s)"





**Refleksi**

1. Pendekatan imperatif mengubah elemen antarmuka secara manual langkah demi langkah setiap kali ada perubahan. Pendekatan deklaratif mendeskripsikan tampilan berdasarkan status data saat ini, dan sistem secara otomatis merender ulang antarmuka ketika data tersebut berubah.

2. Expanded berguna untuk membuat suatu elemen mengisi sisa ruang kosong di dalam baris atau kolom. Expanded akan menghasilkan error jika ditempatkan di dalam wadah yang ukuran panjang atau lebarnya tidak terbatas, seperti pada daftar yang dapat digulir.

3. Breakpoint membuat tata letak otomatis berubah menyesuaikan ukuran layar perangkat sehingga konten tidak terpotong dan mudah diakses. Tema menjaga konsistensi elemen visual serta memberikan kenyamanan melalui penyesuaian warna seperti mode terang dan gelap.

4. Hal yang saya verifikasi setelah membaca rekomendasi AI adalah AI sangat membantu memberikan ide tata letak.

