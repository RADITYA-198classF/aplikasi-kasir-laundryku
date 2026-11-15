<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Service extends Model
{
    protected $fillable = [
        'business_id', 'service_category_id', 'name', 'unit', 'price',
        'min_qty', 'duration_value', 'duration_unit', 'active',
    ];

    protected $casts = [
        'price' => 'integer',
        'min_qty' => 'float',
        'duration_value' => 'integer',
        'active' => 'boolean',
    ];

    public function category(): BelongsTo
    {
        return $this->belongsTo(ServiceCategory::class, 'service_category_id');
    }

    public function scopeOfBusiness(Builder $q, int $businessId): Builder
    {
        return $q->where('business_id', $businessId);
    }

    public function getDurationHoursAttribute(): int
    {
        return $this->duration_value * ($this->duration_unit === 'hari' ? 24 : 1);
    }

    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'category_id' => (string) $this->service_category_id,
            'name' => $this->name,
            'unit' => $this->unit,
            'price' => $this->price,
            'min_qty' => $this->min_qty,
            'duration_value' => $this->duration_value,
            'duration_unit' => $this->duration_unit,
            'duration_hours' => $this->duration_hours,
            'active' => $this->active,
        ];
    }
}
