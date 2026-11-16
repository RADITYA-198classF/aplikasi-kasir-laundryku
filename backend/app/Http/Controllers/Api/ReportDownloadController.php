<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ReportDownload;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

/** Riwayat unduhan laporan (hak "laporan"). Waktu unduh selalu memakai jam server. */
class ReportDownloadController extends Controller
{
    /** GET /reports/downloads: 50 riwayat terbaru milik usaha ini. */
    public function index(Request $request): JsonResponse
    {
        $list = ReportDownload::ofBusiness($this->businessId($request))
            ->orderByDesc('downloaded_at')
            ->orderByDesc('id')
            ->limit(50)
            ->get();

        return response()->json($list->map->toApi()->values());
    }

    /** POST /reports/downloads: dicatat oleh aplikasi setelah PDF dibuat. */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'format' => ['nullable', Rule::in(['pdf'])],
            'period_label' => 'required|string|max:60',
            'from' => 'required|date',
            'to' => 'required|date|after_or_equal:from',
            'sections' => 'required|array|min:1',
            'sections.*' => ['string', Rule::in(ReportDownload::SECTIONS)],
        ]);

        $user = $this->authUser($request);

        $row = ReportDownload::create([
            'business_id' => $user->business_id,
            'user_id' => $user->id,
            'user_name' => $user->name,
            'format' => $data['format'] ?? 'pdf',
            'period_label' => $data['period_label'],
            'period_from' => Carbon::parse($data['from'])->toDateString(),
            'period_to' => Carbon::parse($data['to'])->toDateString(),
            'sections' => array_values(array_unique($data['sections'])),
            'downloaded_at' => Carbon::now(),
        ]);

        return response()->json($row->toApi(), 201);
    }
}
