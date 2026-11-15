<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\User;
use App\Support\DefaultCatalog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AuthController extends Controller
{
    /** POST /auth/login */
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email' => 'required|string',
            'password' => 'required|string',
        ]);

        $user = User::where('email', strtolower(trim($data['email'])))->first();
        if (! $user || ! Hash::check($data['password'], $user->password)) {
            return response()->json(['message' => 'Email atau password salah.'], 401);
        }

        return response()->json([
            'token' => $user->createToken('mobile')->plainTextToken,
            'session' => $user->toSession(),
        ]);
    }

    /** POST /auth/register: mendaftarkan usaha baru + akun owner + katalog layanan bawaan. */
    public function register(Request $request): JsonResponse
    {
        $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);

        $data = Validator::make($request->all(), [
            'business_name' => 'required|string|max:120',
            'owner_name' => 'required|string|max:120',
            'email' => 'required|email|max:190|unique:users,email',
            'phone' => ['required', 'string', 'max:32', function ($attr, $value, $fail) {
                if (strlen(preg_replace('/[^0-9]/', '', (string) $value)) < 9) {
                    $fail('Nomor HP tidak valid.');
                }
            }],
            'password' => 'required|string|min:6|max:100',
        ], [
            'email.unique' => 'Email sudah terdaftar. Silakan masuk.',
            'email.email' => 'Email tidak valid.',
            'password.min' => 'Password minimal 6 karakter.',
        ])->validate();

        DB::transaction(function () use ($data) {
            $business = Business::create(['name' => $data['business_name'], 'phone' => $data['phone']]);
            User::create([
                'business_id' => $business->id,
                'name' => $data['owner_name'],
                'email' => $data['email'],
                'phone' => $data['phone'],
                'password' => $data['password'],
                'role' => User::ROLE_OWNER,
            ]);
            DefaultCatalog::seed($business);
        });

        return response()->json(['message' => 'Pendaftaran berhasil. Silakan masuk.'], 201);
    }

    /** GET /auth/me */
    public function me(Request $request): JsonResponse
    {
        return response()->json(['session' => $this->authUser($request)->toSession()]);
    }

    /** POST /auth/logout: mencabut token perangkat ini saja. */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Berhasil keluar.']);
    }

    /** PUT /auth/password: mengganti password akun yang sedang login (owner maupun karyawan). */
    public function changePassword(Request $request): JsonResponse
    {
        $data = $request->validate([
            'old_password' => 'required|string',
            'new_password' => 'required|string|min:6|max:100',
        ], ['new_password.min' => 'Password minimal 6 karakter.']);

        $user = $this->authUser($request);
        if (! Hash::check($data['old_password'], $user->password)) {
            return response()->json(['message' => 'Password lama salah.', 'code' => 'wrong_password'], 422);
        }

        $user->forceFill(['password' => $data['new_password']])->save(); // di-hash otomatis oleh cast

        // Cabut sesi di perangkat lain, pertahankan sesi ini.
        $current = $user->currentAccessToken();
        $others = $user->tokens();
        if ($current && isset($current->id)) {
            $others->where('id', '!=', $current->id);
        }
        $others->delete();

        return response()->json(['message' => 'Password berhasil diganti.']);
    }
}
