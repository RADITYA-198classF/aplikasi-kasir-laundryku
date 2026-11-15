<?php

namespace App\Models;

use App\Support\Permissions;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens;

    public const ROLE_OWNER = 'owner';
    public const ROLE_EMPLOYEE = 'employee';

    protected $fillable = ['business_id', 'name', 'email', 'phone', 'password', 'role', 'permissions'];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'permissions' => 'array',
    ];

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function isOwner(): bool
    {
        return $this->role === self::ROLE_OWNER;
    }

    public function hasPermission(string $permission): bool
    {
        return $this->isOwner() || in_array($permission, $this->permissions ?? [], true);
    }

    /** @return string[] */
    public function permissionList(): array
    {
        return $this->isOwner() ? Permissions::ALL : array_values($this->permissions ?? []);
    }

    /** Padanan AuthSession di Flutter. */
    public function toSession(): array
    {
        return [
            'name' => $this->name,
            'employee_id' => $this->isOwner() ? null : (string) $this->id,
            'role' => $this->role,
            'permissions' => $this->permissionList(),
        ];
    }

    /** Padanan Employee di Flutter. */
    public function toEmployeeApi(): array
    {
        return [
            'id' => (string) $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'phone' => $this->phone ?? '',
            'permissions' => array_values($this->permissions ?? []),
        ];
    }
}
