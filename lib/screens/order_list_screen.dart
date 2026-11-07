import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

enum OrderFilterKind { overdue, dueToday, dueTomorrow }

/// Daftar transaksi yang belum selesai berdasarkan target selesai (dibuka dari Beranda).
class OrderListScreen extends StatelessWidget {
  const OrderListScreen({super.key, required this.title, required this.filter});

  final String title;
  final OrderFilterKind filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final List<LaundryOrder> list;
    switch (filter) {
      case OrderFilterKind.overdue:
        list = s.overdueOrders;
        break;
      case OrderFilterKind.dueToday:
        list = s.dueOn(DateTime.now());
        break;
      default:
        list = s.dueOn(DateTime.now().add(const Duration(days: 1)));
        break;
    }

    return Scaffold(
      appBar: lkAppBar(title),
      body: list.isEmpty
          ? const EmptyState(
              icon: Icons.check_circle_outline,
              title: 'Tidak ada cucian',
              message: 'Semua cucian pada kategori ini sudah beres.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => OrderCard(
                order: list[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: list[i].id)),
                ),
              ),
            ),
    );
  }
}
