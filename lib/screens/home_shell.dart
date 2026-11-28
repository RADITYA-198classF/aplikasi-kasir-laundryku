import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_state.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/common_widgets.dart';
import 'dashboard_screen.dart';
import 'help_screen.dart';
import 'new_order_screen.dart';
import 'orders_screen.dart';
import 'reports_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget> _pages = [
    DashboardScreen(onGoToTab: _go),
    const OrdersScreen(),
    NewOrderScreen(onGoToTab: _go),
    const ReportsScreen(),
    const HelpScreen(),
  ];

  void _go(int i) => setState(() => _index = i);

  /// Menu bilah bawah mengikuti hak akses: karyawan hanya melihat yang diizinkan.
  List<BarItem> _items(AppState s) {
    return [
      const BarItem(0, Icons.home_rounded, 'Beranda'),
      if (s.canTransaksi) const BarItem(1, Icons.receipt_long, 'Transaksi'),
      if (s.canTransaksi) const BarItem(2, Icons.add, 'Transaksi Baru'),
      if (s.canReport) const BarItem(3, Icons.bar_chart_rounded, 'Laporan'),
      if (s.isOwner) const BarItem(4, Icons.help_rounded, 'Bantuan'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = _items(state);
    final fabSlot = items.indexWhere((i) => i.tab == 2);

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButtonLocation: fabSlot < 0 ? null : SlotFabLocation(fabSlot, items.length),
      floatingActionButton: fabSlot < 0
          ? null
          : LkFab(
              onPressed: () => _go(2),
              gradient: AppColors.freshGradient,
              foregroundColor: AppColors.primaryDark,
              shadowColor: const Color(0x8038BDF8),
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 34),
            ),
      bottomNavigationBar: LkBottomBar(items: items, current: _index, onChanged: _go),
    );
  }
}
