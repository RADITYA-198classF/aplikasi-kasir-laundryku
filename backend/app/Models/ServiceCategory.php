<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ServiceCategory extends Model
{
    protected $fillable = ['business_id', 'name', 'flow'];

    public function services(): HasMany
    {
        return $this->hasMany(Service::class);
    }

    public function scopeOfBusiness(Builder $q, int $businessId): Builder
    {
        return $q->where('business_id', $businessId);
    }

    public function toApi(): array
    {
        return ['id' => (string) $this->id, 'name' => $this->name, 'flow' => $this->flow];
    }
}
