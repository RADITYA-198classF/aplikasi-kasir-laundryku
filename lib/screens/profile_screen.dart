import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _business;
  late final TextEditingController _owner;
  late final TextEditingController _phone;
  late final TextEditingController _hours;
  late final TextEditingController _wa;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().profile;
    _business = TextEditingController(text: p.businessName);
    _owner = TextEditingController(text: p.ownerName);
    _phone = TextEditingController(text: p.phone);
    _hours = TextEditingController(text: p.hours);
    _wa = TextEditingController(text: p.ownerWa);
  }

  @override
  void dispose() {
    for (final c in [_business, _owner, _phone, _hours, _wa]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final state = context.read<AppState>();
    setState(() => _saving = true);
    await state.saveProfile(state.profile.copyWith(
      businessName: _business.text.trim(),
      ownerName: _owner.text.trim(),
      phone: _phone.text.trim(),
      hours: _hours.text.trim(),
      ownerWa: _wa.text.trim(),
    ));
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Profil usaha disimpan.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<AppState>().profile.email;
    return Scaffold(
      appBar: lkAppBar('Profil Usaha'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
          children: [
            const Center(child: IconCircle(Icons.business, size: 100)),
            const SizedBox(height: 12),
            Text(_business.text.isEmpty ? 'Usaha Laundry' : _business.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            Text(email, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            SectionCard(
              icon: Icons.store_outlined,
              title: 'Informasi Usaha',
              child: Column(
                children: [
                  TextFormField(
                    controller: _business,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: inputDeco('Nama Usaha', icon: Icons.store_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama usaha wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _owner,
                    textCapitalization: TextCapitalization.words,
                    decoration: inputDeco('Nama Owner', icon: Icons.person_outline),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama owner wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: inputDeco('No. Telepon', icon: Icons.phone_outlined),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hours,
                    decoration: inputDeco('Jam Operasional', icon: Icons.access_time, hint: '08.00 - 20.00'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.chat_outlined,
              title: 'Nomor Owner di Pesan WhatsApp',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nomor ini dicantumkan pada pesan WhatsApp ke pelanggan sebagai kontak jika ada kendala pembayaran. Isi dengan nomor yang dipegang owner, bukan nomor HP kasir.',
                    style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _wa,
                    keyboardType: TextInputType.phone,
                    decoration: inputDeco('No. WA Owner', icon: Icons.chat_outlined),
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
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
