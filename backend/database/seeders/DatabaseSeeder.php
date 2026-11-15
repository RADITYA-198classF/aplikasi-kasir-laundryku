<?php

namespace Database\Seeders;

use App\Models\Business;
use App\Models\Customer;
use App\Models\Expense;
use App\Models\OrderStatusLog;
use App\Models\Service;
use App\Models\User;
use App\Services\OrderService;
use App\Support\DefaultCatalog;
use App\Support\OrderStatus;
use Illuminate\Database\Seeder;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Data demo yang sama dengan MockLaundryRepository di aplikasi:
 *   owner     admin@laundryku.com / admin123
 *   karyawan  sari@laundryku.com  / sari123  (hak: transaksi, pengeluaran)
 */
class DatabaseSeeder extends Seeder
{
    /** [hari lalu, jam, indeks pelanggan, [[nomor layanan, qty], ...], status, porsi dibayar, metode] */
    private const ORDERS = [
        [6, 8, 0, [[5, 4]], 'diambil', 1, 'tunai'],
        [6, 10, 3, [[4, 3.5], [12, 1]], 'diambil', 1, 'qris'],
        [5, 9, 1, [[1, 2.5]], 'diambil', 1, 'qris'],
        [5, 14, 2, [[2, 2]], 'diambil', 1, 'tunai'],
        [4, 8, 4, [[7, 1]], 'diambil', 1, 'tunai'],
        [4, 9, 5, [[4, 3]], 'diproses', 0, 'tunai'],
        [3, 10, 0, [[13, 1], [15, 3]], 'diambil', 1, 'tunai'],
        [3, 13, 3, [[4, 4.5]], 'selesai', 0, 'tunai'],
        [2, 8, 1, [[5, 5]], 'diproses', 0.5, 'tunai'],
        [2, 11, 4, [[9, 2]], 'diproses', 0, 'tunai'],
        [5, 15, 2, [[4, 2]], 'diproses', 0, 'tunai'],
        [1, 9, 5, [[1, 2]], 'antrian', 1, 'qris'],
        [1, 12, 0, [[4, 5.5]], 'selesai', 1, 'tunai'],
        [0, 8, 3, [[2, 1.5]], 'selesai', 1, 'qris'],
        [0, 10, 1, [[5, 4]], 'antrian', 0.5, 'tunai'],
        [0, 12, 4, [[11, 2]], 'diproses', 0, 'tunai'],
        [0, 14, 2, [[6, 1], [8, 1]], 'antrian', 1, 'tunai'],
    ];

    public function run(): void
    {
        if (User::where('email', 'admin@laundryku.com')->exists()) {
            $this->command?->warn('Data demo sudah ada, seeder dilewati.');

            return;
        }

        DB::transaction(function () {
            $business = Business::create([
                'name' => 'LaundryKu Surabaya',
                'phone' => '081234567890',
                'hours' => '08.00 - 20.00',
            ]);

            User::create([
                'business_id' => $business->id,
                'name' => 'Admin',
                'email' => 'admin@laundryku.com',
                'phone' => '081234567890',
                'password' => 'admin123',
                'role' => User::ROLE_OWNER,
            ]);

            $sari = User::create([
                'business_id' => $business->id,
                'name' => 'Sari',
                'email' => 'sari@laundryku.com',
                'phone' => '081298765432',
                'password' => 'sari123',
                'role' => User::ROLE_EMPLOYEE,
                'permissions' => ['transaksi', 'pengeluaran'],
            ]);

            DefaultCatalog::seed($business);

            $customers = collect([
                ['Budi Santoso', '081234567891'],
                ['Siti Rahmawati', '082145678901'],
                ['Andi Pratama', '085233344455'],
                ['Dewi Lestari', '081377788899'],
                ['Rizky Maulana', '087855566677'],
                ['Nadia Putri', '089612345678'],
            ])->map(fn ($c) => Customer::create(['business_id' => $business->id, 'name' => $c[0], 'phone' => $c[1]]))->values();

            // "svc-N" pada data demo = layanan ke-N menurut urutan katalog bawaan.
            $services = Service::ofBusiness($business->id)->orderBy('id')->get()->values();

            $this->seedOrders($business, $sari, $customers, $services);

            foreach ([
                [1, 'Deterjen & Pewangi', 85000, 'Deterjen 5 kg'],
                [2, 'Gas / LPG', 60000, null],
                [3, 'Listrik', 250000, 'Token listrik'],
                [5, 'Internet & Pulsa', 100000, null],
            ] as [$daysAgo, $category, $amount, $note]) {
                Expense::create([
                    'business_id' => $business->id,
                    'date' => Carbon::today()->subDays($daysAgo)->toDateString(),
                    'category' => $category,
                    'amount' => $amount,
                    'note' => $note,
                ]);
            }
        });
    }

    private function seedOrders(Business $business, User $actor, $customers, $services): void
    {
        $orders = app(OrderService::class);
        $now = Carbon::now();
        $today = Carbon::today();

        $seeds = self::ORDERS;
        usort($seeds, fn ($a, $b) => $b[0] <=> $a[0] ?: $a[1] <=> $b[1]); // lama -> baru, supaya nomor invoice berurutan

        foreach ($seeds as [$daysAgo, $hour, $custIdx, $lines, $status, $share, $method]) {
            $day = $today->copy()->subDays($daysAgo);
            $created = $day->copy()->addHours($hour);
            if ($created->gt($now)) {
                $created = $day->copy()->addMinutes((int) floor($day->diffInMinutes($now, true) * $hour / 18));
            }

            $total = 0;
            $payload = [];
            foreach ($lines as [$n, $qty]) {
                $svc = $services[$n - 1];
                $payload[] = ['service_id' => $svc->id, 'qty' => $qty];
                $total += (int) round($qty * $svc->price);
            }
            $paid = (int) round($total * $share);

            $order = $orders->create(
                $business,
                $actor,
                $customers[$custIdx],
                $payload,
                null,
                $paid > 0 ? ['method' => $method, 'amount' => $paid] : null,
                $created,
            );

            // Riwayat status sampai status akhirnya (tiap langkah +8 jam, tidak melewati "sekarang").
            $target = array_search($status, OrderStatus::FLOW, true);
            for ($i = 1; $i <= $target; $i++) {
                $t = $created->copy()->addHours($i * 8);
                if ($t->gt($now)) {
                    $t = $now->copy();
                }
                OrderStatusLog::create([
                    'order_id' => $order->id,
                    'status' => OrderStatus::FLOW[$i],
                    'logged_at' => $t,
                    'user_id' => $actor->id,
                ]);
            }
            $order->update(['status' => $status]);
        }
    }
}
