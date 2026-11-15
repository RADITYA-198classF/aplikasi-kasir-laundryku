<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Business;
use App\Models\Customer;
use App\Models\Order;
use App\Services\OrderService;
use App\Support\Format;
use App\Support\OrderStatus;
use App\Support\WhatsAppMessage;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    public function __construct(private OrderService $orders)
    {
    }

    private function find(Request $request, string $id): Order
    {
        return Order::ofBusiness($this->businessId($request))
            ->with(['items', 'payments', 'logs'])
            ->findOrFail($id);
    }

    /**
     * GET /orders  (terbaru dulu)
     * Filter opsional: status, cancelled (true/false), customer_id, from, to (YYYY-MM-DD), q (invoice/nama/telepon).
     */
    public function index(Request $request): JsonResponse
    {
        $data = $request->validate([
            'status' => ['nullable', Rule::in(OrderStatus::FLOW)],
            'cancelled' => 'nullable|boolean',
            'customer_id' => 'nullable|integer',
            'from' => 'nullable|date',
            'to' => 'nullable|date',
            'q' => 'nullable|string|max:100',
        ]);

        $query = Order::ofBusiness($this->businessId($request))
            ->with(['items', 'payments', 'logs'])
            ->orderByDesc('created_at')
            ->orderByDesc('id');

        if (! empty($data['status'])) {
            $query->where('status', $data['status']);
        }
        if (array_key_exists('cancelled', $data) && $data['cancelled'] !== null) {
            $query->where('cancelled', (bool) $data['cancelled']);
        }
        if (! empty($data['customer_id'])) {
            $query->where('customer_id', $data['customer_id']);
        }
        if (! empty($data['from']) || ! empty($data['to'])) {
            $from = Carbon::parse($data['from'] ?? '2000-01-01');
            $to = Carbon::parse($data['to'] ?? Carbon::today()->toDateString());
            $query->createdBetween($from, $to);
        }
        if (! empty($data['q'])) {
            $q = trim($data['q']);
            $query->where(fn ($w) => $w->where('invoice', 'like', "%$q%")
                ->orWhere('customer_name', 'like', "%$q%")
                ->orWhere('customer_phone', 'like', "%$q%"));
        }

        return response()->json($query->get()->map->toApi()->values());
    }

    /** GET /orders/{id} */
    public function show(Request $request, string $id): JsonResponse
    {
        return response()->json($this->find($request, $id)->toApi());
    }

    /** POST /orders (hak "transaksi"). Harga diambil dari database, bukan dari klien. */
    public function store(Request $request): JsonResponse
    {
        $biz = $this->businessId($request);

        $data = $request->validate([
            'customer_id' => ['required', 'integer', Rule::exists('customers', 'id')->where('business_id', $biz)->whereNull('deleted_at')],
            'items' => 'required|array|min:1|max:100',
            'items.*.service_id' => ['required', 'integer', Rule::exists('services', 'id')->where('business_id', $biz)],
            'items.*.qty' => 'required|numeric|gt:0|max:100000',
            'note' => 'nullable|string|max:500',
            'first_payment' => 'nullable|array',
            'first_payment.method' => ['required_with:first_payment', Rule::in(['tunai', 'qris'])],
            'first_payment.amount' => 'required_with:first_payment|integer|min:1',
        ], [
            'items.required' => 'Pilih minimal satu layanan.',
            'items.min' => 'Pilih minimal satu layanan.',
        ]);

        $order = $this->orders->create(
            Business::findOrFail($biz),
            $this->authUser($request),
            Customer::ofBusiness($biz)->findOrFail($data['customer_id']),
            $data['items'],
            $data['note'] ?? null,
            $data['first_payment'] ?? null,
        );

        return response()->json($order->toApi(), 201);
    }

    /** PATCH /orders/{id}/status (hak "transaksi"): hanya boleh maju satu langkah. */
    public function updateStatus(Request $request, string $id): JsonResponse
    {
        $data = $request->validate(['status' => ['required', Rule::in(OrderStatus::FLOW)]]);

        $order = $this->orders->advance((int) $id, $this->businessId($request), $this->authUser($request), $data['status']);

        return response()->json($order->toApi());
    }

    /** POST /orders/{id}/cancel (hak "transaksi"; yang sudah dibayar butuh hak "batalBayar") */
    public function cancel(Request $request, string $id): JsonResponse
    {
        $order = $this->orders->cancel((int) $id, $this->businessId($request), $this->authUser($request));

        return response()->json($order->toApi());
    }

    /** POST /orders/{id}/payments (hak "transaksi") */
    public function addPayment(Request $request, string $id): JsonResponse
    {
        $data = $request->validate([
            'method' => ['required', Rule::in(['tunai', 'qris'])],
            'amount' => 'required|integer|min:1',
        ]);

        $order = $this->orders->addPayment(
            (int) $id,
            $this->businessId($request),
            $this->authUser($request),
            $data['method'],
            (int) $data['amount'],
        );

        return response()->json($order->toApi());
    }

    /** GET /orders/{id}/whatsapp: teks pesan + link wa.me untuk memberi tahu pelanggan. */
    public function whatsapp(Request $request, string $id): JsonResponse
    {
        $order = $this->find($request, $id);
        $business = Business::findOrFail($this->businessId($request));

        $phone = Format::normalizePhone($order->customer_phone);
        $message = WhatsAppMessage::build($order, $business);

        return response()->json([
            'phone' => $phone,
            'message' => $message,
            'url' => $phone === '' ? null : WhatsAppMessage::link($phone, $message),
        ]);
    }
}
