import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/period_chips.dart';
import 'expense_form_screen.dart';

class _Group {
  int count = 0;
  int amount = 0;
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  PeriodSelection _period = const PeriodSelection(1);
  bool _perMonth = false;

  Widget _modeChip(String label, bool month) {
    final selected = _perMonth == month;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primaryDark,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? AppColors.primaryDark : AppColors.border),
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
        onSelected: (_) => setState(() => _perMonth = month),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final range = _period.range;
    final orders = s.ordersCreatedBetween(range.start, range.end);
    final omzet = sumTotal(orders);
    final received = sumPaid(orders);
    final receivable = omzet - received;
    final expense = sumExpense(s.expensesBetween(range.start, range.end));
    final profit = omzet - expense;
    final dateText = rangeText(range.start, range.end);

    // Rincian transaksi per hari / per bulan
    final groups = <String, _Group>{};
    final keys = <String, DateTime>{};
    for (final o in orders) {
      final d = _perMonth ? DateTime(o.createdAt.year, o.createdAt.month) : startOfDay(o.createdAt);
      final key = _perMonth ? bulanTahun(d) : tanggal(d);
      keys[key] = d;
      final g = groups.putIfAbsent(key, () => _Group());
      g.count++;
      g.amount += o.total;
    }
    final rows = groups.entries.toList()..sort((a, b) => keys[b.key]!.compareTo(keys[a.key]!));

    final summary = 'Laporan ${s.profile.businessName}\n'
        'Periode: $dateText\n'
        'Omzet: ${rupiah(omzet)}\n'
        'Transaksi: ${orders.length}\n'
        'Sudah diterima: ${rupiah(received)}\n'
        'Piutang: ${rupiah(receivable)}\n'
        'Pengeluaran: ${rupiah(expense)}\n'
        'Laba: ${rupiah(profit)}';

    return Scaffold(
      appBar: lkAppBar(
        'Laporan',
        actions: [
          IconButton(
            tooltip: 'Salin ringkasan',
            icon: const Icon(Icons.content_copy_outlined),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await Clipboard.setData(ClipboardData(text: summary));
              messenger.showSnackBar(const SnackBar(content: Text('Ringkasan laporan disalin.')));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 12),
          PeriodChips(selection: _period, onChanged: (p) => setState(() => _period = p)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GradientPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Omzet ${_period.label}',
                                style: const TextStyle(color: Colors.white70)),
                          ),
                          Pill('${orders.length} trx', color: Colors.white, icon: Icons.receipt_long, onDark: true),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(rupiah(omzet),
                          style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Divider(color: Colors.white.withAlpha(60), height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.store_outlined, size: 15, color: Colors.white70),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('${s.profile.businessName}, $dateText',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: StatTile(icon: Icons.attach_money, label: 'Total Omzet', value: rupiah(omzet))),
                    const SizedBox(width: 12),
                    Expanded(child: StatTile(icon: Icons.receipt_long, label: 'Total Transaksi', value: '${orders.length}')),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: StatTile(
                        icon: Icons.check_circle_outline,
                        label: 'Sudah Diterima',
                        value: rupiah(received),
                        iconColor: AppColors.success,
                        iconBg: AppColors.success.withAlpha(30),
                        extra: Column(
                          children: [
                            const Divider(height: 1, color: AppColors.border),
                            const SizedBox(height: 6),
                            InfoRow('Tunai', rupiah(paidByMethod(orders, PayMethod.tunai))),
                            InfoRow('QRIS', rupiah(paidByMethod(orders, PayMethod.qris))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: StatTile(
                        icon: Icons.schedule,
                        label: 'Piutang',
                        value: rupiah(receivable),
                        iconColor: AppColors.warning,
                        iconBg: AppColors.warning.withAlpha(30),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  icon: Icons.account_balance_outlined,
                  title: 'Pengeluaran & Laba',
                  child: Column(
                    children: [
                      InfoRow('Total Omzet', rupiah(omzet), bold: true),
                      InfoRow('Total Pengeluaran', '-${rupiah(expense)}', valueColor: AppColors.danger),
                      const Divider(color: AppColors.border),
                      InfoRow('Laba (Omzet - Pengeluaran)', rupiah(profit),
                          bold: true, valueColor: profit >= 0 ? AppColors.success : AppColors.danger),
                      if (s.canExpense) ...[
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (_) => const ExpenseFormScreen())),
                          icon: const Icon(Icons.add),
                          label: const Text('Catat Pengeluaran'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SectionCard(
                  icon: Icons.bar_chart,
                  title: 'Rincian Transaksi',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _modeChip('Per Hari', false),
                          _modeChip('Per Bulan', true),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (rows.isEmpty)
                        const EmptyBox(icon: Icons.inbox_outlined, title: 'Belum ada transaksi di periode ini')
                      else
                        for (final r in rows)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.key, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                                      Text('${r.value.count} transaksi',
                                          style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                    ],
                                  ),
                                ),
                                Text(rupiah(r.value.amount),
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
