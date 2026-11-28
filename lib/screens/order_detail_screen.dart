import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../core/whatsapp.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/payment_dialog.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  Future<void> _chat(ScaffoldMessengerState messenger, LaundryOrder order, BusinessProfile profile) async {
    final ok = await openWhatsApp(order, profile);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('WhatsApp tidak dapat dibuka. Periksa nomor pelanggan.')),
      );
    }
  }

  Future<void> _advance(BuildContext context, LaundryOrder order) async {
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    final updated = await state.advanceStatus(order.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text('Status diubah menjadi ${updated.status.label}.'),
        action: updated.customerPhone.isEmpty
            ? null
            : SnackBarAction(
                label: 'Beritahu pelanggan',
                onPressed: () => _chat(messenger, updated, state.profile),
              ),
      ),
    );
  }

  Future<void> _pay(BuildContext context, LaundryOrder order) async {
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    final input = await showPaymentDialog(
      context,
      total: order.total,
      alreadyPaid: order.paid,
      confirmLabel: 'Simpan Pembayaran',
    );
    if (input == null) return;
    final amount = input.amount > order.remaining ? order.remaining : input.amount;
    final change = input.method == PayMethod.tunai ? input.amount - amount : 0;
    await state.addPayment(order.id, input.method, amount);
    messenger.showSnackBar(SnackBar(
      content: Text(change > 0 ? 'Pembayaran dicatat. Kembalian ${rupiah(change)}.' : 'Pembayaran dicatat.'),
    ));
  }

  Future<void> _cancel(BuildContext context, LaundryOrder order) async {
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan transaksi?'),
        content: Text(
            '${order.invoice} atas nama ${order.customerName} akan dibatalkan dan tidak dihitung di laporan. Tindakan ini tidak bisa diurungkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Tidak')),
          FilledButton(
            style: solidFilledStyle(background: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await state.cancelOrder(order.id);
    messenger.showSnackBar(const SnackBar(content: Text('Transaksi dibatalkan.')));
  }

  Widget _statusStepper(LaundryOrder order) {
    const all = OrderStatus.values;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < all.length; i++)
          Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(height: 2, color: i == 0 ? Colors.transparent : (i <= order.status.index ? statusColor(all[i]) : AppColors.border)),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i <= order.status.index ? statusColor(all[i]) : Colors.white,
                        border: Border.all(color: i <= order.status.index ? statusColor(all[i]) : AppColors.border, width: 2),
                      ),
                      child: Icon(
                        i < order.status.index ? Icons.check : all[i].icon,
                        size: 16,
                        color: i <= order.status.index ? Colors.white : AppColors.muted,
                      ),
                    ),
                    Expanded(
                      child: Container(height: 2, color: i == all.length - 1 ? Colors.transparent : (i < order.status.index ? statusColor(all[i + 1]) : AppColors.border)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(all[i].label,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: i == order.status.index ? FontWeight.w800 : FontWeight.w500,
                        color: i <= order.status.index ? AppColors.ink : AppColors.muted)),
                Text(
                  order.timeOf(all[i]) == null ? '-' : '${tanggalPendek(order.timeOf(all[i])!)}, ${jam(order.timeOf(all[i])!)}',
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final order = state.orderById(orderId);
    if (order == null) {
      return Scaffold(
        appBar: lkAppBar('Detail Transaksi'),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Transaksi tidak ditemukan',
          message: 'Transaksi ini mungkin sudah dihapus.',
        ),
      );
    }

    final messenger = ScaffoldMessenger.of(context);
    final next = order.cancelled ? null : order.status.next;
    final canCancel = !order.cancelled &&
        order.status != OrderStatus.diambil &&
        (order.paid == 0 || state.canCancelPaid);
    final overdue = order.isOverdue();

    return Scaffold(
      appBar: lkAppBar('Detail Transaksi'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          GradientPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.invoice,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text('${state.profile.businessName}, ${tanggal(order.createdAt)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                    StatusPill(order.status, onDark: true, cancelled: order.cancelled),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withAlpha(60), height: 1),
                const SizedBox(height: 12),
                const Text('Total Tagihan', style: TextStyle(color: Colors.white70)),
                Row(
                  children: [
                    Expanded(
                      child: Text(rupiah(order.total),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                    ),
                    PayPill(paid: order.isPaid, onDark: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.person_outline,
            title: 'Pelanggan',
            trailing: order.customerPhone.isEmpty
                ? null
                : FilledButton.tonalIcon(
                    style: tonalSolidStyle,
                    onPressed: () => _chat(messenger, order, state.profile),
                    icon: const Icon(Icons.chat_outlined, size: 18),
                    label: const Text('Chat'),
                  ),
            child: Column(
              children: [
                InfoRow('Nama', order.customerName),
                InfoRow('No. HP', order.customerPhone.isEmpty ? '-' : order.customerPhone),
                InfoRow('Estimasi selesai', tanggalJam(order.dueAt),
                    valueColor: overdue ? AppColors.danger : AppColors.ink),
                if (order.note.isNotEmpty) InfoRow('Catatan', order.note),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.local_laundry_service_outlined,
            title: 'Layanan',
            child: Column(
              children: [
                for (final i in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(8)),
                          child: Text('${formatQty(i.qty)} ${i.unit.label}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryDark)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(i.name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                              Text('${rupiah(i.price)} / ${i.unit.label}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(rupiah(i.subtotal), style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Pembayaran',
            child: Column(
              children: [
                InfoRow('Total', rupiah(order.total), bold: true),
                InfoRow('Sudah Dibayar', rupiah(order.paid), bold: true),
                const Divider(color: AppColors.border),
                InfoRow('Sisa', rupiah(order.remaining),
                    bold: true, valueColor: order.isPaid ? AppColors.success : AppColors.danger),
                if (!order.isPaid && !order.cancelled) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: () => _pay(context, order),
                      icon: const Icon(Icons.add),
                      label: const Text('Catat Pembayaran'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.history,
            title: 'Riwayat Pembayaran',
            child: order.payments.isEmpty
                ? const EmptyBox(icon: Icons.receipt_long_outlined, title: 'Belum ada pembayaran')
                : Column(
                    children: [
                      for (final p in order.payments)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              IconCircle(p.method.icon, size: 36),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tanggal(p.date), style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                                    Text(p.method.label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                  ],
                                ),
                              ),
                              Text(rupiah(p.amount),
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.success)),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.timeline,
            title: 'Status Cucian',
            child: _statusStepper(order),
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: () => _advance(context, order),
                icon: Icon(next.icon),
                label: Text('${order.status.advanceLabel} (${next.label})',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
          if (order.cancelled)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.danger.withAlpha(24),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.cancel_outlined, color: AppColors.danger),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text('Transaksi ini dibatalkan dan tidak dihitung di laporan.',
                          style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
          if (!order.cancelled && order.status != OrderStatus.diambil) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: BorderSide(color: canCancel ? AppColors.danger : AppColors.border),
                ),
                onPressed: canCancel ? () => _cancel(context, order) : null,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Batalkan Transaksi'),
              ),
            ),
            if (!canCancel)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Transaksi yang sudah dibayar hanya bisa dibatalkan oleh owner atau karyawan dengan izin khusus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
