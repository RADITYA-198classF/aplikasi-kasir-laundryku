import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await context.read<AppState>().changePassword(_old.text, _new.text);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _error = 'Password lama salah.';
      });
      return;
    }
    messenger.showSnackBar(const SnackBar(content: Text('Password berhasil diganti.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: lkAppBar('Ganti Password'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            const Center(child: IconCircle(Icons.lock_outline, size: 76)),
            const SizedBox(height: 12),
            const Text('Ganti Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('Gunakan password yang sulit ditebak dan jangan dibagikan.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            AppCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _old,
                    obscureText: true,
                    decoration: inputDeco('Password Lama', icon: Icons.lock_outline),
                    validator: (v) => (v == null || v.isEmpty) ? 'Password lama wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _new,
                    obscureText: true,
                    decoration: inputDeco('Password Baru', icon: Icons.lock_outline),
                    validator: (v) => (v ?? '').length < 6 ? 'Password minimal 6 karakter' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: inputDeco('Konfirmasi Password Baru', icon: Icons.lock_outline),
                    validator: (v) => v != _new.text ? 'Konfirmasi password tidak sama' : null,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
