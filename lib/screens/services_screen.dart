import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import 'service_form_screen.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final Set<String> _collapsed = {};

  void _openForm({LaundryService? existing}) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ServiceFormScreen(existing: existing)));
  }

  Widget _tag(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(8)),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sections = <Widget>[];

    for (final cat in state.categories) {
      final list = state.services.where((s) => s.categoryId == cat.id).toList();
      final collapsed = _collapsed.contains(cat.id);
      sections.add(Padding(
        padding: const EdgeInsets.only(top: 12),
        child: AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => setState(() => collapsed ? _collapsed.remove(cat.id) : _collapsed.add(cat.id)),
          child: Row(
            children: [
              IconCircle(categoryIcon(cat.name), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text(cat.flow, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              Icon(collapsed ? Icons.expand_more : Icons.expand_less, color: AppColors.ink),
            ],
          ),
        ),
      ));
      if (collapsed) continue;
      if (list.isEmpty) {
        sections.add(const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Text('Belum ada layanan di kategori ini.', style: TextStyle(color: AppColors.muted, fontSize: 13)),
        ));
      }
      for (final s in list) {
        sections.add(Padding(
          padding: const EdgeInsets.only(top: 8, left: 10, right: 2),
          child: AppCard(
            radius: 16,
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            onTap: state.isOwner ? () => _openForm(existing: s) : null,
            child: Row(
              children: [
                Expanded(
                  child: Opacity(
                    opacity: s.active ? 1 : 0.5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15)),
                        Text('${rupiah(s.price)} / ${s.unit.label}',
                            style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: [
                            _tag(s.durationLabel, AppColors.primaryDark),
                            _tag('Min ${formatQty(s.minQty)} ${s.unit.label}', AppColors.warning),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Switch(
                  value: s.active,
                  onChanged: state.canToggleService
                      ? (v) => context.read<AppState>().saveService(s.copyWith(active: v))
                      : null,
                ),
              ],
            ),
          ),
        ));
      }
    }

    return Scaffold(
      appBar: lkAppBar('Kelola Layanan'),
      floatingActionButton: state.isOwner
          ? FloatingActionButton(
              onPressed: () => _openForm(),
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              tooltip: 'Tambah layanan',
              child: const Icon(Icons.add),
            )
          : null,
      body: state.categories.isEmpty
          ? const EmptyState(
              icon: Icons.local_laundry_service_outlined,
              title: 'Belum ada layanan',
              message: 'Tekan tombol + untuk menambahkan layanan pertama.',
            )
          : ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 96), children: sections),
    );
  }
}
