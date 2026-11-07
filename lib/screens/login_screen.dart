import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import 'register_screen.dart';

/// Header gradien yang dipakai layar masuk dan daftar.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.icon, required this.subtitle, this.title});
  final IconData icon;
  final String subtitle;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return GradientPanel(
      lightStatusBar: true,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 28, 24, 32),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(color: Colors.white.withAlpha(50), shape: BoxShape.circle),
              child: Icon(icon, size: 38, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const BrandPill(large: true),
            if (title != null) ...[
              const SizedBox(height: 14),
              Text(title!, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            ],
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Isi email dan password terlebih dahulu.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    final err = await context.read<AppState>().login(_email.text, _pass.text);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = err;
    });
  }

  Future<void> _forgot() async {
    final ctl = TextEditingController(text: _email.text);
    final messenger = ScaffoldMessenger.of(context);
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lupa password?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan email akun Anda. Tautan untuk mengatur ulang password akan dikirim ke sana.'),
            const SizedBox(height: 14),
            TextField(
              controller: ctl,
              keyboardType: TextInputType.emailAddress,
              decoration: inputDeco('Email', icon: Icons.mail_outline),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(ctl.text.trim()), child: const Text('Kirim tautan')),
        ],
      ),
    );
    ctl.dispose();
    if (email != null && email.isNotEmpty) {
      messenger.showSnackBar(SnackBar(content: Text('Tautan reset dikirim ke $email (mode demo).')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const AuthHeader(icon: Icons.local_laundry_service_outlined, subtitle: 'Masuk ke akun kamu'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: inputDeco('Email', icon: Icons.mail_outline),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: _obscure,
                    onSubmitted: (_) => _submit(),
                    decoration: inputDeco('Password', icon: Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Tampilkan password' : 'Sembunyikan password',
                        icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
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
                          : const Text('Masuk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(onPressed: _forgot, child: const Text('Lupa password?')),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: const Text('Belum punya akun? Daftar usaha baru'),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 24),
            child: Text('Owner demo: admin@laundryku.com / admin123\nKaryawan demo: sari@laundryku.com / sari123',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
          ),
        ],
      ),
    );
  }
}
