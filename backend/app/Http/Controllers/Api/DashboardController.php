<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class DashboardController extends Controller
{
    /** GET /dashboard: ringkasan beranda (bisa diakses semua akun). */
    public function index(Request $request): JsonResponse
    {
        $biz = $this->businessId($request);
        $today = Carbon::today();
        $tomorrow = $today->copy()->addDay();

        $todayOrders = Order::ofBusiness($biz)->counted()->createdBetween($today, $today)->get(['total', 'paid']);

        $statusCounts = Order::ofBusiness($biz)->counted()
            ->selectRaw('status, COUNT(*) as c')->groupBy('status')->pluck('c', 'status');

        $active = Order::ofBusiness($biz)->counted()->whereIn('status', ['antrian', 'diproses'])->get(['id', 'due_at']);

        return response()->json([
            'today' => [
                'transactions' => $todayOrders->count(),
                'omzet' => (int) $todayOrders->sum('total'),
                'received' => (int) $todayOrders->sum('paid'),
            ],
            'status_counts' => [
                'antrian' => (int) ($statusCounts['antrian'] ?? 0),
                'diproses' => (int) ($statusCounts['diproses'] ?? 0),
                'selesai' => (int) ($statusCounts['selesai'] ?? 0),
                'diambil' => (int) ($statusCounts['diambil'] ?? 0),
            ],
            'overdue' => $active->filter(fn ($o) => $o->due_at->copy()->startOfDay()->lt($today))->count(),
            'due_today' => $active->filter(fn ($o) => $o->due_at->isSameDay($today))->count(),
            'due_tomorrow' => $active->filter(fn ($o) => $o->due_at->isSameDay($tomorrow))->count(),
            'cancelled' => Order::ofBusiness($biz)->where('cancelled', true)->count(),
        ]);
    }
}
