<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Support\Permissions;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

/** Kelola karyawan: khusus owner (middleware OwnerOnly di routes/api.php). */
class EmployeeController extends Controller
{
    private function find(Request $request, string $id): User
    {
        return User::where('business_id', $this->businessId($request))
            ->where('role', User::ROLE_EMPLOYEE)
            ->findOrFail($id);
    }

    /** GET /employees */
    public function index(Request $request): JsonResponse
    {
        $list = User::where('business_id', $this->businessId($request))
            ->where('role', User::ROLE_EMPLOYEE)
            ->orderBy('id')
            ->get();

        return response()->json($list->map->toEmployeeApi()->values());
    }

    /** POST /employees */
    public function store(Request $request): JsonResponse
    {
        $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);

        $data = Validator::make($request->all(), [
            'name' => 'required|string|max:120',
            'phone' => 'nullable|string|max:32',
            'email' => 'required|email|max:190|unique:users,email',
            'password' => 'required|string|min:6|max:100',
            'permissions' => 'nullable|array',
            'permissions.*' => ['string', Rule::in(Permissions::ALL)],
        ], [
            'email.unique' => 'Email sudah dipakai akun lain.',
            'email.email' => 'Email tidak valid.',
            'name.required' => 'Nama karyawan wajib diisi.',
            'password.min' => 'Password minimal 6 karakter.',
        ])->validate();

        $employee = User::create([
            'business_id' => $this->businessId($request),
            'name' => $data['name'],
            'email' => $data['email'],
            'phone' => $data['phone'] ?? null,
            'password' => $data['password'],
            'role' => User::ROLE_EMPLOYEE,
            'permissions' => array_values(array_unique($data['permissions'] ?? [])),
        ]);

        return response()->json($employee->toEmployeeApi(), 201);
    }

    /** PUT /employees/{id}: ubah data dan/atau hak akses. */
    public function update(Request $request, string $id): JsonResponse
    {
        $employee = $this->find($request, $id);

        if ($request->has('email')) {
            $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);
        }

        $data = Validator::make($request->all(), [
            'name' => 'sometimes|required|string|max:120',
            'phone' => 'sometimes|nullable|string|max:32',
            'email' => ['sometimes', 'required', 'email', 'max:190', Rule::unique('users', 'email')->ignore($employee->id)],
            'permissions' => 'sometimes|array',
            'permissions.*' => ['string', Rule::in(Permissions::ALL)],
        ], ['email.unique' => 'Email sudah dipakai akun lain.'])->validate();

        if (isset($data['permissions'])) {
            $data['permissions'] = array_values(array_unique($data['permissions']));
        }
        $employee->update($data);

        return response()->json($employee->fresh()->toEmployeeApi());
    }

    /** DELETE /employees/{id}: akun dihapus, sesi login dicabut, riwayat transaksi tetap ada. */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $employee = $this->find($request, $id);
        $employee->tokens()->delete();
        $employee->delete();

        return response()->json(['message' => 'Karyawan dihapus.']);
    }

    /** PUT /employees/{id}/password: owner mengganti password karyawan tanpa password lama. */
    public function resetPassword(Request $request, string $id): JsonResponse
    {
        $employee = $this->find($request, $id);
        $data = $request->validate(
            ['new_password' => 'required|string|min:6|max:100'],
            ['new_password.min' => 'Password minimal 6 karakter.'],
        );

        $employee->forceFill(['password' => $data['new_password']])->save();
        $employee->tokens()->delete(); // paksa login ulang dengan password baru

        return response()->json(['message' => 'Password karyawan diganti.']);
    }
}
