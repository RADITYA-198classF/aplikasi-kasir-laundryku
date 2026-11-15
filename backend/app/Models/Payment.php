<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    public $timestamps = false;

    protected $fillable = ['order_id', 'method', 'amount', 'paid_at', 'created_by'];

    protected $casts = [
        'amount' => 'integer',
        'paid_at' => 'datetime',
    ];

    public function toApi(): array
    {
        return [
            'id' => (string) $this->id,
            'date' => $this->paid_at->toIso8601String(),
            'method' => $this->method,
            'amount' => $this->amount,
        ];
    }
}
