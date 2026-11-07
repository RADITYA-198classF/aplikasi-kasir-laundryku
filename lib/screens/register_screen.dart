import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _business = TextEditingController();
  final _owner = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_business, _owner, _email, _phone, _pass, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AppState>().register(
          businessName: _business.text.trim(),
          ownerName: _owner.text.trim(),
          email: _email.text.trim(),
          phone: _phone.text.trim(),
          password: _pass.text,
        );
    if (!mounted) return;
    if (err == null) {
      // Login berhasil: tutup halaman daftar agar beranda terlihat.
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    setState(() {
      _loading = false;
      _error = err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const AuthHeader(
            icon: Icons.store_outlined,
            title: 'Daftar Usaha Laundry',
            subtitle: 'Buat akun untuk mulai mencatat transaksi',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _business,
                      textCapitalization: TextCapitalization.words,
                      decoration: inputDeco('Nama Usaha', icon: Icons.store_outlined),
                      validator: (v) => _required(v, 'Nama usaha'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _owner,
                      textCapitalization: TextCapitalization.words,
                      decoration: inputDeco('Nama Kamu (Owner)', icon: Icons.person_outline),
                      validator: (v) => _required(v, 'Nama owner'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      decoration: inputDeco('Email', icon: Icons.mail_outline),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Email tidak valid';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: inputDeco('No. HP', icon: Icons.phone_outlined),
                      validator: (v) =>
                          (v ?? '').replaceAll(RegExp(r'[^0-9]'), '').length < 9 ? 'Nomor HP tidak valid' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: inputDeco('Password', icon: Icons.lock_outline),
                      validator: (v) => (v ?? '').length < 6 ? 'Password minimal 6 karakter' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      decoration: inputDeco('Konfirmasi Password', icon: Icons.lock_outline),
                      validator: (v) => v != _pass.text ? 'Konfirmasi password tidak sama' : null,
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Sudah punya akun? Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
