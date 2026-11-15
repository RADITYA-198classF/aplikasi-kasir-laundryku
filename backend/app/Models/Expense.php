<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    protected $fillable = ['business_id', 'date', 'category', 'amount', 'note', 'created_by'];

    protected $casts = [
        'date' => 'date:Y-m-d',
        'amount' => 'integer',
    ];

    public function scopeOfBusiness(Builder $q, int $businessId): Builder
    {
        return $q->where('business_id', $businessId);
    }

    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'date' => $this->date->format('Y-m-d'),
            'category' => $this->category,
            'amount' => $this->amount,
            'note' => $this->note ?? '',
        ];
    }
}
