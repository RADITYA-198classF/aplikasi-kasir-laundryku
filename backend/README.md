# Backend LaundryKu (Laravel 11/12 + Sanctum)

REST API untuk aplikasi Flutter. Dokumentasi endpoint: [`docs/API.md`](docs/API.md).

## Kebutuhan
- PHP 8.2+ (ekstensi `pdo_sqlite` aktif untuk SQLite, atau `pdo_mysql` untuk MySQL)
- Composer 2

## Menjalankan
```bash
cd backend
composer install
php artisan migrate --seed
php artisan serve --host=0.0.0.0 --port=8000
```
Cek: buka `http://localhost:8000/api/health` -> `{"status":"ok"}`.

`.env` sudah disiapkan (SQLite, zona waktu Asia/Jakarta). File database `database/database.sqlite` sudah ada (kosong),
`php artisan migrate --seed` yang mengisinya.

### Akun demo (dari seeder)
| Peran | Email | Password |
|---|---|---|
| Owner | `admin@laundryku.com` | `admin123` |
| Karyawan | `sari@laundryku.com` | `sari123` |

Reset data demo: `php artisan migrate:fresh --seed`

### Pakai MySQL (XAMPP / Laragon)
1. Buat database kosong `laundryku`.
2. Di `.env`: komentari `DB_CONNECTION=sqlite`, lalu aktifkan blok `DB_CONNECTION=mysql ...`.
3. `php artisan migrate:fresh --seed`

## Menyambungkan aplikasi Flutter
| Perangkat | Perintah |
|---|---|
| Emulator Android | `flutter run` (default `http://10.0.2.2:8000/api`) |
| HP asli (satu Wi-Fi dengan laptop) | `flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000/api` |
| Chrome / Windows / iOS Simulator | `flutter run --dart-define=API_BASE_URL=http://localhost:8000/api` |

`IP_LAPTOP` dilihat dengan `ipconfig` (Windows) / `ifconfig` (Mac/Linux). Server harus dijalankan dengan `--host=0.0.0.0`,
dan firewall harus mengizinkan port 8000.

## Masalah umum
- **`could not find driver`** -> aktifkan `extension=pdo_sqlite` (atau `pdo_mysql`) di `php.ini`.
- **Flutter: "Tidak dapat terhubung ke server"** -> server belum jalan, URL/IP salah, atau firewall memblokir port 8000.
- **Login sering gagal setelah beberapa kali coba** -> endpoint login dibatasi 10x per menit (`throttle:10,1`).
- Error 500 -> lihat `storage/logs/laravel.log`.
