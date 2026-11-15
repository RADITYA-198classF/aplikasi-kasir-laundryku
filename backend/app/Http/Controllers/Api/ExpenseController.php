<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Support\Permissions;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class ExpenseController extends Controller
{
    private function rules(): array
    {
        return [
            'date' => 'required|date_format:Y-m-d',
            'category' => 'required|string|max:100',
            'amount' => 'required|integer|min:1|max:100000000000',
            'note' => 'nullable|string|max:255',
        ];
    }

    /**
     * GET /expenses?from=YYYY-MM-DD&to=YYYY-MM-DD
     * Aplikasi memuat pengeluaran saat login untuk semua akun, jadi akun tanpa hak "pengeluaran"
     * atau "laporan" mendapat daftar kosong (bukan error 403).
     */
    public function index(Request $request): JsonResponse
    {
        $user = $this->authUser($request);
        if (! $user->hasPermission(Permissions::PENGELUARAN) && ! $user->hasPermission(Permissions::LAPORAN)) {
            return response()->json([]);
        }

        $request->validate(['from' => 'nullable|date', 'to' => 'nullable|date']);

        $query = Expense::ofBusiness($this->businessId($request))->orderByDesc('date')->orderByDesc('id');
        if ($request->filled('from')) {
            $query->where('date', '>=', Carbon::parse($request->query('from'))->toDateString());
        }
        if ($request->filled('to')) {
            $query->where('date', '<=', Carbon::parse($request->query('to'))->toDateString());
        }

        return response()->json($query->get()->map->toApi()->values());
    }

    /** POST /expenses */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate($this->rules());
        $expense = Expense::create([
            'business_id' => $this->businessId($request),
            'date' => $data['date'],
            'category' => $data['category'],
            'amount' => $data['amount'],
            'note' => $data['note'] ?? null,
            'created_by' => $this->authUser($request)->id,
        ]);

        return response()->json($expense->toApi(), 201);
    }

    /** PUT /expenses/{id} */
    public function update(Request $request, string $id): JsonResponse
    {
        $data = $request->validate($this->rules());
        $expense = Expense::ofBusiness($this->businessId($request))->findOrFail($id);
        $expense->update($data);

        return response()->json($expense->fresh()->toApi());
    }

    /** DELETE /expenses/{id} */
    public function destroy(Request $request, string $id): JsonResponse
    {
        Expense::ofBusiness($this->businessId($request))->findOrFail($id)->delete();

        return response()->json(['message' => 'Pengeluaran dihapus.']);
    }
}
