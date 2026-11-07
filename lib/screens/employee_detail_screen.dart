import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/permission_picker.dart';

/// Atur hak akses dan ganti password seorang karyawan.
class EmployeeDetailScreen extends StatefulWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _newPass = TextEditingController();
  final _confirm = TextEditingController();
  Set<AppPermission>? _perms;
  bool _savingPerms = false;
  bool _savingPass = false;
  String? _passError;

  @override
  void dispose() {
    _newPass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _savePerms(Employee e) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _savingPerms = true);
    await context.read<AppState>().saveEmployeePermissions(e.id, _perms ?? e.permissions);
    if (!mounted) return;
    setState(() => _savingPerms = false);
    messenger.showSnackBar(const SnackBar(content: Text('Hak akses disimpan.')));
  }

  Future<void> _resetPassword(Employee e) async {
    if (_newPass.text.length < 6) {
      setState(() => _passError = 'Password baru minimal 6 karakter.');
      return;
    }
    if (_newPass.text != _confirm.text) {
      setState(() => _passError = 'Konfirmasi password tidak sama.');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _savingPass = true;
      _passError = null;
    });
    await context.read<AppState>().resetEmployeePassword(e.id, _newPass.text);
    if (!mounted) return;
    _newPass.clear();
    _confirm.clear();
    setState(() => _savingPass = false);
    messenger.showSnackBar(
      const SnackBar(content: Text('Password diganti. Beri tahu karyawan password barunya.')),
    );
  }

  Future<void> _delete(Employee e) async {
    final state = context.read<AppState>();
    final ok = await confirmDelete(
      context,
      title: 'Hapus karyawan?',
      message: 'Akun login ${e.name} akan dihapus dan tidak bisa masuk lagi ke aplikasi.',
      confirmLabel: 'Hapus Akun',
    );
    if (!ok) return;
    await state.deleteEmployee(e.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final e = state.employeeById(widget.employeeId);
    if (e == null) {
      return Scaffold(
        appBar: lkAppBar('Detail Karyawan'),
        body: const EmptyState(
          icon: Icons.person_outline,
          title: 'Karyawan tidak ditemukan',
          message: 'Akun karyawan ini mungkin sudah dihapus.',
        ),
      );
    }
    final perms = _perms ?? e.permissions;

    return Scaffold(
      appBar: lkAppBar('Detail Karyawan'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryDark,
                  child: Text(e.initial,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.ink)),
                      Text('Karyawan ${state.profile.businessName}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(e.email, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                      if (e.phone.isNotEmpty)
                        Text(e.phone, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.verified_user,
            title: 'Hak Akses & Pekerjaan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Daftar pekerjaan yang dapat dilakukan karyawan.',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 12),
                PermissionPicker(selected: perms, onChanged: (p) => setState(() => _perms = p)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _savingPerms ? null : () => _savePerms(e),
              icon: const Icon(Icons.save_outlined),
              label: Text(_savingPerms ? 'Menyimpan...' : 'Simpan Perubahan'),
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.vpn_key,
            title: 'Ganti Password Karyawan',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Atur password baru tanpa perlu tahu password lama. Beri tahu karyawan password barunya.',
                    style: TextStyle(color: AppColors.muted, height: 1.4)),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPass,
                  obscureText: true,
                  decoration: inputDeco('Password Baru', icon: Icons.lock_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: inputDeco('Konfirmasi Password Baru', icon: Icons.lock_outline),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                    SizedBox(width: 6),
                    Text('Password baru minimal 6 karakter.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
                if (_passError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_passError!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _savingPass ? null : () => _resetPassword(e),
              icon: const Icon(Icons.lock_outline),
              label: Text(_savingPass ? 'Menyimpan...' : 'Ganti Password'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
              ),
              onPressed: () => _delete(e),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus Akun Karyawan'),
            ),
          ),
        ],
      ),
    );
  }
}
