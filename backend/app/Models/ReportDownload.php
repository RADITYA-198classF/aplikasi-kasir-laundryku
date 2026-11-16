<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class ReportDownload extends Model
{
    public $timestamps = false;

    /** Kunci isi laporan; HARUS sama dengan nama enum ReportSection di Flutter. */
    public const SECTIONS = [
        'ringkasan', 'harian', 'transaksi', 'rincianLayanan',
        'layananTerlaris', 'pembayaran', 'pengeluaran',
    ];

    protected $fillable = [
        'business_id', 'user_id', 'user_name', 'format',
        'period_label', 'period_from', 'period_to', 'sections', 'downloaded_at',
    ];

    protected $casts = [
        'sections' => 'array',
        'period_from' => 'date:Y-m-d',
        'period_to' => 'date:Y-m-d',
        'downloaded_at' => 'datetime',
    ];

    public function scopeOfBusiness(Builder $q, int $businessId): Builder
    {
        return $q->where('business_id', $businessId);
    }

    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'user_name' => $this->user_name ?? '',
            'format' => $this->format,
            'period_label' => $this->period_label,
            'period_from' => $this->period_from->format('Y-m-d'),
            'period_to' => $this->period_to->format('Y-m-d'),
            'sections' => array_values($this->sections ?? []),
            'downloaded_at' => $this->downloaded_at->toIso8601String(),
        ];
    }
}
