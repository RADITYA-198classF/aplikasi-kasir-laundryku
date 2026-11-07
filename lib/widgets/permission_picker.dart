import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../models/models.dart';

/// Pilihan "Hak Akses & Pekerjaan" karyawan: chip dengan lingkaran centang.
class PermissionPicker extends StatelessWidget {
  const PermissionPicker({super.key, required this.selected, required this.onChanged});

  final Set<AppPermission> selected;
  final ValueChanged<Set<AppPermission>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in AppPermission.values)
          _chip(p, selected.contains(p)),
      ],
    );
  }

  Widget _chip(AppPermission p, bool on) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: () {
        final next = Set<AppPermission>.of(selected);
        on ? next.remove(p) : next.add(p);
        onChanged(next);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: on ? AppColors.soft : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: on ? AppColors.primaryDark : AppColors.border, width: on ? 1.6 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(on ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 18, color: on ? AppColors.primaryDark : AppColors.muted),
            const SizedBox(width: 8),
            Text(p.label,
                style: TextStyle(
                    color: on ? AppColors.ink : AppColors.muted,
                    fontWeight: on ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
