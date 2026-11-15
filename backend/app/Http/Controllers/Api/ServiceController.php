<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Service;
use App\Support\Permissions;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class ServiceController extends Controller
{
    private function rules(int $businessId): array
    {
        return [
            'category_id' => ['required', 'integer', Rule::exists('service_categories', 'id')->where('business_id', $businessId)],
            'name' => 'required|string|max:100',
            'unit' => ['required', Rule::in(['kg', 'pcs', 'm2'])],
            'price' => 'required|integer|min:0|max:100000000',
            'min_qty' => 'nullable|numeric|min:0|max:100000',
            'duration_value' => 'required|integer|min:1|max:65000',
            'duration_unit' => ['required', Rule::in(['hari', 'jam'])],
            'active' => 'sometimes|boolean',
        ];
    }

    private function find(Request $request, string $id): Service
    {
        return Service::ofBusiness($this->businessId($request))->findOrFail($id);
    }

    /** GET /services (semua layanan, termasuk yang nonaktif) */
    public function index(Request $request): JsonResponse
    {
        $list = Service::ofBusiness($this->businessId($request))->orderBy('service_category_id')->orderBy('id')->get();

        return response()->json($list->map->toApi()->values());
    }

    /** POST /services (owner) */
    public function store(Request $request): JsonResponse
    {
        $biz = $this->businessId($request);
        $data = $request->validate($this->rules($biz));

        $service = Service::create([
            'business_id' => $biz,
            'service_category_id' => $data['category_id'],
            'name' => $data['name'],
            'unit' => $data['unit'],
            'price' => $data['price'],
            'min_qty' => $data['min_qty'] ?? 0,
            'duration_value' => $data['duration_value'],
            'duration_unit' => $data['duration_unit'],
            'active' => $data['active'] ?? true,
        ]);

        return response()->json($service->toApi(), 201);
    }

    /**
     * PUT /services/{id}
     * Owner boleh mengubah semua field. Karyawan dengan hak "layanan" hanya boleh mengubah `active`
     * (field lain harus sama persis dengan data yang tersimpan).
     */
    public function update(Request $request, string $id): JsonResponse
    {
        $user = $this->authUser($request);
        $service = $this->find($request, $id);
        $data = $request->validate($this->rules($service->business_id));

        if (! $user->isOwner()) {
            if (! $user->hasPermission(Permissions::LAYANAN)) {
                abort(403, 'Anda tidak memiliki hak akses untuk mengubah layanan.');
            }
            $sameDetails = (int) $data['category_id'] === (int) $service->service_category_id
                && $data['name'] === $service->name
                && $data['unit'] === $service->unit
                && (int) $data['price'] === (int) $service->price
                && abs((float) ($data['min_qty'] ?? 0) - (float) $service->min_qty) < 0.001
                && (int) $data['duration_value'] === (int) $service->duration_value
                && $data['duration_unit'] === $service->duration_unit;
            if (! $sameDetails) {
                abort(403, 'Hanya owner yang dapat mengubah detail layanan.');
            }
        }

        $service->update([
            'service_category_id' => $data['category_id'],
            'name' => $data['name'],
            'unit' => $data['unit'],
            'price' => $data['price'],
            'min_qty' => $data['min_qty'] ?? 0,
            'duration_value' => $data['duration_value'],
            'duration_unit' => $data['duration_unit'],
            'active' => $data['active'] ?? $service->active,
        ]);

        return response()->json($service->fresh()->toApi());
    }

    /** PATCH /services/{id}/active (owner atau karyawan dengan hak "layanan") */
    public function toggle(Request $request, string $id): JsonResponse
    {
        $data = $request->validate(['active' => 'required|boolean']);
        $service = $this->find($request, $id);
        $service->update(['active' => $data['active']]);

        return response()->json($service->toApi());
    }

    /** DELETE /services/{id} (owner). Riwayat transaksi tetap utuh karena item menyimpan salinan. */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $this->find($request, $id)->delete();

        return response()->json(['message' => 'Layanan dihapus.']);
    }
}
