import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/period_chips.dart';
import 'expense_form_screen.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  PeriodSelection _period = const PeriodSelection(2);

  Future<void> _delete(Expense e) async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus pengeluaran?'),
        content: Text('${e.category}, ${rupiah(e.amount)} akan dihapus dari catatan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(
            style: solidFilledStyle(background: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) await state.deleteExpense(e.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final range = _period.range;
    final list = s.expensesBetween(range.start, range.end);

    return Scaffold(
      appBar: lkAppBar('Pengeluaran'),
      floatingActionButton: LkFab(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ExpenseFormScreen())),
        tooltip: 'Catat pengeluaran',
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          const SizedBox(height: 12),
          PeriodChips(selection: _period, onChanged: (p) => setState(() => _period = p)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: GradientPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Pengeluaran ${_period.label}',
                                  style: const TextStyle(color: Colors.white70)),
                            ),
                            Pill('${list.length} catatan', color: Colors.white, icon: Icons.receipt_long, onDark: true),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(rupiah(sumExpense(list)),
                            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 10),
                        Divider(color: Colors.white.withAlpha(60), height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.store_outlined, size: 15, color: Colors.white70),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text('${s.profile.businessName}, ${rangeText(range.start, range.end)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (list.isEmpty)
                  const AppCard(
                    child: EmptyBox(
                      icon: Icons.money_off,
                      title: 'Belum ada pengeluaran di periode ini',
                      message: 'Tap tombol + untuk mencatat pengeluaran',
                    ),
                  )
                else
                  for (final e in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: AppCard(
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        child: Row(
                          children: [
                            IconCircle(expenseIcon(e.category), size: 40),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(e.category,
                                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                                  Text(e.note.isEmpty ? tanggal(e.date) : '${e.note}, ${tanggal(e.date)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Text('-${rupiah(e.amount)}',
                                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger)),
                            IconButton(
                              tooltip: 'Hapus',
                              onPressed: () => _delete(e),
                              icon: const Icon(Icons.delete_outline, color: AppColors.muted),
                            ),
                          ],
                        ),
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
