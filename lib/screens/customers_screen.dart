import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

Future<void> showCustomerForm(BuildContext context, {Customer? existing}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _CustomerFormSheet(existing: existing),
  );
}

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';

  Future<void> _delete(Customer c) async {
    final state = context.read<AppState>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDelete(
      context,
      title: 'Hapus pelanggan?',
      message: '${c.name} akan dihapus dari daftar pelanggan. Riwayat transaksinya tetap tersimpan.',
    );
    if (!ok) return;
    await state.deleteCustomer(c.id);
    messenger.showSnackBar(SnackBar(content: Text('${c.name} dihapus.')));
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = _query.toLowerCase();
    final list = state.customers
        .where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: lkAppBar('Pelanggan'),
      floatingActionButton: LkFab(
        onPressed: () => showCustomerForm(context),
        tooltip: 'Tambah pelanggan',
        child: const Icon(Icons.person_add_alt_1_outlined),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim()),
              decoration: inputDeco('Cari nama atau nomor HP', icon: Icons.search, plain: true),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Pelanggan tidak ditemukan',
                    message: 'Ubah kata kunci, atau tambahkan pelanggan baru.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final c = list[i];
                      return AppCard(
                        onTap: () => showCustomerForm(context, existing: c),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            GradientAvatar(
                              soft: true,
                              child: Text(c.initial,
                                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                                  Text(c.phone.isEmpty ? 'Tanpa nomor HP' : c.phone,
                                      style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('${state.customerOrderCount(c.id)}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                                const Text('transaksi', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                              ],
                            ),
                            IconButton(
                              tooltip: 'Hapus pelanggan',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => _delete(c),
                              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerFormSheet extends StatefulWidget {
  const _CustomerFormSheet({this.existing});
  final Customer? existing;

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.existing?.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final c = widget.existing!;
    final state = context.read<AppState>();
    final ok = await confirmDelete(
      context,
      title: 'Hapus pelanggan?',
      message: '${c.name} akan dihapus dari daftar pelanggan. Riwayat transaksinya tetap tersimpan.',
    );
    if (!ok) return;
    await state.deleteCustomer(c.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    await context.read<AppState>().saveCustomer(
          Customer(id: widget.existing?.id ?? '', name: _name.text.trim(), phone: _phone.text.trim()),
        );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.existing == null ? 'Tambah pelanggan' : 'Ubah pelanggan',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: inputDeco('Nama Pelanggan', icon: Icons.person_outline),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: inputDeco('No. HP (opsional)', icon: Icons.phone_outlined),
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  return digits.isNotEmpty && digits.length < 9 ? 'Nomor HP tidak valid' : null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    onPressed: _saving ? null : _delete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus Pelanggan'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
