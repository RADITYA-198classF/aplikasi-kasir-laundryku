<?php

namespace App\Support;

/**
 * Hak akses karyawan. Kunci HARUS sama dengan nama enum AppPermission di Flutter.
 * Owner otomatis punya semua hak akses.
 */
final class Permissions
{
    public const TRANSAKSI = 'transaksi';       // buat transaksi, ubah status, catat pembayaran
    public const BATAL_BAYAR = 'batalBayar';    // batalkan transaksi yang sudah ada pembayarannya
    public const LAYANAN = 'layanan';           // aktif/nonaktifkan layanan
    public const PENGELUARAN = 'pengeluaran';   // catat & hapus pengeluaran
    public const LAPORAN = 'laporan';           // akses laporan

    public const ALL = [
        self::TRANSAKSI,
        self::BATAL_BAYAR,
        self::LAYANAN,
        self::PENGELUARAN,
        self::LAPORAN,
    ];
}
