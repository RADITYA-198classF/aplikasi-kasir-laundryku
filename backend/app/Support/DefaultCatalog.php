<?php

namespace App\Support;

use App\Models\Business;
use App\Models\Service;
use App\Models\ServiceCategory;

/** Katalog layanan bawaan untuk usaha yang baru mendaftar (sama dengan data awal di aplikasi). */
final class DefaultCatalog
{
    public static function seed(Business $business): void
    {
        $categories = [
            'Cuci Kiloan' => 'Cuci -> Pengeringan -> Setrika',
            'Bed Cover' => 'Cuci -> Pengeringan',
            'Boneka' => 'Cuci -> Pengeringan',
            'Sepatu' => 'Cuci -> Pengeringan',
            'Tas' => 'Cuci -> Pengeringan -> Setrika',
            'Karpet' => 'Cuci -> Pengeringan',
        ];

        $ids = [];
        foreach ($categories as $name => $flow) {
            $ids[$name] = ServiceCategory::create([
                'business_id' => $business->id,
                'name' => $name,
                'flow' => $flow,
            ])->id;
        }

        // [kategori, nama, satuan, harga, min, durasi, satuan durasi]
        $rows = [
            ['Cuci Kiloan', 'Express 1 Hari', 'kg', 15000, 0, 1, 'hari'],
            ['Cuci Kiloan', 'Express 3 Jam', 'kg', 25000, 0, 3, 'jam'],
            ['Cuci Kiloan', 'Express 6 Jam', 'kg', 20000, 0, 6, 'jam'],
            ['Cuci Kiloan', 'Reguler 2 Hari', 'kg', 10000, 0, 2, 'hari'],
            ['Cuci Kiloan', 'Reguler 3 Hari', 'kg', 7000, 0, 3, 'hari'],
            ['Bed Cover', 'King', 'pcs', 25000, 1, 3, 'hari'],
            ['Bed Cover', 'Queen', 'pcs', 18000, 1, 3, 'hari'],
            ['Bed Cover', 'Single', 'pcs', 15000, 1, 3, 'hari'],
            ['Boneka', 'Besar', 'pcs', 25000, 1, 5, 'hari'],
            ['Boneka', 'Kecil', 'pcs', 20000, 1, 5, 'hari'],
            ['Sepatu', 'Deep Clean', 'pcs', 35000, 1, 3, 'hari'],
            ['Sepatu', 'Fast Clean', 'pcs', 25000, 1, 3, 'hari'],
            ['Tas', 'Besar', 'pcs', 20000, 1, 3, 'hari'],
            ['Tas', 'Kecil', 'pcs', 15000, 1, 3, 'hari'],
            ['Karpet', 'Standar', 'm2', 15000, 1, 7, 'hari'],
            ['Karpet', 'Turki', 'm2', 25000, 1, 7, 'hari'],
        ];

        foreach ($rows as [$cat, $name, $unit, $price, $min, $dur, $durUnit]) {
            Service::create([
                'business_id' => $business->id,
                'service_category_id' => $ids[$cat],
                'name' => $name,
                'unit' => $unit,
                'price' => $price,
                'min_qty' => $min,
                'duration_value' => $dur,
                'duration_unit' => $durUnit,
                'active' => true,
            ]);
        }
    }
}
