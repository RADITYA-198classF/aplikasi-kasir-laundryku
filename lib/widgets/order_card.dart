import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'common_widgets.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});

  final LaundryOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = order.isOverdue();
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order.invoice,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 14)),
              ),
              StatusPill(order.status, cancelled: order.cancelled),
            ],
          ),
          const SizedBox(height: 6),
          Text(order.customerName,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 15)),
          const SizedBox(height: 2),
          Text(order.itemsSummary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rupiah(order.total),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 13, color: overdue ? AppColors.danger : AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          overdue ? 'Terlambat, target ${tanggalPendek(order.dueAt)}' : 'Target ${tanggalPendek(order.dueAt)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: overdue ? AppColors.danger : AppColors.muted,
                            fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!order.cancelled) PayPill(paid: order.isPaid),
            ],
          ),
        ],
      ),
    );
  }
}
