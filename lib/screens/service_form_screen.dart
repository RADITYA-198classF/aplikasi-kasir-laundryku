import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class ServiceFormScreen extends StatefulWidget {
  const ServiceFormScreen({super.key, this.existing});

  final LaundryService? existing;

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _price =
      TextEditingController(text: widget.existing == null ? '' : '${widget.existing!.price}');
  late final TextEditingController _min = TextEditingController(
      text: widget.existing == null ? '0' : formatQty(widget.existing!.minQty));
  late final TextEditingController _duration = TextEditingController(
      text: widget.existing == null ? '1' : '${widget.existing!.durationValue}');

  late String? _categoryId = widget.existing?.categoryId;
  late QtyUnit _unit = widget.existing?.unit ?? QtyUnit.kg;
  late DurationUnit _durationUnit = widget.existing?.durationUnit ?? DurationUnit.hari;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (_categoryId == null) {
      final cats = context.read<AppState>().categories;
      if (cats.isNotEmpty) _categoryId = cats.first.id;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _min.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final nameCtl = TextEditingController();
    final flowCtl = TextEditingController(text: 'Cuci -> Pengeringan');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategori baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: inputDeco('Nama kategori'),
            ),
            const SizedBox(height: 10),
            TextField(controller: flowCtl, decoration: inputDeco('Tahapan pengerjaan')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Simpan')),
        ],
      ),
    );
    final name = nameCtl.text.trim();
    final flow = flowCtl.text.trim();
    nameCtl.dispose();
    flowCtl.dispose();
    if (ok != true || name.isEmpty || !mounted) return;
    final cat = await context.read<AppState>().addCategory(name, flow.isEmpty ? 'Cuci -> Pengeringan' : flow);
    if (mounted) setState(() => _categoryId = cat.id);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_categoryId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Pilih kategori terlebih dahulu.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await context.read<AppState>().saveService(
            LaundryService(
              id: widget.existing?.id ?? '',
              categoryId: _categoryId!,
              name: _name.text.trim(),
              unit: _unit,
              price: int.parse(_price.text.trim()),
              minQty: double.tryParse(_min.text.replaceAll(',', '.')) ?? 0,
              durationValue: int.parse(_duration.text.trim()),
              durationUnit: _durationUnit,
              active: widget.existing?.active ?? true,
            ),
          );
    } catch (_) {
      // Buka kembali tombol Simpan; pesan error ditampilkan oleh handler global di main.dart.
      if (mounted) setState(() => _saving = false);
      rethrow;
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Layanan disimpan.')));
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final state = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text('"${widget.existing!.name}" akan dihapus. Transaksi lama tetap aman.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await state.deleteService(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final cats = context.watch<AppState>().categories;
    final editing = widget.existing != null;

    return Scaffold(
      appBar: lkAppBar('Form Layanan'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const Center(child: IconCircle(Icons.local_laundry_service_outlined, size: 76)),
            const SizedBox(height: 12),
            Text(editing ? 'Edit Layanan' : 'Layanan Baru',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('Perubahan harga hanya berlaku untuk transaksi baru.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            SectionCard(
              icon: Icons.category_outlined,
              title: 'Kategori',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in cats)
                    ChoiceChip(
                      label: Text(c.name),
                      selected: _categoryId == c.id,
                      showCheckmark: false,
                      selectedColor: AppColors.primaryDark,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: _categoryId == c.id ? AppColors.primaryDark : AppColors.border),
                      labelStyle: TextStyle(
                          color: _categoryId == c.id ? Colors.white : AppColors.ink, fontWeight: FontWeight.w600),
                      onSelected: (_) => setState(() => _categoryId = c.id),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 18),
                    label: const Text('Kategori Baru'),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: AppColors.border),
                    onPressed: _addCategory,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.label_outline,
              title: 'Informasi Layanan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: inputDeco('Nama Layanan', icon: Icons.local_laundry_service_outlined),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama layanan wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  const Text('Satuan', style: TextStyle(color: AppColors.muted)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<QtyUnit>(
                      showSelectedIcon: false,
                      segments: [
                        for (final u in QtyUnit.values) ButtonSegment<QtyUnit>(value: u, label: Text(u.label)),
                      ],
                      selected: {_unit},
                      onSelectionChanged: (v) => setState(() => _unit = v.first),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.attach_money,
              title: 'Harga & Minimum',
              trailing: Pill('${rupiah(int.tryParse(_price.text) ?? 0)} / ${_unit.label}', color: AppColors.primaryDark),
              child: Column(
                children: [
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: inputDeco('Harga', prefixText: 'Rp ', suffixText: '/ ${_unit.label}'),
                    validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'Harga harus lebih dari 0' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _min,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    decoration: inputDeco('Minimum pesanan (${_unit.label})', icon: Icons.tune),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Kasir tidak bisa memesan layanan ini di bawah jumlah minimum.',
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              icon: Icons.hourglass_empty,
              title: 'Durasi Pengerjaan',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _duration,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: inputDeco('Jumlah'),
                          validator: (v) => (int.tryParse((v ?? '').trim()) ?? 0) <= 0 ? 'Isi lebih dari 0' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: SegmentedButton<DurationUnit>(
                            showSelectedIcon: false,
                            segments: [
                              for (final u in DurationUnit.values)
                                ButtonSegment<DurationUnit>(value: u, label: Text(u.label)),
                            ],
                            selected: {_durationUnit},
                            onSelectionChanged: (v) => setState(() => _durationUnit = v.first),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AppColors.muted),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text('Dipakai menghitung estimasi selesai saat transaksi dibuat.',
                            style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      ),
                    ],
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
                label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
              ),
            ),
            if (editing) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                  ),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus Layanan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
