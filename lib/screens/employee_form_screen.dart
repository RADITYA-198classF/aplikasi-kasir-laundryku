import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/permission_picker.dart';

class EmployeeFormScreen extends StatefulWidget {
  const EmployeeFormScreen({super.key});

  @override
  State<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends State<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  Set<AppPermission> _perms = {AppPermission.transaksi, AppPermission.pengeluaran};
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await context.read<AppState>().createEmployee(
          name: _name.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
          permissions: _perms,
        );
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _saving = false;
        _error = err;
      });
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Akun karyawan dibuat.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: lkAppBar('Karyawan Baru'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            const Center(child: IconCircle(Icons.person_add_alt_1_outlined, size: 76)),
            const SizedBox(height: 12),
            const Text('Karyawan Baru',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('Buatkan akun login dan tentukan apa saja yang boleh dikerjakan.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            SectionCard(
              icon: Icons.assignment_ind_outlined,
              title: 'Data Karyawan',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: inputDeco('Nama Karyawan', icon: Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama karyawan wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: inputDeco('No. HP (opsional)', icon: Icons.phone_outlined),
                    validator: (v) {
                      final d = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                      return d.isNotEmpty && d.length < 9 ? 'Nomor HP tidak valid' : null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.vpn_key,
              title: 'Akun Login',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: inputDeco('Email untuk Login', icon: Icons.mail_outline),
                    validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((v ?? '').trim())
                        ? null
                        : 'Email tidak valid',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: inputDeco('Password Awal', icon: Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6 ? 'Password minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Minimal 6 karakter. Karyawan bisa menggantinya sendiri setelah login.',
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                    ],
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
                  PermissionPicker(selected: _perms, onChanged: (p) => setState(() => _perms = p)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
              ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(_saving ? 'Membuat akun...' : 'Buat Akun Karyawan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
