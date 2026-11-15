<?php

namespace App\Services;

use App\Models\Business;
use App\Models\Customer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusLog;
use App\Models\Payment;
use App\Models\Service;
use App\Models\User;
use App\Support\Format;
use App\Support\OrderStatus;
use App\Support\Permissions;
use Illuminate\Database\QueryException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

/**
 * Seluruh aturan bisnis transaksi ada di sini. Harga, nama, dan durasi layanan SELALU diambil
 * dari database (bukan dari klien), lalu disalin ke item transaksi.
 */
class OrderService
{
    /**
     * @param  array<int, array{service_id:int|string, qty:int|float|string}>  $lines
     * @param  array{method:string, amount:int}|null  $firstPayment
     */
    public function create(
        Business $business,
        ?User $actor,
        Customer $customer,
        array $lines,
        ?string $note = null,
        ?array $firstPayment = null,
        ?Carbon $at = null,
    ): Order {
        $at = $at ?: Carbon::now();

        $services = Service::with('category')
            ->ofBusiness($business->id)
            ->whereIn('id', array_map(fn ($l) => (int) $l['service_id'], $lines))
            ->get()
            ->keyBy('id');

        $items = [];
        $total = 0;
        $maxHours = 0;
        foreach ($lines as $i => $line) {
            /** @var Service|null $svc */
            $svc = $services->get((int) $line['service_id']);
            if (! $svc) {
                throw ValidationException::withMessages(["items.$i.service_id" => 'Layanan tidak ditemukan.']);
            }
            if (! $svc->active) {
                throw ValidationException::withMessages(["items.$i.service_id" => "Layanan {$svc->name} sedang nonaktif."]);
            }
            $qty = round((float) $line['qty'], 2);
            if ($qty <= 0 || $qty < $svc->min_qty) {
                throw ValidationException::withMessages(["items.$i.qty" => "Jumlah minimal {$svc->min_qty} {$svc->unit}."]);
            }

            $subtotal = (int) round($qty * $svc->price);
            $total += $subtotal;
            $maxHours = max($maxHours, $svc->duration_hours);
            $items[] = [
                'service_id' => $svc->id,
                'name' => Format::serviceFullName($svc->category->name, $svc->name),
                'unit' => $svc->unit,
                'price' => $svc->price,
                'qty' => $qty,
                'duration_hours' => $svc->duration_hours,
                'subtotal' => $subtotal,
            ];
        }

        $dueAt = $at->copy()->addHours($maxHours);

        // Nomor invoice per hari per usaha. Jika dua kasir menyimpan bersamaan, unique index
        // menolak salah satunya dan kita coba lagi dengan nomor berikutnya.
        for ($attempt = 1; $attempt <= 5; $attempt++) {
            try {
                return DB::transaction(function () use ($business, $actor, $customer, $items, $total, $note, $firstPayment, $at, $dueAt) {
                    $order = new Order([
                        'business_id' => $business->id,
                        'invoice' => $this->nextInvoice($business->id, $at),
                        'customer_id' => $customer->id,
                        'customer_name' => $customer->name,
                        'customer_phone' => $customer->phone,
                        'status' => 'antrian',
                        'note' => $note,
                        'created_by' => $actor?->id,
                        'total' => $total,
                        'paid' => 0,
                        'due_at' => $dueAt,
                    ]);
                    $order->created_at = $at;
                    $order->updated_at = $at;
                    $order->save();

                    foreach ($items as $item) {
                        OrderItem::create($item + ['order_id' => $order->id]);
                    }

                    OrderStatusLog::create([
                        'order_id' => $order->id,
                        'status' => 'antrian',
                        'logged_at' => $at,
                        'user_id' => $actor?->id,
                    ]);

                    if ($firstPayment && (int) $firstPayment['amount'] > 0) {
                        $amount = min((int) $firstPayment['amount'], $total);
                        Payment::create([
                            'order_id' => $order->id,
                            'method' => $firstPayment['method'],
                            'amount' => $amount,
                            'paid_at' => $at,
                            'created_by' => $actor?->id,
                        ]);
                        $order->paid = $amount;
                        $order->save();
                    }

                    return $this->fresh($order);
                });
            } catch (QueryException $e) {
                $duplicate = in_array((string) $e->getCode(), ['23000', '23505'], true);
                if (! $duplicate || $attempt === 5) {
                    throw $e;
                }
            }
        }

        throw new \RuntimeException('Gagal membuat nomor invoice.');
    }

