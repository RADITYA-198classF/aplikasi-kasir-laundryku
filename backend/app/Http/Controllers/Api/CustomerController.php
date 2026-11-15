<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Customer;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CustomerController extends Controller
{
    private function rules(): array
    {
        return [
            'name' => 'required|string|max:120',
            'phone' => 'nullable|string|max:32',
        ];
    }

    private function find(Request $request, string $id): Customer
    {
        return Customer::ofBusiness($this->businessId($request))->findOrFail($id);
    }

    /** GET /customers?q=  (q opsional: cari nama/telepon) */
    public function index(Request $request): JsonResponse
    {
        $biz = $this->businessId($request);
        $query = Customer::ofBusiness($biz)->orderBy('name');

        if ($q = trim((string) $request->query('q', ''))) {
            $query->where(fn ($w) => $w->where('name', 'like', "%$q%")->orWhere('phone', 'like', "%$q%"));
        }

        $customers = $query->get();

        // Jumlah transaksi (tanpa yang dibatalkan) untuk tiap pelanggan, sekali query.
        $counts = Order::ofBusiness($biz)->counted()
            ->whereIn('customer_id', $customers->pluck('id'))
            ->selectRaw('customer_id, COUNT(*) as c')
            ->groupBy('customer_id')
            ->pluck('c', 'customer_id');

        return response()->json($customers->map(
            fn (Customer $c) => $c->toApi() + ['orders_count' => (int) ($counts[$c->id] ?? 0)]
        )->values());
    }

    /** POST /customers */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate($this->rules());
        $customer = Customer::create([
            'business_id' => $this->businessId($request),
            'name' => trim($data['name']),
            'phone' => trim((string) ($data['phone'] ?? '')),
        ]);

        return response()->json($customer->toApi(), 201);
    }

    /** PUT /customers/{id} */
    public function update(Request $request, string $id): JsonResponse
    {
        $data = $request->validate($this->rules());
        $customer = $this->find($request, $id);
        $customer->update([
            'name' => trim($data['name']),
            'phone' => trim((string) ($data['phone'] ?? '')),
        ]);

        return response()->json($customer->toApi());
    }

    /** DELETE /customers/{id}: soft delete, riwayat transaksi pelanggan tetap tersimpan. */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $this->find($request, $id)->delete();

        return response()->json(['message' => 'Pelanggan dihapus.']);
    }
}
