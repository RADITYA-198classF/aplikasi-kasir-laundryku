<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Expense;
use App\Models\Order;
use App\Models\Payment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

/** Laporan (hak "laporan"). Aturan sama dengan layar Laporan: transaksi batal tidak dihitung. */
class ReportController extends Controller
{
    /**
     * GET /reports/summary
     *   period   = today | 7days | month | custom   (default today)
     *   from,to  = YYYY-MM-DD (wajib jika period=custom)
     *   group_by = day | month                       (default day)
     */
    public function summary(Request $request): JsonResponse
    {
        $data = $request->validate([
            'period' => ['nullable', Rule::in(['today', '7days', 'month', 'custom'])],
            'from' => 'required_if:period,custom|nullable|date',
            'to' => 'required_if:period,custom|nullable|date|after_or_equal:from',
            'group_by' => ['nullable', Rule::in(['day', 'month'])],
        ]);

        $biz = $this->businessId($request);
        $today = Carbon::today();

        switch ($data['period'] ?? 'today') {
            case '7days':
                [$from, $to] = [$today->copy()->subDays(6), $today->copy()];
                break;
            case 'month':
                [$from, $to] = [$today->copy()->startOfMonth(), $today->copy()];
                break;
            case 'custom':
                [$from, $to] = [Carbon::parse($data['from'])->startOfDay(), Carbon::parse($data['to'])->startOfDay()];
                break;
            default:
                [$from, $to] = [$today->copy(), $today->copy()];
        }
        $perMonth = ($data['group_by'] ?? 'day') === 'month';

        $orders = Order::ofBusiness($biz)->counted()->createdBetween($from, $to)
            ->get(['id', 'created_at', 'total', 'paid']);

        $omzet = (int) $orders->sum('total');
        $received = (int) $orders->sum('paid');
        $expense = (int) Expense::ofBusiness($biz)
            ->whereBetween('date', [$from->toDateString(), $to->toDateString()])
            ->sum('amount');

        $byMethod = $orders->isEmpty() ? collect() : Payment::whereIn('order_id', $orders->pluck('id'))
            ->selectRaw('method, SUM(amount) as total')
            ->groupBy('method')
            ->pluck('total', 'method');

        // Rincian per hari / per bulan (terbaru dulu)
        $groups = [];
        foreach ($orders as $o) {
            $key = $perMonth ? $o->created_at->format('Y-m') . '-01' : $o->created_at->format('Y-m-d');
            $groups[$key] ??= ['date' => $key, 'count' => 0, 'amount' => 0];
            $groups[$key]['count']++;
            $groups[$key]['amount'] += $o->total;
        }
        krsort($groups);

        return response()->json([
            'period' => ['from' => $from->toDateString(), 'to' => $to->toDateString()],
            'group_by' => $perMonth ? 'month' : 'day',
            'omzet' => $omzet,
            'transactions' => $orders->count(),
            'received' => $received,
            'receivable' => $omzet - $received,
            'expense' => $expense,
            'profit' => $omzet - $expense,
            'by_method' => [
                'tunai' => (int) ($byMethod['tunai'] ?? 0),
                'qris' => (int) ($byMethod['qris'] ?? 0),
            ],
            'breakdown' => array_values($groups),
        ]);
    }
}
