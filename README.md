# Kasir LaundryKu

Aplikasi kasir untuk usaha laundry: **Flutter** (Android/desktop/web) + **backend REST API Laravel** dengan autentikasi token (Laravel Sanctum) dan basis data MySQL.

Dipakai oleh dua peran: **owner** (semua fitur) dan **karyawan** (sesuai hak akses yang diberikan owner).

## Fitur

- **Akun:** daftar usaha baru, masuk, ganti password.
- **Karyawan & hak akses:** owner menambah karyawan dan mengatur lima hak akses (`transaksi`, `batalBayar`, `layanan`, `pengeluaran`, `laporan`).
- **Layanan:** kategori dan layanan (kg, pcs, m²; durasi hari/jam), aktif/nonaktif.
- **Pelanggan:** data pelanggan; riwayat transaksi tetap tersimpan walau pelanggan dihapus.
- **Transaksi:** nota otomatis `INV-yymmdd-0001`, estimasi selesai, status *antrian → diproses → selesai → diambil*, pembayaran tunai/QRIS termasuk uang muka, pembatalan terkontrol.
- **WhatsApp:** pesan ke pelanggan sesuai status transaksi.
- **Pengeluaran** dan **laporan** omzet, piutang, laba; **unduh PDF** laporan dengan pilihan bagian, dan riwayat unduhan tercatat di server.
- **Aturan bisnis di server:** harga dihitung ulang dari katalog layanan (tidak bisa dimanipulasi dari aplikasi), hak akses dicek di server, data tiap usaha terpisah.

## Struktur repo

```
lib/        aplikasi Flutter (layar, widget, state, repository)
backend/    REST API Laravel (41 endpoint), migrasi, seeder, uji API
  docs/API.md   dokumentasi endpoint
  tests/api_e2e.py   uji API otomatis (104 pernyataan uji)
```

## Menjalankan

### 1. Backend

Kebutuhan: PHP 8.2+, Composer 2, MySQL 8 (mis. Laragon/XAMPP).

```bash
cd backend
composer install
cp .env.example .env        # Windows PowerShell: copy .env.example .env
php artisan key:generate
```

Buat database kosong `laundryku`, cek pengaturan `DB_*` di `.env`, lalu:

```bash
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```

Cek `http://localhost:8000/api/health` → `{"status":"ok"}`. Detail dan pemecahan masalah ada di [`backend/README.md`](backend/README.md).

### 2. Aplikasi Flutter

```bash
flutter pub get
flutter run
```

Alamat API bawaan adalah `http://10.0.2.2:8000/api` (emulator Android). Untuk perangkat lain:

| Perangkat | Perintah |
|---|---|
| HP asli (satu Wi-Fi dengan laptop) | `flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api` |
| Chrome / Windows / iOS Simulator | `flutter run --dart-define=API_BASE_URL=http://localhost:8000/api` |

### Akun demo (dari seeder)

| Peran | Email | Password |
|---|---|---|
| Owner | `admin@laundryku.com` | `admin123` |
| Karyawan (hak: transaksi, pengeluaran) | `sari@laundryku.com` | `sari123` |

Akun ini hanya untuk percobaan. Ganti passwordnya sebelum dipakai sungguhan.

## Pengujian

Uji API otomatis (server harus berjalan, data baru di-seed):

```bash
cd backend
php artisan migrate:fresh --seed
python tests/api_e2e.py
```

Hasil yang diharapkan: `PASS=104 FAIL=0` (skrip berhenti sekitar satu menit sekali karena login dibatasi 10 kali per menit).

## Teknologi

- **Aplikasi:** Flutter, Dart, `provider`, `dio`, `pdf`, `printing`, `url_launcher`; pola repository (`MockLaundryRepository` untuk data demo lokal, `ApiLaundryRepository` untuk server).
- **Server:** Laravel, Laravel Sanctum, Eloquent ORM, MySQL.

## Tangkapan layar

<!-- Tambahkan gambar di sini, mis.: ![Beranda](docs/screenshots/beranda.png) -->

## Pembuat

Raditya Ardi Prahasta, Sistem Informasi, Universitas Negeri Surabaya.