    /** Maju ke status berikutnya (antrian -> diproses -> selesai -> diambil). */
    public function advance(int $orderId, int $businessId, User $actor, string $to): Order
    {
        return DB::transaction(function () use ($orderId, $businessId, $actor, $to) {
            $order = Order::ofBusiness($businessId)->lockForUpdate()->findOrFail($orderId);

            if ($order->cancelled) {
                abort(422, 'Transaksi sudah dibatalkan, status tidak dapat diubah.');
            }
            $next = OrderStatus::next($order->status);
            if ($next === null) {
                abort(422, 'Transaksi sudah berstatus Diambil.');
            }
            if ($to !== $next) {
                abort(422, 'Status hanya boleh maju satu langkah ke ' . OrderStatus::label($next) . '.');
            }

            $order->status = $next;
            $order->save();
            OrderStatusLog::create([
                'order_id' => $order->id,
                'status' => $next,
                'logged_at' => Carbon::now(),
                'user_id' => $actor->id,
            ]);

            return $this->fresh($order);
        });
    }

    /** Catat pembayaran. Nominal dipotong sampai sisa tagihan. */
    public function addPayment(int $orderId, int $businessId, User $actor, string $method, int $amount): Order
    {
        return DB::transaction(function () use ($orderId, $businessId, $actor, $method, $amount) {
            $order = Order::ofBusiness($businessId)->lockForUpdate()->findOrFail($orderId);

            if ($order->cancelled) {
                abort(422, 'Transaksi sudah dibatalkan.');
            }
            if ($order->remaining <= 0) {
                abort(422, 'Transaksi ini sudah lunas.');
            }

            $amount = min($amount, $order->remaining);
            Payment::create([
                'order_id' => $order->id,
                'method' => $method,
                'amount' => $amount,
                'paid_at' => Carbon::now(),
                'created_by' => $actor->id,
            ]);
            $order->paid += $amount;
            $order->save();

            return $this->fresh($order);
        });
    }

    /** Batalkan transaksi (tidak dihitung di laporan). Tidak bisa diurungkan. */
    public function cancel(int $orderId, int $businessId, User $actor): Order
    {
        return DB::transaction(function () use ($orderId, $businessId, $actor) {
            $order = Order::ofBusiness($businessId)->lockForUpdate()->findOrFail($orderId);

            if ($order->cancelled) {
                abort(422, 'Transaksi sudah dibatalkan.');
            }
            if ($order->status === 'diambil') {
                abort(422, 'Transaksi yang sudah diambil tidak dapat dibatalkan.');
            }
            if ($order->paid > 0 && ! $actor->hasPermission(Permissions::BATAL_BAYAR)) {
                abort(403, 'Anda tidak memiliki izin membatalkan transaksi yang sudah dibayar.');
            }

            $order->cancelled = true;
            $order->cancelled_at = Carbon::now();
            $order->cancelled_by = $actor->id;
            $order->save();

            return $this->fresh($order);
        });
    }

    public function fresh(Order $order): Order
    {
        return $order->fresh(['items', 'payments', 'logs']);
    }

    private function nextInvoice(int $businessId, Carbon $at): string
    {
        $prefix = 'INV-' . $at->format('ymd') . '-';
        $last = Order::ofBusiness($businessId)->where('invoice', 'like', $prefix . '%')->max('invoice');
        $n = $last ? ((int) substr($last, -4)) + 1 : 1;

        return $prefix . str_pad((string) $n, 4, '0', STR_PAD_LEFT);
    }
}
