<?php

namespace App\Support;

/** Alur cucian: antrian -> diproses -> selesai -> diambil. */
final class OrderStatus
{
    public const FLOW = ['antrian', 'diproses', 'selesai', 'diambil'];

    public static function next(string $status): ?string
    {
        $i = array_search($status, self::FLOW, true);
        if ($i === false) {
            return null;
        }

        return self::FLOW[$i + 1] ?? null;
    }

    public static function label(string $status): string
    {
        return ucfirst($status);
    }
}
