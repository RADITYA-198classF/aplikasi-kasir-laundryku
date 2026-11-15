<?php

namespace App\Support;

use Carbon\CarbonInterface;

/** Padanan fungsi format.dart di Flutter (dipakai untuk pesan WhatsApp dan laporan). */
final class Format
{
    private const BULAN = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

    /** 12500 -> "Rp 12.500" */
    public static function rupiah(int|float $value): string
    {
        $neg = $value < 0 ? '-' : '';

        return $neg . 'Rp ' . number_format((int) round(abs($value)), 0, ',', '.');
    }

    /** 2026-11-04 -> "4 Nov 2026" */
    public static function tanggal(CarbonInterface $d): string
    {
        return $d->day . ' ' . self::BULAN[$d->month - 1] . ' ' . $d->year;
    }

    /** 0812-3456-7890 -> 6281234567890 (format wa.me) */
    public static function normalizePhone(?string $raw): string
    {
        $d = preg_replace('/[^0-9]/', '', (string) $raw);
        if ($d === '') {
            return '';
        }
        if (str_starts_with($d, '0')) {
            return '62' . substr($d, 1);
        }
        if (str_starts_with($d, '8')) {
            return '62' . $d;
        }

        return $d;
    }

    /** Nama layanan di keranjang: kategori "Cuci Kiloan" tidak ditulis. */
    public static function serviceFullName(string $categoryName, string $serviceName): string
    {
        return str_contains(mb_strtolower($categoryName), 'kiloan')
            ? $serviceName
            : $categoryName . ' ' . $serviceName;
    }
}
