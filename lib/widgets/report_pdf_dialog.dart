import 'package:flutter/material.dart';

import '../core/report_pdf.dart';
import '../core/theme.dart';

/// Dialog "Unduh Laporan PDF": pengguna memilih isi laporan.
/// Mengembalikan bagian yang dipilih, atau null jika dibatalkan.
Future<Set<ReportSection>?> showReportPdfDialog(
  BuildContext context, {
  required String periodText,
}) {
  return showDialog<Set<ReportSection>>(
    context: context,
    builder: (_) => _ReportPdfDialog(periodText: periodText),
  );
}

class _ReportPdfDialog extends StatefulWidget {
  const _ReportPdfDialog({required this.periodText});

  final String periodText;

  @override
  State<_ReportPdfDialog> createState() => _ReportPdfDialogState();
}

class _ReportPdfDialogState extends State<_ReportPdfDialog> {
  final Set<ReportSection> _selected = {...ReportSection.values};

  bool get _all => _selected.length == ReportSection.values.length;

  void _toggleAll() {
    setState(() {
      if (_all) {
        _selected.clear();
      } else {
        _selected.addAll(ReportSection.values);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.soft,
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    color: AppColors.primaryDark,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Unduh Laporan PDF',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.periodText,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Isi Laporan',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(_all ? 'Hapus semua' : 'Pilih semua'),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (final section in ReportSection.values)
                        CheckboxListTile(
                          value: _selected.contains(section),
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _selected.add(section);
                            } else {
                              _selected.remove(section);
                            }
                          }),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primaryDark,
                          title: Text(
                            section.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          subtitle: Text(
                            section.description,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_selected.length} isi laporan dipilih',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => Navigator.of(context).pop(_selected),
                      child: const Text('Unduh PDF'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
