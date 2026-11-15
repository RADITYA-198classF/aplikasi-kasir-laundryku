<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderItem extends Model
{
    public $timestamps = false;

    protected $fillable = ['order_id', 'service_id', 'name', 'unit', 'price', 'qty', 'duration_hours', 'subtotal'];

    protected $casts = [
        'price' => 'integer',
        'qty' => 'float',
        'duration_hours' => 'integer',
        'subtotal' => 'integer',
    ];

    public function toApi(): array
    {
        return [
            'service_id' => $this->service_id === null ? '' : (string) $this->service_id,
            'name' => $this->name,
            'unit' => $this->unit,
            'price' => $this->price,
            'qty' => $this->qty,
            'duration_hours' => $this->duration_hours,
            'subtotal' => $this->subtotal,
        ];
    }
}
