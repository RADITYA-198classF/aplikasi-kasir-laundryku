<?php

namespace App\Models;

use App\Support\OrderStatus;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Carbon;

class Order extends Model
{
    protected $fillable = [
        'business_id', 'invoice', 'customer_id', 'customer_name', 'customer_phone',
        'status', 'note', 'cancelled', 'cancelled_at', 'cancelled_by', 'created_by',
        'total', 'paid', 'due_at',
    ];

    protected $casts = [
        'cancelled' => 'boolean',
        'cancelled_at' => 'datetime',
        'due_at' => 'datetime',
        'total' => 'integer',
        'paid' => 'integer',
    ];

    public function customer(): BelongsTo
    {
        return $this->belongsTo(Customer::class)->withTrashed();
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class)->orderBy('id');
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class)->orderBy('paid_at')->orderBy('id');
    }

    public function logs(): HasMany
    {
        return $this->hasMany(OrderStatusLog::class)->orderBy('logged_at')->orderBy('id');
    }

    public function scopeOfBusiness(Builder $q, int $businessId): Builder
    {
        return $q->where('business_id', $businessId);
    }

    /** Transaksi yang dibatalkan tidak dihitung di omzet maupun laporan. */
    public function scopeCounted(Builder $q): Builder
    {
        return $q->where('cancelled', false);
    }

    /** Rentang tanggal [dari, sampai] inklusif, berdasarkan waktu transaksi dibuat. */
    public function scopeCreatedBetween(Builder $q, Carbon $from, Carbon $to): Builder
    {
        return $q->where('created_at', '>=', $from->copy()->startOfDay())
            ->where('created_at', '<', $to->copy()->startOfDay()->addDay());
    }

    public function getRemainingAttribute(): int
    {
        return max($this->total - $this->paid, 0);
    }

    /** Belum selesai dikerjakan. */
    public function isActive(): bool
    {
        return ! $this->cancelled && in_array($this->status, ['antrian', 'diproses'], true);
    }

    public function isOverdue(?Carbon $now = null): bool
    {
        $now = $now ?: Carbon::now();

        return $this->isActive() && $this->due_at->copy()->startOfDay()->lt($now->copy()->startOfDay());
    }

    /** Padanan LaundryOrder di Flutter. */
    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'invoice' => $this->invoice,
            'customer_id' => $this->customer_id === null ? '' : (string) $this->customer_id,
            'customer_name' => $this->customer_name,
            'customer_phone' => $this->customer_phone ?? '',
            'status' => $this->status,
            'status_label' => OrderStatus::label($this->status),
            'note' => $this->note ?? '',
            'cancelled' => $this->cancelled,
            'created_at' => $this->created_at->toIso8601String(),
            'due_at' => $this->due_at->toIso8601String(),
            'total' => $this->total,
            'paid' => $this->paid,
            'remaining' => $this->remaining,
            'is_paid' => $this->remaining === 0,
            'is_overdue' => $this->isOverdue(),
            'items' => $this->items->map->toApi()->values()->all(),
            'payments' => $this->payments->map->toApi()->values()->all(),
            'logs' => $this->logs->map->toApi()->values()->all(),
        ];
    }
}
