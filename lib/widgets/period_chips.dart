import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import 'common_widgets.dart';

/// Pilihan periode untuk Laporan dan Pengeluaran:
/// 0 = Hari Ini, 1 = 7 Hari Terakhir, 2 = Bulan Ini, 3 = Custom.
class PeriodSelection {
  const PeriodSelection(this.index, [this.custom]);
  final int index;
  final DateTimeRange? custom;

  DateTimeRange get range {
    final today = startOfDay(DateTime.now());
    switch (index) {
      case 0:
        return DateTimeRange(start: today, end: today);
      case 1:
        return DateTimeRange(start: today.subtract(const Duration(days: 6)), end: today);
      case 2:
        return DateTimeRange(start: DateTime(today.year, today.month, 1), end: today);
      default:
        return custom ?? DateTimeRange(start: today, end: today);
    }
  }

  String get label {
    switch (index) {
      case 0:
        return 'Hari Ini';
      case 1:
        return '7 Hari Terakhir';
      case 2:
        return 'Bulan Ini';
      default:
        return 'Custom';
    }
  }
}

class PeriodChips extends StatelessWidget {
  const PeriodChips({super.key, required this.selection, required this.onChanged});

  final PeriodSelection selection;
  final ValueChanged<PeriodSelection> onChanged;

  Future<void> _pickCustom(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: selection.custom,
    );
    if (picked != null) onChanged(PeriodSelection(3, picked));
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Hari Ini', '7 Hari Terakhir', 'Bulan Ini'];
    Widget chip(String text, bool selected, VoidCallback onTap, {IconData? icon}) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: LkChoiceChip(
          avatar: icon == null ? null : Icon(icon, size: 16, color: selected ? Colors.white : AppColors.primaryDark),
          label: Text(text),
          selected: selected,
          labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
          onSelected: (_) => onTap(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            chip(labels[i], selection.index == i, () => onChanged(PeriodSelection(i))),
          chip('Custom', selection.index == 3, () => _pickCustom(context), icon: Icons.calendar_today_outlined),
        ],
      ),
    );
  }
}
