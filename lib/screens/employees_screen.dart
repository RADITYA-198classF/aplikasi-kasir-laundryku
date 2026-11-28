import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import 'employee_detail_screen.dart';
import 'employee_form_screen.dart';

/// Kelola Karyawan (khusus owner).
class EmployeesScreen extends StatelessWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final employees = context.watch<AppState>().employees;

    return Scaffold(
      appBar: lkAppBar('Kelola Karyawan'),
      floatingActionButton: LkFab(
        onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const EmployeeFormScreen())),
        tooltip: 'Karyawan baru',
        child: const Icon(Icons.add),
      ),
      body: employees.isEmpty
          ? const EmptyState(
              icon: Icons.people_outline,
              title: 'Belum ada karyawan',
              message: 'Tap tombol + untuk buat akun karyawan baru',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: employees.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final e = employees[i];
                return AppCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EmployeeDetailScreen(employeeId: e.id)),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GradientAvatar(
                            radius: 22,
                            child: Text(e.initial,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name,
                                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 16)),
                                Text(e.email, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Hapus karyawan',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            onPressed: () async {
                              final state = context.read<AppState>();
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = await confirmDelete(
                                context,
                                title: 'Hapus karyawan?',
                                message:
                                    'Akun login ${e.name} akan dihapus dan tidak bisa masuk lagi ke aplikasi.',
                              );
                              if (!ok) return;
                              await state.deleteEmployee(e.id);
                              messenger.showSnackBar(SnackBar(content: Text('${e.name} dihapus.')));
                            },
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.muted),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (e.permissions.isEmpty)
                        const Text('Belum ada hak akses', style: TextStyle(color: AppColors.muted, fontSize: 12))
                      else
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final p in e.permissions)
                              Pill(p.shortLabel, color: AppColors.primaryDark),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
