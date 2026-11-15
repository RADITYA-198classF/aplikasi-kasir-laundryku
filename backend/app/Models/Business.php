<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class Business extends Model
{
    protected $fillable = ['name', 'phone', 'hours', 'owner_wa'];

    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function owner(): HasOne
    {
        return $this->hasOne(User::class)->where('role', User::ROLE_OWNER);
    }

    /** Padanan BusinessProfile di Flutter. */
    public function toProfile(): array
    {
        $owner = $this->owner;

        return [
            'business_name' => $this->name,
            'owner_name' => $owner?->name ?? '',
            'email' => $owner?->email ?? '',
            'phone' => $this->phone ?? '',
            'hours' => $this->hours ?? '',
            'owner_wa' => $this->owner_wa ?? '',
        ];
    }
}
