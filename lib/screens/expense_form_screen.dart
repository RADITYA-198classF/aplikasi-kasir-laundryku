import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../providers/app_state.dart';
import '../widgets/common_widgets.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _note = TextEditingController();
  final _amount = TextEditingController();
  DateTime _date = startOfDay(DateTime.now());
  String? _category;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final amount = int.tryParse(_amount.text.trim()) ?? 0;
    if (_category == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Pilih kategori pengeluaran.')));
      return;
    }
    if (amount <= 0) {
      messenger.showSnackBar(const SnackBar(content: Text('Isi nominal lebih dari 0.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AppState>().saveExpense(
            Expense(id: '', date: _date, category: _category!, amount: amount, note: _note.text.trim()),
          );
    } catch (_) {
      // Buka kembali tombol Simpan; pesan error ditampilkan oleh handler global di main.dart.
      if (mounted) setState(() => _saving = false);
      rethrow;
    }
    if (!mounted) return;
    messenger.showSnackBar(const SnackBar(content: Text('Pengeluaran dicatat.')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isToday = sameDay(_date, DateTime.now());
    return Scaffold(
      appBar: lkAppBar('Form Pengeluaran'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          const Center(child: IconCircle(Icons.attach_money, size: 76)),
          const SizedBox(height: 12),
          const Text('Pengeluaran Baru',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 4),
          const Text('Catat setiap uang keluar supaya laporan laba usaha akurat.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
          const SizedBox(height: 16),
          SectionCard(
            icon: Icons.calendar_today_outlined,
            title: 'Tanggal',
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.field,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event, color: AppColors.ink),
                    const SizedBox(width: 12),
                    Expanded(child: Text('${tanggal(_date)}${isToday ? ' (Hari ini)' : ''}', style: const TextStyle(fontSize: 15))),
                    const Icon(Icons.edit_outlined, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.category_outlined,
            title: 'Kategori Pengeluaran',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in expenseCategories)
                  ChoiceChip(
                    avatar: Icon(c.icon, size: 18, color: _category == c.name ? Colors.white : AppColors.primaryDark),
                    label: Text(c.name),
                    selected: _category == c.name,
                    showCheckmark: false,
                    selectedColor: AppColors.primaryDark,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: _category == c.name ? AppColors.primaryDark : AppColors.border),
                    labelStyle: TextStyle(
                        color: _category == c.name ? Colors.white : AppColors.ink, fontWeight: FontWeight.w500),
                    onSelected: (_) => setState(() => _category = c.name),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            icon: Icons.notes,
            title: 'Detail',
            child: Column(
              children: [
                TextField(controller: _note, decoration: inputDeco('Keterangan (opsional)', icon: Icons.description_outlined)),
                const SizedBox(height: 12),
                TextField(
                  controller: _amount,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: inputDeco('Nominal', prefixText: 'Rp '),
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
        ],
      ),
    );
  }
}
