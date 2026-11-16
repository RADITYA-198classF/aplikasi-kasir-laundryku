# Dokumentasi API LaundryKu

Base URL: `http://<host>:8000/api`  
Semua jawaban berformat JSON. Setelah login, kirim header `Authorization: Bearer <token>` dan `Accept: application/json`.

**Format error**

| Kode | Arti | Isi |
|---|---|---|
| 401 | belum login / token salah | `{"message": "..."}` |
| 403 | tidak punya hak akses | `{"message": "..."}` |
| 404 | data tidak ada (atau milik usaha lain) | `{"message": "..."}` |
| 422 | validasi / aturan bisnis gagal | `{"message": "...", "errors": {"field": ["..."]}}` |

**Catatan format data**
- `id` selalu string. Uang = bilangan bulat rupiah. `qty` = angka desimal (boleh 2,5).
- Waktu (`created_at`, `due_at`, `date` pembayaran, `time` log) = ISO-8601 dengan zona (`2026-11-15T10:00:00+07:00`). Pengeluaran memakai tanggal saja `YYYY-MM-DD`.
- Semua data dibatasi per usaha: akun hanya melihat dan mengubah data usahanya sendiri.

## Hak akses

| Pelaku | Boleh |
|---|---|
| Owner | semua fitur |
| Karyawan | sesuai izin: `transaksi`, `batalBayar`, `layanan`, `pengeluaran`, `laporan` |
| Semua akun | dashboard, pelanggan, melihat layanan & transaksi, profil usaha (baca), ganti password sendiri |

## Endpoint

### Auth
| Method & path | Akses | Keterangan |
|---|---|---|
| `POST /auth/register` | publik | `business_name, owner_name, email, phone, password` → buat usaha + owner + katalog bawaan (201) |
| `POST /auth/login` | publik | `email, password` → `{token, session:{name, employee_id, role, permissions[]}}`; 401 jika salah |
| `GET /auth/me` | login | sesi saat ini |
| `POST /auth/logout` | login | cabut token perangkat ini |
| `PUT /auth/password` | login | `old_password, new_password`; password lama salah → 422 `code: wrong_password` |

### Profil usaha
| Method & path | Akses | Keterangan |
|---|---|---|
| `GET /business` | login | `{business_name, owner_name, email, phone, hours, owner_wa}` |
| `PUT /business` | owner | `business_name, owner_name, phone, hours, owner_wa` |

### Karyawan (owner)
| Method & path | Keterangan |
|---|---|
| `GET /employees` | daftar karyawan `{id,name,email,phone,permissions[]}` |
| `POST /employees` | `name, phone, email, password(min 6), permissions[]`; email dipakai → 422 |
| `PUT /employees/{id}` | ubah `name/phone/email/permissions` |
| `DELETE /employees/{id}` | hapus akun (sesi login dicabut, riwayat transaksi tetap) |
| `PUT /employees/{id}/password` | `new_password` — tanpa password lama |

### Kategori & layanan
| Method & path | Akses | Keterangan |
|---|---|---|
| `GET /categories` | login | `{id,name,flow}` |
| `POST /categories`, `PUT /categories/{id}`, `DELETE /categories/{id}` | owner | hapus ditolak jika masih punya layanan |
| `GET /services` | login | semua layanan (termasuk nonaktif) |
| `POST /services` | owner | `category_id, name, unit(kg\|pcs\|m2), price, min_qty, duration_value, duration_unit(hari\|jam), active` |
| `PUT /services/{id}` | owner; karyawan `layanan` hanya boleh mengubah `active` | body sama seperti POST |
| `PATCH /services/{id}/active` | owner / `layanan` | `{active: true\|false}` |
| `DELETE /services/{id}` | owner | riwayat transaksi tetap utuh |

### Pelanggan (semua akun)
| Method & path | Keterangan |
|---|---|
| `GET /customers?q=` | cari nama/telepon; ada `orders_count` (tanpa transaksi batal) |
| `POST /customers`, `PUT /customers/{id}` | `name, phone` |
| `DELETE /customers/{id}` | soft delete — riwayat transaksi tetap tersimpan |

### Transaksi
| Method & path | Akses | Keterangan |
|---|---|---|
| `GET /orders` | login | terbaru dulu. Filter opsional: `status, cancelled (1/0), customer_id, from, to (YYYY-MM-DD), q` |
| `GET /orders/{id}` | login | detail + `items[]`, `payments[]`, `logs[]` |
| `POST /orders` | `transaksi` | `customer_id, items[{service_id, qty}], note, first_payment{method, amount}`. **Harga, nama, durasi diambil server dari katalog.** Nomor invoice `INV-yymmdd-0001`; estimasi selesai = waktu masuk + durasi layanan terlama |
| `PATCH /orders/{id}/status` | `transaksi` | `{status}` — hanya boleh maju satu langkah: antrian → diproses → selesai → diambil |
| `POST /orders/{id}/payments` | `transaksi` | `{method: tunai\|qris, amount}`; nominal dipotong sampai sisa tagihan; lunas → 422 |
| `POST /orders/{id}/cancel` | `transaksi` (+ `batalBayar` jika sudah ada pembayaran) | tidak bisa jika sudah *diambil*; tidak bisa diurungkan |
| `GET /orders/{id}/whatsapp` | login | `{phone, message, url}` pesan WhatsApp sesuai status |

### Pengeluaran
| Method & path | Akses | Keterangan |
|---|---|---|
| `GET /expenses?from=&to=` | login | kosong `[]` jika akun tak punya hak `pengeluaran`/`laporan` |
| `POST /expenses`, `PUT /expenses/{id}`, `DELETE /expenses/{id}` | `pengeluaran` | `date(YYYY-MM-DD), category, amount, note` |

### Dashboard & laporan
| Method & path | Akses | Keterangan |
|---|---|---|
| `GET /dashboard` | login | `today{transactions,omzet,received}`, `status_counts`, `overdue`, `due_today`, `due_tomorrow`, `cancelled` |
| `GET /reports/summary` | `laporan` | `period=today\|7days\|month\|custom` (+`from`,`to`), `group_by=day\|month` → `omzet, transactions, received, receivable, expense, profit, by_method{tunai,qris}, breakdown[]` |
| `GET /reports/downloads` | `laporan` | 50 riwayat unduhan terbaru `{id,user_name,format,period_label,period_from,period_to,sections[],downloaded_at}` |
| `POST /reports/downloads` | `laporan` | `period_label, from, to, sections[] (ringkasan\|harian\|transaksi\|rincianLayanan\|layananTerlaris\|pembayaran\|pengeluaran), format=pdf` → catat unduhan (201); `downloaded_at` memakai jam server |

Aturan laporan: transaksi batal tidak dihitung; omzet = total transaksi yang **dibuat** pada periode; piutang = omzet − sudah diterima; laba = omzet − pengeluaran.

## Contoh curl

```bash
# login
curl -s -X POST http://localhost:8000/api/auth/login -H 'Accept: application/json' \
  -d 'email=admin@laundryku.com' -d 'password=admin123'

# buat transaksi (ganti TOKEN)
curl -s -X POST http://localhost:8000/api/orders \
  -H 'Accept: application/json' -H 'Content-Type: application/json' -H 'Authorization: Bearer TOKEN' \
  -d '{"customer_id":1,"items":[{"service_id":4,"qty":3.5}],"first_payment":{"method":"tunai","amount":10000}}'
```
