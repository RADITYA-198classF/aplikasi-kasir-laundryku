<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;

abstract class Controller
{
    protected function authUser(Request $request): User
    {
        /** @var User $user */
        $user = $request->user();

        return $user;
    }

    /** Semua data selalu dibatasi pada usaha milik user yang login. */
    protected function businessId(Request $request): int
    {
        return (int) $this->authUser($request)->business_id;
    }
}
