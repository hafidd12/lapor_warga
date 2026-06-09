# PRD - Aplikasi Lapor Warga

## 1. Ringkasan Produk

**Lapor Warga** adalah aplikasi mobile Flutter untuk memudahkan warga melaporkan masalah lingkungan kepada pengurus RT/RW, sekaligus membantu RT/RW mengelola verifikasi warga, pengumuman, voting, dan tindak lanjut laporan secara transparan.

Tujuan utama aplikasi:
- Warga dapat membuat dan memantau laporan lingkungan.
- RT/RW dapat memverifikasi warga dan menangani laporan.
- Warga dapat melihat bukti foto penyelesaian yang dikirim RT/RW setelah laporan selesai.
- Komunitas memiliki kanal pengumuman dan voting yang rapi.

Target pengguna:
- **Warga**: penduduk yang tinggal di wilayah RT/RW tertentu.
- **RT/RW (Admin)**: pengurus lingkungan yang mengelola warga, laporan, pengumuman, dan voting.

## 2. Sistem Autentikasi

### 2.1 Alur Pendaftaran

```text
Buka aplikasi -> Loading -> Login
                         -> Belum punya akun?
                         -> Pilih peran
                         -> Form Warga atau Form RT/RW
                         -> Warga menunggu verifikasi RT
                         -> RT/RW langsung bisa login
```

Form warga:
- Nama lengkap
- NIK atau nomor KTP
- Email
- Nomor telepon
- RT/RW
- Alamat
- Password

Form RT/RW:
- Nama lengkap
- Email
- Nomor telepon
- Jabatan
- Nomor RT/RW
- Password

### 2.2 Alur Login

1. Pengguna memasukkan email dan password.
2. Sistem mencari akun berdasarkan email.
3. Jika akun warga belum diverifikasi, pengguna diarahkan ke halaman menunggu verifikasi.
4. Jika akun warga ditolak, pengguna melihat informasi penolakan.
5. Jika akun valid dan sudah diverifikasi, pengguna masuk ke dashboard sesuai role.

### 2.3 Verifikasi Warga

RT/RW dapat:
- Melihat daftar warga pending, terverifikasi, dan ditolak.
- Menyetujui pendaftaran warga.
- Menolak pendaftaran warga.
- Mengeluarkan warga dari sistem jika diperlukan.

## 3. Fitur RT/RW

### 3.1 Dashboard Admin

Dashboard admin menampilkan:
- Jumlah laporan baru, diproses, dan selesai.
- Jumlah warga terverifikasi dan pending.
- Akses cepat ke manajemen warga, laporan, pengumuman, voting, aktivitas, dan profil.

### 3.2 Manajemen Warga

Admin dapat:
- Melihat daftar warga.
- Memverifikasi warga baru.
- Menolak warga yang tidak valid.
- Menghapus warga dari daftar wilayah.

### 3.3 Pengumuman

Admin dapat membuat pengumuman berisi judul dan konten. Pengumuman tampil di dashboard warga.

### 3.4 Voting

Admin dapat membuat polling dengan satu pertanyaan dan beberapa opsi. Warga dapat memilih satu opsi dan melihat hasil voting.

### 3.5 Pengelolaan Laporan

Admin dapat:
- Melihat semua laporan warga.
- Mengubah status laporan menjadi **Diajukan**, **Diproses**, atau **Selesai**.
- Menyelesaikan laporan dengan bukti foto.

Ketentuan bukti foto penyelesaian:
- Saat laporan ditandai selesai, RT/RW wajib menyertakan URL atau lampiran foto bukti.
- Foto tersimpan pada data laporan sebagai `completionPhotoUrl`.
- Sistem menyimpan waktu penyelesaian sebagai `completedAt`.
- Sistem menyimpan nama petugas sebagai `completedBy`.
- Aktivitas admin mencatat penyelesaian laporan dan foto terkait.

### 3.6 Aktivitas Admin

Aktivitas admin mencatat:
- Verifikasi warga.
- Penolakan atau penghapusan warga.
- Pengumuman yang dibuat.
- Voting yang dibuat.
- Laporan yang selesai beserta bukti foto.

## 4. Fitur Warga

### 4.1 Dashboard Warga

