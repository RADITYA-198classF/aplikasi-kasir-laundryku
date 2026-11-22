# Backend LaundryKu (Laravel 11/12 + Sanctum)

REST API untuk aplikasi Flutter kasir laundry. Dokumentasi endpoint: [`docs/API.md`](docs/API.md).

## Kebutuhan
- PHP 8.2+ (ekstensi `pdo_mysql` untuk MySQL, atau `pdo_sqlite` untuk SQLite)
- Composer 2
- MySQL 8 (mis. dari Laragon/XAMPP), atau SQLite

## Menjalankan pertama kali (setelah clone)
```bash
cd backend
composer install
cp .env.example .env        # Windows PowerShell: copy .env.example .env
php artisan key:generate
```

Atur database di `.env`:

**MySQL (disarankan):** buat database kosong `laundryku`, lalu isi
```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=laundryku
DB_USERNAME=root
DB_PASSWORD=
APP_TIMEZONE=Asia/Jakarta
```

**SQLite:** `DB_CONNECTION=sqlite`, hapus baris DB_HOST/PORT/DATABASE/USERNAME/PASSWORD, dan buat file
`database/database.sqlite` (atau jawab `yes` saat `migrate` menawarkan membuatnya).

Lalu:
```bash
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```
Cek: buka `http://localhost:8000/api/health` -> `{"status":"ok"}`.

> `APP_TIMEZONE=Asia/Jakarta` penting: tanggal nomor nota dan batas "hari ini" mengikuti zona waktu ini
> (dibaca lewat `config/app.php`).

### Akun demo (dari seeder)
| Peran | Email | Password |
|---|---|---|
| Owner | `admin@laundryku.com` | `admin123` |
| Karyawan (hak: transaksi, pengeluaran) | `sari@laundryku.com` | `sari123` |

Ganti password akun demo sebelum dipakai sungguhan.
Reset data demo: `php artisan migrate:fresh --seed` (**menghapus semua data** di database).

## Pengujian API otomatis
Server harus berjalan. Reset data lalu jalankan skrip uji (jangan memakai aplikasi di antaranya):
```bash
php artisan migrate:fresh --seed
python tests/api_e2e.py
```
Skrip berhenti sekitar satu menit sekali karena login dibatasi 10x per menit; itu normal.
Hasil yang diharapkan: `PASS=104 FAIL=0`. Setelah selesai, jalankan `migrate:fresh --seed` lagi untuk membuang data uji.

## Menyambungkan aplikasi Flutter
| Perangkat | Perintah |
|---|---|
| Emulator Android | `flutter run` (default `http://10.0.2.2:8000/api`) |
| HP asli (satu Wi-Fi dengan laptop) | `flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api` |
| Chrome / Windows / iOS Simulator | `flutter run --dart-define=API_BASE_URL=http://localhost:8000/api` |

`IP_LAPTOP` dilihat dengan `ipconfig` (Windows) / `ifconfig` (Mac/Linux). Server harus dijalankan dengan `--host=0.0.0.0`,
dan firewall harus mengizinkan port 8000.

## Masalah umum
- **`php` is not recognized (Windows + Laragon)** -> jalankan dari terminal Laragon, atau di Laragon pilih
  Tools > Path > Add Laragon to Path, lalu buka ulang terminal.
- **`could not find driver`** -> aktifkan `extension=pdo_mysql` (atau `pdo_sqlite`) di `php.ini`.
- **`No application encryption key has been specified`** -> jalankan `php artisan key:generate`.
- **Flutter: "Tidak dapat terhubung ke server"** -> server belum jalan, URL/IP salah, atau firewall memblokir port 8000.
- **Login gagal setelah beberapa kali coba (429)** -> login/daftar dibatasi 10x per menit (`throttle:10,1`); tunggu semenit.
- Error 500 -> lihat `storage/logs/laravel.log`.