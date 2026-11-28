import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/order_card.dart';
import 'order_detail_screen.dart';

/// Tab "Transaksi": daftar transaksi per status, ditambah tab Dibatalkan.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // 0..3 = urutan OrderStatus, 4 = Dibatalkan
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final cancelledTab = OrderStatus.values.length;
    final labels = [...OrderStatus.values.map((e) => e.label), 'Dibatalkan'];
    int countOf(int i) => i == cancelledTab ? s.cancelledOrders.length : s.countStatus(OrderStatus.values[i]);

    final list = _tab == cancelledTab
        ? s.cancelledOrders
        : s.orders.where((o) => !o.cancelled && o.status.index == _tab).toList();

    return Scaffold(
      appBar: lkAppBar('Transaksi'),
      body: Column(
        children: [
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var i = 0; i < labels.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LkChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(labels[i]),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: _tab == i ? Colors.white.withAlpha(60) : AppColors.field,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('${countOf(i)}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _tab == i ? Colors.white : AppColors.muted)),
                          ),
                        ],
                      ),
                      selected: _tab == i,
                      labelStyle:
                          TextStyle(color: _tab == i ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                      onSelected: (_) => setState(() => _tab = i),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long,
                    title: 'Belum ada transaksi',
                    message: 'Buat transaksi baru lewat tab Transaksi Baru.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => OrderCard(
                      order: list[i],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: list[i].id)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
