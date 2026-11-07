import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';
import '../widgets/payment_dialog.dart';
import 'order_detail_screen.dart';

/// Tab "Transaksi Baru": pilih pelanggan, isi keranjang layanan, lalu buat transaksi.
class NewOrderScreen extends StatefulWidget {
  const NewOrderScreen({super.key, required this.onGoToTab});

  final ValueChanged<int> onGoToTab;

  @override
  State<NewOrderScreen> createState() => _NewOrderScreenState();
}

class _NewOrderScreenState extends State<NewOrderScreen> {
  final _search = TextEditingController();
  final _newName = TextEditingController();
  final _newPhone = TextEditingController();
  final _note = TextEditingController();
  final _advance = TextEditingController();

  Customer? _customer;
  bool _addingCustomer = false;
  bool _saving = false;
  final List<OrderItem> _cart = [];

  @override
  void dispose() {
    for (final c in [_search, _newName, _newPhone, _note, _advance]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _total => _cart.fold<int>(0, (s, i) => s + i.subtotal);

  void _reset() {
    setState(() {
      _customer = null;
      _addingCustomer = false;
      _saving = false;
      _cart.clear();
      _search.clear();
      _newName.clear();
      _newPhone.clear();
      _note.clear();
      _advance.clear();
    });
  }

  Future<void> _saveNewCustomer() async {
    final name = _newName.text.trim();
    if (name.isEmpty) return;
    final c = await context.read<AppState>().saveCustomer(Customer(id: '', name: name, phone: _newPhone.text.trim()));
    if (!mounted) return;
    setState(() {
      _customer = c;
      _addingCustomer = false;
      _newName.clear();
      _newPhone.clear();
    });
  }

  Future<void> _addService() async {
    final state = context.read<AppState>();
    while (true) {
      final service = await showServicePicker(context);
      if (service == null || !mounted) return;
      final category = state.categoryById(service.categoryId);
      final qty = await showQuantityDialog(context, service);
      if (!mounted) return;
      if (qty == null) return; // ditutup
      if (qty < 0) continue; // tombol kembali -> pilih layanan lain
      final item = OrderItem(
        serviceId: service.id,
        name: serviceFullName(category?.name ?? '', service.name),
        unit: service.unit,
        price: service.price,
        qty: qty,
        durationHours: service.durationHours,
      );
      setState(() {
        final i = _cart.indexWhere((x) => x.serviceId == item.serviceId);
        if (i >= 0) {
          _cart[i] = _cart[i].withQty(_cart[i].qty + qty);
        } else {
          _cart.add(item);
        }
      });
      return;
    }
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_customer == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Pilih pelanggan terlebih dahulu.')));
      return;
    }
    if (!context.read<AppState>().customers.any((c) => c.id == _customer!.id)) {
      setState(() => _customer = null);
      messenger.showSnackBar(const SnackBar(content: Text('Pelanggan ini sudah dihapus. Pilih pelanggan lain.')));
      return;
    }
    if (_cart.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('Tambahkan minimal satu layanan.')));
      return;
    }
    final advance = int.tryParse(_advance.text.trim()) ?? 0;
    if (advance > _total) {
      messenger.showSnackBar(const SnackBar(content: Text('Bayar di muka tidak boleh melebihi total tagihan.')));
      return;
    }

    PaymentInput? input;
    if (advance > 0) {
      input = await showPaymentDialog(
        context,
        total: _total,
        alreadyPaid: 0,
        fixedAmount: advance,
        confirmLabel: 'Buat Transaksi',
      );
      if (input == null || !mounted) return;
    }

