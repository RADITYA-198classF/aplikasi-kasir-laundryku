<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Customer extends Model
{
    use SoftDeletes;

    protected $fillable = ['business_id', 'name', 'phone'];

    public function scopeOfBusiness(Builder $q, int $businessId): Builder
    {
        return $q->where('business_id', $businessId);
    }

    public function toApi(): array
    {
        return ['id' => (string) $this->id, 'name' => $this->name, 'phone' => $this->phone ?? ''];
    }
}
