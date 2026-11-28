import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import 'customers_screen.dart';
import 'employees_screen.dart';
import 'expenses_screen.dart';
import 'order_list_screen.dart';
import 'password_screen.dart';
import 'profile_screen.dart';
import 'services_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.onGoToTab});

  final ValueChanged<int> onGoToTab;

  void _open(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Anda perlu masuk lagi untuk mengelola transaksi.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Keluar')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<AppState>().logout();
  }

  Widget _countTile(BuildContext context, String label, int count, Widget page, {bool alert = false}) {
    final hot = alert && count > 0;
    return Expanded(
      child: Material(
        color: Colors.white.withAlpha(36),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(context, page),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (hot) ...[
                      const Icon(Icons.schedule, size: 13, color: AppColors.amber),
                      const SizedBox(width: 3),
                    ],
                    Flexible(
                      child: Text(label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: hot ? AppColors.amber : Colors.white70,
                              fontSize: 12,
                              fontWeight: hot ? FontWeight.w800 : FontWeight.w400)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('$count',
                    style: TextStyle(
                        color: hot ? AppColors.amber : Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, VoidCallback onTap) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      radius: 16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(gradient: AppColors.softGradient, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.primaryDark, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final today = s.todayOrders;
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    // Menu mengikuti hak akses: karyawan hanya melihat yang diizinkan owner.
    final tiles = <Widget>[
      if (s.isOwner || s.canToggleService)
        _menuTile(Icons.local_laundry_service_outlined, 'Kelola Layanan', () => _open(context, const ServicesScreen())),
      if (s.isOwner)
        _menuTile(Icons.people_outline, 'Kelola Karyawan', () => _open(context, const EmployeesScreen())),
      _menuTile(Icons.person_pin_outlined, 'Pelanggan', () => _open(context, const CustomersScreen())),
      if (s.canExpense)
        _menuTile(Icons.attach_money, 'Pengeluaran', () => _open(context, const ExpensesScreen())),
      _menuTile(Icons.lock_outline, 'Ganti Password', () => _open(context, const PasswordScreen())),
      if (s.isOwner)
        _menuTile(Icons.business_outlined, 'Profil Usaha', () => _open(context, const ProfileScreen())),
    ];

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          GradientPanel(
            lightStatusBar: true,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 18, 16, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Halo, ${s.greetingName}',
                              style: const TextStyle(color: AppColors.amber, fontSize: 21, fontWeight: FontWeight.w800)),
                          Text(s.profile.businessName, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const BrandPill(),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withAlpha(50)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: s.canReport ? () => onGoToTab(3) : null,
                        child: Row(
                          children: [
                            const IconCircle(Icons.account_balance_wallet_outlined,
                                size: 32, color: Colors.white, bg: Color(0x33FFFFFF)),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text('OMSET HARI INI',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                            ),
                            if (s.canReport) const Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(rupiah(sumTotal(today)),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 10),
                      Divider(color: Colors.white.withAlpha(60), height: 1),
                      const SizedBox(height: 10),
                      if (s.isOwner)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sudah diterima', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text(rupiah(sumPaid(today)),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 34, color: Colors.white.withAlpha(60)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Transaksi', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('${today.length}',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 16, color: Colors.white70),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('${today.length} transaksi hari ini di ${s.profile.businessName}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 14),
                      const Text('CUCIAN BELUM SELESAI',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _countTile(
                            context,
                            'Terlambat',
                            s.overdueOrders.length,
                            const OrderListScreen(title: 'Cucian Terlambat', filter: OrderFilterKind.overdue),
                            alert: true,
                          ),
                          const SizedBox(width: 8),
                          _countTile(context, 'Hari Ini', s.dueOn(now).length,
                              const OrderListScreen(title: 'Selesai Hari Ini', filter: OrderFilterKind.dueToday)),
                          const SizedBox(width: 8),
                          _countTile(context, 'Besok', s.dueOn(tomorrow).length,
                              const OrderListScreen(title: 'Selesai Besok', filter: OrderFilterKind.dueTomorrow)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Menu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                  children: tiles,
                ),
                const SizedBox(height: 16),
                AppCard(
                  onTap: () => _confirmLogout(context),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const IconCircle(Icons.logout, size: 44, color: AppColors.danger, bg: Color(0x1FE0264A)),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Keluar',
                                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger, fontSize: 16)),
                            Text('Akhiri sesi di perangkat ini', style: TextStyle(color: AppColors.muted, fontSize: 13)),
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
