<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BusinessController extends Controller
{
    /** GET /business */
    public function show(Request $request): JsonResponse
    {
        $business = Business::with('owner')->findOrFail($this->businessId($request));

        return response()->json($business->toProfile());
    }

    /** PUT /business (owner) */
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'business_name' => 'required|string|max:120',
            'owner_name' => 'required|string|max:120',
            'phone' => 'nullable|string|max:32',
            'hours' => 'nullable|string|max:60',
            'owner_wa' => 'nullable|string|max:32',
        ]);

        $business = Business::findOrFail($this->businessId($request));

        DB::transaction(function () use ($request, $business, $data) {
            $business->update([
                'name' => $data['business_name'],
                'phone' => $data['phone'] ?? null,
                'hours' => $data['hours'] ?? null,
                'owner_wa' => $data['owner_wa'] ?? null,
            ]);
            $this->authUser($request)->update(['name' => $data['owner_name']]);
        });

        return response()->json($business->fresh('owner')->toProfile());
    }
}
