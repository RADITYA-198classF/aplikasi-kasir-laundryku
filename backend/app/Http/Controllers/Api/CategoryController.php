<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ServiceCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CategoryController extends Controller
{
    private function rules(): array
    {
        return ['name' => 'required|string|max:100', 'flow' => 'nullable|string|max:150'];
    }

    /** GET /categories */
    public function index(Request $request): JsonResponse
    {
        $list = ServiceCategory::ofBusiness($this->businessId($request))->orderBy('id')->get();

        return response()->json($list->map->toApi()->values());
    }

    /** POST /categories (owner) */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate($this->rules());

        $category = ServiceCategory::create([
            'business_id' => $this->businessId($request),
            'name' => $data['name'],
            'flow' => ($data['flow'] ?? null) ?: 'Cuci -> Pengeringan',
        ]);

        return response()->json($category->toApi(), 201);
    }

    /** PUT /categories/{id} (owner) */
    public function update(Request $request, string $id): JsonResponse
    {
        $data = $request->validate($this->rules());
        $category = ServiceCategory::ofBusiness($this->businessId($request))->findOrFail($id);
        $category->update(['name' => $data['name'], 'flow' => ($data['flow'] ?? null) ?: $category->flow]);

        return response()->json($category->toApi());
    }

    /** DELETE /categories/{id} (owner): hanya jika belum punya layanan. */
    public function destroy(Request $request, string $id): JsonResponse
    {
        $category = ServiceCategory::ofBusiness($this->businessId($request))->findOrFail($id);
        if ($category->services()->exists()) {
            abort(422, 'Kategori masih memiliki layanan. Hapus layanannya terlebih dahulu.');
        }
        $category->delete();

        return response()->json(['message' => 'Kategori dihapus.']);
    }
}
