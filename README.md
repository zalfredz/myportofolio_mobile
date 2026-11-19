Nama : Alfredo Harsono  
NPM : 2506656412  
Kelas : PBP C  
Semester : 3

#### Deskripsi Proyek

MyPortofolio Mobile adalah aplikasi mobile berbasis Flutter yang menjadi pendamping website portofolio pribadi saya, [myportofolio](https://github.com/zalfredz/myportofolio). Aplikasi ini dirancang sebagai klien mobile yang mengambil dan mengelola data portofolio, seperti Experience dan Projects, melalui REST API yang dibangun dengan Django REST Framework di `/api/v1/`. Dengan begitu, portofolio dapat diakses dan dikelola dari perangkat Android, iOS, maupun web dari satu basis kode.

#### Instruksi Setup

1. Pastikan Flutter SDK dan Google Chrome sudah terpasang, lalu cek dengan `flutter doctor`.

   ```sh
   flutter doctor
   ```

2. Clone repository dan masuk ke direktori proyek.

   ```sh
   git clone https://github.com/zalfredz/myportofolio_mobile.git
   cd myportofolio_mobile
   ```

3. Unduh dependency.

   ```sh
   flutter pub get
   ```

4. Jalankan aplikasi di Google Chrome.

   ```sh
   flutter run -d chrome
   ```

   Aplikasi juga dapat dijalankan di emulator Android atau perangkat fisik dengan `flutter run`.

5. Periksa kualitas kode.

   ```sh
   flutter analyze
   ```

6. Jalankan widget test.

   ```sh
   flutter test
   ```

---

### Tugas 7

1. Widget tree adalah susunan hierarki widget yang membentuk tampilan aplikasi Flutter. Induk (parent) membungkus satu anak melalui `child` atau beberapa anak melalui `children`, serta mengatur batasan ukuran dan tata letaknya. Dalam proyek ini, `MaterialApp` membungkus `Scaffold`, yang menyediakan `AppBar` dan `body` berisi kartu identitas (`InfoCard`) serta tombol menu (`ItemCard`).

2. Widget yang saya gunakan:
   - `MaterialApp`: root aplikasi yang mengatur judul, tema warna, dan halaman awal.
   - `Scaffold`: kerangka halaman yang menyediakan tempat untuk AppBar, body, dan SnackBar.
   - `AppBar`: bar di bagian atas yang menampilkan judul "MyPortfolio".
   - `Text`: menampilkan teks, seperti judul, data identitas, dan label tombol.
   - `SingleChildScrollView`: membuat halaman bisa di-scroll jika kontennya melebihi tinggi layar.
   - `Padding`: memberi jarak di sekitar widget anaknya.
   - `Column`: menyusun widget secara vertikal.
   - `Row`: menyusun tiga kartu identitas secara horizontal.
   - `Expanded`: membagi lebar `Row` secara merata untuk ketiga `InfoCard`.
   - `SizedBox`: memberi jarak kosong dengan ukuran tetap antarwidget.
   - `Card`: kartu dengan bayangan untuk membungkus informasi identitas.
   - `GridView.count`: menampilkan tombol menu dalam grid tiga kolom.
   - `Material`: memberi warna latar dan sudut membulat pada tombol, sekaligus menjadi permukaan untuk efek ripple.
   - `InkWell`: menangkap ketukan dan menampilkan efek ripple saat tombol ditekan.
   - `Icon`: menampilkan ikon pada tombol dan SnackBar.
   - `ScaffoldMessenger`: mengelola SnackBar, yaitu menutup SnackBar sebelumnya lalu menampilkan yang baru.
   - `SnackBar`: notifikasi singkat yang muncul setelah tombol ditekan.
   - `MyApp`, `MyHomePage`, `InfoCard`, dan `ItemCard`: widget buatan sendiri (semuanya `StatelessWidget`) untuk root aplikasi, halaman utama, kartu identitas, dan kartu tombol.

3. `MaterialApp` menyediakan konfigurasi dasar aplikasi Material Design, seperti tema (`ThemeData`), navigasi (`Navigator`), dan pengelolaan SnackBar (`ScaffoldMessenger`). Widget ini umumnya digunakan sebagai root widget karena widget Material seperti `Scaffold`, `AppBar`, dan `SnackBar` mencari konfigurasi tersebut dari leluhurnya. Tanpa `MaterialApp` di atasnya, widget-widget itu tidak mendapat tema dan layanan yang dibutuhkan.

4. `StatelessWidget` tidak memiliki state internal yang dapat berubah, tetapi tampilannya dapat dibangun ulang ketika data dari parent atau konteks berubah. Widget ini cocok untuk tampilan statis seperti kartu identitas dan menu sederhana. `StatefulWidget` memiliki objek `State` untuk menyimpan data yang berubah dan dapat memperbarui tampilan melalui `setState()`, sehingga dipakai ketika tampilan bergantung pada interaksi atau data yang berubah, misalnya counter, checkbox, atau form input.

5. `BuildContext` menunjukkan posisi widget dalam widget tree dan memungkinkan akses ke data atau layanan dari leluhurnya. Di dalam `build(BuildContext context)`, contohnya adalah `Theme.of(context)` untuk mengambil tema dan `ScaffoldMessenger.of(context)` untuk menampilkan SnackBar. Context harus berada di bawah leluhur yang menyediakan layanan tersebut.

6. Hot reload menerapkan perubahan kode ke aplikasi yang sedang berjalan dan menjalankan ulang `build()` sambil mempertahankan state aplikasi. Hot restart menjalankan ulang aplikasi Dart dari `main()` sehingga state kembali ke kondisi awal. Hot reload tidak cukup jika perubahan harus menjalankan ulang kode inisialisasi, seperti `main()`, `initState()`, atau nilai awal variabel global dan `static`, sehingga perlu hot restart. Full restart (menghentikan lalu menjalankan ulang `flutter run`) diperlukan setelah mengubah kode native Android atau iOS, atau menambah package baru di `pubspec.yaml`.

### AI Disclosure
Saya tidak menggunakan bantuan AI dalam pengerjaan tugas kali ini. Segala pembuatan, penyesuaian, dan integrasi dengan bagian website lainnya saya kerjakan dan sesuaikan sendiri.

---

### Tugas 8

1. `Navigator.push()` menambahkan halaman baru di atas tumpukan (stack) sehingga halaman sebelumnya tetap ada di bawahnya. `Navigator.pushReplacement()` mengganti halaman paling atas dengan halaman baru, sehingga halaman lama dibuang dari stack. `Navigator.pop()` menghapus halaman paling atas dan kembali ke halaman di bawahnya. Formulir dari kartu aksi dibuka dengan `Navigator.push()` (melalui atribut `page` pada `ItemHomepage`), sehingga tombol Back perangkat atau browser bisa membawa pengguna kembali ke menu. Opsi Home di drawer memakai `Navigator.pushReplacement()` ke `MyHomePage`, sehingga halaman formulir diganti dengan halaman utama dan tidak bisa dibuka lagi dengan tombol Back. Pada formulir pengalaman, drawer meminta konfirmasi terlebih dahulu jika masih ada isian yang belum disimpan.

2. Setiap halaman memakai `Scaffold` dengan slot yang sama: `appBar` untuk judul, `drawer` untuk menu navigasi, dan `body` untuk konten. Karena `AppBar` selalu berada di atas dan widget `LeftDrawer` yang sama dipakai di halaman utama, formulir proyek, dan formulir pengalaman, posisi judul, ikon menu, dan isi drawer tetap sama di semua halaman. Contoh warna tema: `Theme.of(context).colorScheme.primary`, yang dibuat dari `seedColor: Colors.indigo` di `main.dart`, dipakai sebagai warna `AppBar` di `MyHomePage` dan `ExperienceFormPage`, serta sebagai warna tombol Simpan.

3. Formulir disusun dalam satu `Column` agar field terbaca dari atas ke bawah sesuai urutan pengisian dan setiap field memakai lebar penuh, sehingga nyaman di layar ponsel. `Padding` memberi jarak antarfield agar tidak berdempetan dan mudah disentuh. `SingleChildScrollView` membuat formulir bisa di-scroll ketika layar sempit atau papan ketik muncul. Tanpa widget ini, `Column` yang lebih tinggi dari layar akan overflow dan tombol Simpan tidak bisa dijangkau.


### AI Disclosure
Saya juga menggunakan bantuan AI (model KIMI) untuk memahami dan melihat contoh implementasi code yang ingin saya kerjakan. Penggunaan AI tersebut berfungsi sebagai alat bantu dalam proses pemahaman cara implementasinya, sementara penyesuaian code, integrasi dengan bagian website lainnya saya kerjakan dan sesuaikan sendiri.

bisa di cek melalui link berikut: https://www.kimi.ai/share/1a1f2ffa-ded2-8c2b-8000-000033452292

### Implementasi SARAN KIMI (AI):

`Struktur Formulir`
Saran solusi dari AI:
Gunakan `StatefulWidget`, `Form` dengan `GlobalKey<FormState>`, dan `TextEditingController` untuk setiap field teks. Reset form dengan `reset()`, `clear()` pada controller, dan mengosongkan variabel state.

Implementasi saya:
Saya tetap memakai pola Tutorial 09, yaitu `onChanged` yang menyimpan isian ke variabel state, dan controller hanya dipakai untuk field tanggal. Saya menerapkan saran reset dengan mengosongkan variabel state setelah OK agar nilai lama tidak muncul di dialog berikutnya.

`Pemilih Tanggal dan Validasinya`
Saran solusi dari AI:
Bungkus `showDatePicker()` dalam `FormField<DateTime>` dengan `initialValue` agar validasi tanggal ikut berjalan saat `validate()` dipanggil.

Implementasi saya:
Saran ini tidak saya pakai karena nilai `FormField` tidak pernah diperbarui, sehingga validator selalu menerima `null` dan formulir tidak bisa disimpan meskipun tanggal sudah dipilih. Saya memakai `TextFormField` read-only dengan controller, validator yang membaca tanggal dari state, dan batas `firstDate` agar tanggal selesai tidak bisa dipilih sebelum tanggal mulai.

---