Dashboard warga menampilkan:
- Sapaan dan wilayah RT/RW.
- Sorotan **Bukti Selesai dari RT** untuk laporan selesai yang memiliki foto bukti.
- Pengumuman terbaru.
- Laporan terbaru.
- Voting lingkungan.
- Tombol buat laporan baru.

### 4.2 Membuat Laporan

Warga dapat membuat laporan dengan:
- Judul laporan.
- Kategori.
- Prioritas.
- Deskripsi detail.
- Foto bukti awal secara opsional.

Kategori laporan:
- Infrastruktur
- Kebersihan
- Keamanan
- Penerangan Jalan
- Sosial & Tetangga
- Lainnya

Prioritas laporan:
- Rendah
- Sedang
- Tinggi

### 4.3 Aktivitas dan History Laporan

Warga dapat:
- Melihat seluruh history laporan.
- Mencari laporan berdasarkan judul, deskripsi, atau kategori.
- Memfilter laporan berdasarkan status.
- Membuka detail laporan.
- Melihat status pengerjaan bertahap: Diajukan -> Diproses -> Selesai.

### 4.4 Melihat Foto Bukti Penyelesaian

Warga harus bisa melihat foto yang dikirim RT/RW setelah laporan selesai.

Acceptance criteria:
- Kartu laporan selesai menampilkan penanda bahwa ada bukti foto dari RT.
- Detail laporan selesai menampilkan bagian **Bukti Penyelesaian RT**.
- Foto bukti dapat diperbesar.
- Metadata penyelesaian menampilkan siapa yang menyelesaikan dan tanggal penyelesaian jika tersedia.
- Dashboard warga menampilkan sorotan laporan selesai terbaru yang memiliki foto bukti.

### 4.5 Profil Warga

Warga dapat:
- Melihat informasi akun.
- Melihat status verifikasi.
- Logout.

## 5. Desain dan UI/UX

Desain mengikuti referensi Stitch pada file `stitch_aplikasi_lapor_warga.zip`.

Design system:
- **Primary**: Deep Forest Green `#012D1D`
- **Primary Container**: `#1B4332`
- **Background**: Soft Earthy Light Grey `#F8F9FA`
- **Surface Card**: `#FFFFFF`
- **Text Primary**: `#191C1D`
- **Text Secondary**: `#414844`
- **Font**: Inter
- **Radius kecil**: 8px
- **Radius kartu besar**: 16px
- **Shadow**: ambient shadow ringan dengan tint hijau

Pola desain utama dari Stitch:
- Top app bar putih/surface dengan brand hijau.
- Halaman aktivitas warga memakai judul **History Laporan**, search field, filter chip, kartu laporan, dan statistik ringkas.
- Laporan selesai memakai visual bukti foto dan status hijau.
- Detail laporan menonjolkan status, metadata pelapor, deskripsi, bukti foto, dan riwayat/progress status.

## 6. Navigasi

Bottom navigation warga:
1. Dashboard
2. Laporan
3. Profil

Bottom navigation RT/RW:
1. Dashboard
2. Warga
3. Aktivitas
4. Profil

## 7. Tech Stack

- Framework: Flutter
- Bahasa: Dart
- State management: Provider / ChangeNotifier
- Font: Google Fonts Inter
- Data: mock data lokal
- Target platform: Android, iOS, Web

## 8. Status Prioritas

| Fitur | Prioritas | Status |
| --- | --- | --- |
| Login/register role warga dan RT/RW | Tinggi | Dalam pengerjaan |
| Verifikasi warga oleh RT/RW | Tinggi | Dalam pengerjaan |
| Dashboard RT/RW dengan statistik | Tinggi | Dalam pengerjaan |
| Manajemen warga | Tinggi | Dalam pengerjaan |
| Penyelesaian laporan dengan foto RT/RW | Tinggi | Dalam pengerjaan |
| Warga melihat foto bukti selesai | Tinggi | Dalam pengerjaan |
| Voting dan pengumuman | Sedang | Sudah ada |
| Profil dan logout | Rendah | Sudah ada |

## 9. Catatan Implementasi Saat Ini

Data laporan sudah mendukung:
- `completionPhotoUrl`
- `completedAt`
- `completedBy`

Data aktivitas admin sudah mendukung:
- `photoUrl`
- `relatedId`

Mock data perlu menyediakan minimal satu laporan selesai dengan foto bukti agar flow warga dapat diuji.

---

Tanggal dokumen: 9 Juni 2026  
Versi: 1.1