    setState(() => _saving = true);
    try {
      final order = await context.read<AppState>().createOrder(
            customer: _customer!,
            items: List<OrderItem>.of(_cart),
            note: _note.text.trim(),
            firstPayment: input == null
                ? null
                : Payment(date: DateTime.now(), method: input.method, amount: input.amount),
          );
      if (!mounted) return;
      _reset();
      messenger.showSnackBar(SnackBar(content: Text('Transaksi ${order.invoice} dibuat.')));
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(const SnackBar(content: Text('Transaksi gagal dibuat. Coba lagi.')));
    }
  }

  Widget _stepHeader(int n, String title, {Widget? trailing}) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: AppColors.primaryDark, shape: BoxShape.circle),
          child: Text('$n', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink))),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _customerCard(AppState state) {
    final q = _search.text.trim().toLowerCase();
    final matches = state.customers
        .where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.phone.contains(q))
        .take(5)
        .toList();

    Widget body;
    if (_customer != null) {
      body = Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryDark,
              child: Text(_customer!.initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_customer!.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                  if (_customer!.phone.isNotEmpty)
                    Text(_customer!.phone, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.check_circle_outline, color: AppColors.primaryDark),
          ],
        ),
      );
    } else if (_addingCustomer) {
      body = Column(
        children: [
          TextField(
            controller: _newName,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: inputDeco('Nama Pelanggan', icon: Icons.person_outline),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _newPhone,
            keyboardType: TextInputType.phone,
            decoration: inputDeco('No. HP (opsional)', icon: Icons.phone_outlined),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _addingCustomer = false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveNewCustomer,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Simpan'),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      body = Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: inputDeco('Cari nama / no. HP pelanggan', icon: Icons.search),
          ),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            const EmptyBox(icon: Icons.people_outline, title: 'Belum ada pelanggan')
          else
            for (final c in matches)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  tileColor: AppColors.field,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.soft,
                    child: Text(c.initial, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.w800)),
                  ),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: c.phone.isEmpty ? null : Text(c.phone),
                  onTap: () => setState(() => _customer = c),
                ),
              ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => setState(() {
                _addingCustomer = true;
                _newName.text = _search.text.trim();
              }),
              icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
              label: const Text('Pelanggan Baru'),
            ),
          ),
        ],
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            1,
            'Pelanggan',
            trailing: _customer == null
                ? null
                : TextButton.icon(
                    onPressed: () => setState(() => _customer = null),
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: const Text('Ganti'),
                  ),
          ),
          const SizedBox(height: 12),
          body,
        ],
      ),
    );
  }

  Widget _cartCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader(
            2,
            'Layanan',
            trailing: _cart.isEmpty
                ? null
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(10)),
                    child: Text('${_cart.length}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)),
                  ),
          ),
          const SizedBox(height: 12),
          if (_cart.isEmpty)
            const EmptyBox(
              icon: Icons.shopping_cart_outlined,
              title: 'Keranjang masih kosong',
              message: 'Tambahkan minimal satu layanan.',
            )
          else
            for (var i = 0; i < _cart.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                  decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.soft, borderRadius: BorderRadius.circular(8)),
                        child: Text('${formatQty(_cart[i].qty)} ${_cart[i].unit.label}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppColors.primaryDark)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_cart[i].name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink)),
                            Text('${rupiah(_cart[i].price)} / ${_cart[i].unit.label}',
                                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Text(rupiah(_cart[i].subtotal),
                          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
                      IconButton(
                        tooltip: 'Hapus',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => setState(() => _cart.removeAt(i)),
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Layanan'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final due = _cart.isEmpty ? null : estimateDue(DateTime.now(), _cart);

    return Scaffold(
      appBar: lkAppBar('Transaksi Baru'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Row(
            children: [
              const Icon(Icons.store_outlined, size: 16, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Transaksi untuk ${state.profile.businessName}',
                    overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _customerCard(state),
          const SizedBox(height: 14),
          _cartCard(),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _stepHeader(3, 'Detail Tambahan'),
                const SizedBox(height: 12),
                TextField(
                  controller: _note,
                  decoration: inputDeco('Catatan (opsional)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _advance,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: inputDeco('Bayar di muka (opsional)', prefixText: 'Rp '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GradientPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Total Tagihan', style: TextStyle(color: Colors.white70)),
                    ),
                    Pill('${_cart.length} layanan', color: Colors.white, icon: Icons.shopping_cart_outlined, onDark: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(rupiah(_total),
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                if (due != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Estimasi selesai ${tanggalJam(due)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                    onPressed: _saving ? null : _submit,
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(_saving ? 'Menyimpan...' : 'Buat Transaksi'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pemilih layanan dan dialog jumlah
// ---------------------------------------------------------------------------

Future<LaundryService?> showServicePicker(BuildContext context) {
  return showModalBottomSheet<LaundryService>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _ServicePickerSheet(),
  );
}

class _ServicePickerSheet extends StatefulWidget {
  const _ServicePickerSheet();

  @override
  State<_ServicePickerSheet> createState() => _ServicePickerSheetState();
}

class _ServicePickerSheetState extends State<_ServicePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = _query.toLowerCase();

    final children = <Widget>[];
    for (final cat in state.categories) {
      final list = state.services
          .where((s) => s.active && s.categoryId == cat.id)
          .where((s) => q.isEmpty || s.name.toLowerCase().contains(q) || cat.name.toLowerCase().contains(q))
          .toList();
      if (list.isEmpty) continue;
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
        child: Row(
          children: [
            Icon(categoryIcon(cat.name), size: 18, color: AppColors.primaryDark),
            const SizedBox(width: 8),
            Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          ],
        ),
      ));
      for (final s in list) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: ListTile(
            tileColor: AppColors.field,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${rupiah(s.price)} / ${s.unit.label}, ${s.durationLabel}'),
            trailing: const Icon(Icons.add_circle_outline, color: AppColors.primaryDark),
            onTap: () => Navigator.of(context).pop(s),
          ),
        ));
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Pilih layanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim()),
                decoration: inputDeco('Cari layanan', icon: Icons.search),
              ),
            ),
            Expanded(
              child: children.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'Layanan tidak ditemukan',
                      message: 'Tambahkan layanan lewat menu Kelola Layanan di Beranda.',
                    )
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: children),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mengembalikan jumlah, null jika ditutup, atau -1 jika tombol kembali ditekan.
Future<double?> showQuantityDialog(BuildContext context, LaundryService service) {
  return showDialog<double>(context: context, builder: (_) => _QuantityDialog(service: service));
}

class _QuantityDialog extends StatefulWidget {
  const _QuantityDialog({required this.service});
  final LaundryService service;

  @override
  State<_QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<_QuantityDialog> {
  late final TextEditingController _ctl = TextEditingController(
    text: widget.service.minQty > 0 ? formatQty(widget.service.minQty) : '',
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  double get _qty => double.tryParse(_ctl.text.replaceAll(',', '.')) ?? 0;

  void _bump(double delta) {
    final next = (((_qty + delta) * 10).round() / 10);
    final v = next < 0 ? 0.0 : next;
    final text = v == 0 ? '' : formatQty(v);
    setState(() {
      _ctl.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.service;
    final step = s.unit == QtyUnit.pcs ? 1.0 : 0.5;
    final valid = _qty > 0 && _qty >= s.minQty;
    final subtotal = (_qty * s.price).round();

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Kembali',
                  onPressed: () => Navigator.of(context).pop(-1.0),
                  icon: const Icon(Icons.chevron_left),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      Text('${rupiah(s.price)} / ${s.unit.label}', style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Jumlah', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton.filledTonal(onPressed: () => _bump(-step), icon: const Icon(Icons.remove)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _ctl,
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                    textAlign: TextAlign.center,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
                    decoration: inputDeco('', suffixText: s.unit.label, hint: '0', plain: true),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(onPressed: () => _bump(step), icon: const Icon(Icons.add)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.muted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Minimum ${formatQty(s.minQty)} ${s.unit.label}, boleh pakai koma, misal 2,5',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  const Expanded(child: Text('Subtotal', style: TextStyle(color: AppColors.muted))),
                  Text(rupiah(subtotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: valid ? () => Navigator.of(context).pop(((_qty * 100).round()) / 100) : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Tambah ke Keranjang'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
