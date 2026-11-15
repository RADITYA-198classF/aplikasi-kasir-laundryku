<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OrderStatusLog extends Model
{
    public $timestamps = false;

    protected $fillable = ['order_id', 'status', 'logged_at', 'user_id'];

    protected $casts = ['logged_at' => 'datetime'];

    public function toApi(): array
    {
        return ['status' => $this->status, 'time' => $this->logged_at->toIso8601String()];
    }
}
