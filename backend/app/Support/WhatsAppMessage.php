<?php

namespace App\Support;

use App\Models\Business;
use App\Models\Order;

/** Padanan statusMessage() dan openWhatsApp() di whatsapp.dart: pesan WhatsApp ke pelanggan sesuai status. */
final class WhatsAppMessage
{
    public static function build(Order $o, Business $business): string
    {
        $shop = $business->name !== '' ? $business->name : 'LaundryKu';
        $b = "Halo {$o->customer_name}, ";

        if ($o->cancelled) {
            return $b . "transaksi Anda ({$o->invoice}) telah dibatalkan. Salam, {$shop}.";
        }

        switch ($o->status) {
            case 'antrian':
                $b .= "cucian Anda ({$o->invoice}) sudah kami terima dan masuk antrian.";
                break;
            case 'diproses':
                $b .= "cucian Anda ({$o->invoice}) sedang kami proses.";
                break;
            case 'selesai':
                $b .= "cucian Anda ({$o->invoice}) sudah selesai dan siap diambil.";
                break;
            default: // diambil
                $b .= "terima kasih, cucian Anda ({$o->invoice}) sudah diambil.";
        }

        if ($o->isActive()) {
            $b .= ' Estimasi selesai ' . Format::tanggal($o->due_at) . '.';
        }
        $b .= ' Total tagihan ' . Format::rupiah($o->total);
        $b .= $o->remaining === 0 ? ' (sudah lunas).' : ', sisa ' . Format::rupiah($o->remaining) . '.';
        if (! empty($business->owner_wa)) {
            $b .= " Ada kendala? Hubungi owner: {$business->owner_wa}.";
        }

        return $b . " Salam, {$shop}.";
    }

    public static function link(string $phone, string $message): string
    {
        return 'https://wa.me/' . $phone . '?text=' . rawurlencode($message);
    }
}
