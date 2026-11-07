import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/models.dart';
import 'common_widgets.dart';

class PaymentInput {
  const PaymentInput(this.method, this.amount);
  final PayMethod method;
  final int amount;
}

/// Dialog "Konfirmasi Pembayaran".
/// [fixedAmount] != null -> nominal tidak bisa diubah (dipakai saat membuat transaksi).
Future<PaymentInput?> showPaymentDialog(
  BuildContext context, {
  required int total,
  required int alreadyPaid,
  int? fixedAmount,
  String confirmLabel = 'Simpan',
}) {
  return showDialog<PaymentInput>(
    context: context,
    builder: (_) => _PaymentDialog(
      total: total,
      alreadyPaid: alreadyPaid,
      fixedAmount: fixedAmount,
      confirmLabel: confirmLabel,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.total,
    required this.alreadyPaid,
    required this.fixedAmount,
    required this.confirmLabel,
  });

  final int total;
  final int alreadyPaid;
  final int? fixedAmount;
  final String confirmLabel;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  PayMethod _method = PayMethod.tunai;
  late final TextEditingController _ctl = TextEditingController(
    text: '${widget.fixedAmount ?? (widget.total - widget.alreadyPaid)}',
  );

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  int get _amount => widget.fixedAmount ?? (int.tryParse(_ctl.text) ?? 0);
  int get _remaining {
    final r = widget.total - widget.alreadyPaid - _amount;
    return r < 0 ? 0 : r;
  }

  @override
  Widget build(BuildContext context) {
    final valid = _amount > 0;
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(child: IconCircle(Icons.attach_money, size: 68)),
            const SizedBox(height: 14),
            const Text('Konfirmasi Pembayaran',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            const Text('Periksa nominalnya sebelum dicatat.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 16),
            const Text('Metode pembayaran', style: TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final m in PayMethod.values) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _method = m),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _method == m ? AppColors.soft : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _method == m ? AppColors.primaryDark : AppColors.border,
                            width: _method == m ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(m.icon, size: 20, color: AppColors.primaryDark),
                            const SizedBox(width: 6),
                            Text(m.label, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (m != PayMethod.values.last) const SizedBox(width: 10),
                ],
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  if (widget.fixedAmount != null)
                    InfoRow('Uang diterima', rupiah(widget.fixedAmount!), bold: true)
                  else
                    TextField(
                      controller: _ctl,
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: inputDeco('Uang diterima', prefixText: 'Rp ', plain: true),
                    ),
                  const Divider(color: AppColors.border),
                  InfoRow('Sisa tagihan', rupiah(_remaining), bold: true,
                      valueColor: _remaining == 0 ? AppColors.success : AppColors.danger),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_remaining == 0 ? AppColors.success : AppColors.warning).withAlpha(28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(_remaining == 0 ? Icons.check_circle_outline : Icons.info_outline,
                      size: 18, color: _remaining == 0 ? AppColors.success : AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _remaining == 0 ? 'Transaksi jadi lunas setelah ini.' : 'Sisa tagihan dibayar saat cucian diambil.',
                      style: TextStyle(
                          color: _remaining == 0 ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: valid ? () => Navigator.of(context).pop(PaymentInput(_method, _amount)) : null,
                      child: Text(widget.confirmLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
