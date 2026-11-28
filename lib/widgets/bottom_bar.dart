import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Satu tujuan di bilah bawah. [tab] 2 adalah slot tombol melayang "Transaksi Baru".
class BarItem {
  const BarItem(this.tab, this.icon, this.label);
  final int tab;
  final IconData icon;
  final String label;
}

/// Meletakkan tombol melayang tepat di tengah slot ke-[slot] dari [count] slot bilah bawah.
class SlotFabLocation extends FloatingActionButtonLocation {
  const SlotFabLocation(this.slot, this.count);
  final int slot;
  final int count;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final fab = geometry.floatingActionButtonSize;
    final x = geometry.scaffoldSize.width * (slot + 0.5) / count - fab.width / 2;
    final y = geometry.contentBottom - fab.height / 2;
    return Offset(x, y);
  }
}

/// Bilah bawah. Jumlah menu mengikuti hak akses pengguna.
class LkBottomBar extends StatelessWidget {
  const LkBottomBar({super.key, required this.items, required this.current, required this.onChanged});

  final List<BarItem> items;
  final int current;
  final ValueChanged<int> onChanged;

  Widget _item(BarItem item) {
    final selected = current == item.tab;
    final color = selected ? AppColors.amber : Colors.white.withAlpha(215);
    final isFabSlot = item.tab == 2;
    return Expanded(
      child: InkWell(
        onTap: () => onChanged(item.tab),
        child: isFabSlot
            ? Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(item.label,
                      style: TextStyle(
                          color: color, fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, color: color, size: 24),
                  const SizedBox(height: 3),
                  Text(item.label,
                      style: TextStyle(
                          color: color, fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gradien dipasang di dalam BottomAppBar (dipotong mengikuti lekukan tombol tengah).
    // Area aman bawah diisi sendiri supaya gradien menyambung sampai tepi layar.
    final inset = MediaQuery.of(context).padding.bottom;
    return MediaQuery.removePadding(
      context: context,
      removeBottom: true,
      child: BottomAppBar(
        height: 68 + inset,
        padding: EdgeInsets.zero,
        color: AppColors.primaryDark,
        surfaceTintColor: Colors.transparent,
        shape: const CircularNotchedRectangle(),
        notchMargin: 7,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.gradientH),
          child: Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: Row(children: [for (final i in items) _item(i)]),
          ),
        ),
      ),
    );
  }
}
