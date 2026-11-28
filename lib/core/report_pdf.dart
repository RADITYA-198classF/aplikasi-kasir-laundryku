import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/models.dart';
import '../providers/app_state.dart'
    show sumTotal, sumPaid, sumExpense, paidByMethod;
import 'format.dart';

/// Bagian-bagian yang bisa dipilih untuk dimasukkan ke PDF laporan.
enum ReportSection {
  ringkasan('Ringkasan', 'Omzet, piutang, status, metode bayar'),
  harian('Rekap Harian / Bulanan', 'Omzet & uang masuk per hari atau bulan'),
  transaksi('Transaksi', 'Semua nota beserta statusnya'),
  rincianLayanan('Rincian Layanan', 'Setiap item layanan per nota'),
  layananTerlaris('Layanan Terlaris', 'Peringkat layanan per omzet'),
  pembayaran('Pembayaran', 'Daftar pembayaran yang masuk'),
  pengeluaran('Pengeluaran & Laba', 'Daftar pengeluaran dan laba bersih');

  const ReportSection(this.label, this.description);
  final String label;
  final String description;
}

// Warna PDF (sama dengan palet aplikasi).
final _primary = PdfColor.fromHex('#0B4FB3');
final _ink = PdfColor.fromHex('#0B2545');
final _muted = PdfColor.fromHex('#4F6B89');
final _soft = PdfColor.fromHex('#E3F2FD');
final _border = PdfColor.fromHex('#D0E4F7');
final _success = PdfColor.fromHex('#0FA36B');
final _danger = PdfColor.fromHex('#E0264A');

/// Font bawaan PDF hanya mendukung huruf Latin; karakter lain (emoji, dll.) dibuang agar tidak error.
String _t(String s) => s.replaceAll(RegExp(r'[^\u0000-\u00FF]'), '');

pw.Widget _heading(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
  child: pw.Text(
    _t(text),
    style: pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: _primary,
    ),
  ),
);

pw.Widget _emptyNote([String text = 'Tidak ada data pada periode ini.']) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 9, color: _muted)),
    );

pw.Widget _cell(
  String text, {
  bool right = false,
  bool bold = false,
  PdfColor? color,
}) => pw.Padding(
  padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
  child: pw.Text(
    _t(text),
    textAlign: right ? pw.TextAlign.right : pw.TextAlign.left,
    style: pw.TextStyle(
      fontSize: 8.5,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: color ?? _ink,
    ),
  ),
);

/// Tabel dengan baris judul berwarna (diulang di tiap halaman), isi, dan baris total opsional.
pw.Widget _table({
  required List<String> headers,
  required List<List<String>> rows,
  required Map<int, pw.TableColumnWidth> widths,
  Set<int> rightCols = const {},
  List<String>? footer,
}) {
  if (rows.isEmpty) return _emptyNote();
  return pw.Table(
    columnWidths: widths,
    border: pw.TableBorder.all(color: _border, width: 0.5),
    children: [
      pw.TableRow(
        repeat: true,
        decoration: pw.BoxDecoration(color: _primary),
        children: [
          for (var i = 0; i < headers.length; i++)
            _cell(
              headers[i],
              right: rightCols.contains(i),
              bold: true,
              color: PdfColors.white,
            ),
        ],
      ),
      for (final r in rows)
        pw.TableRow(
          children: [
            for (var i = 0; i < r.length; i++)
              _cell(r[i], right: rightCols.contains(i)),
          ],
        ),
      if (footer != null)
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _soft),
          children: [
            for (var i = 0; i < footer.length; i++)
              _cell(footer[i], right: rightCols.contains(i), bold: true),
          ],
        ),
    ],
  );
}

/// Dua kolom: label di kiri, nilai di kanan.
pw.Widget _keyValues(List<List<String>> rows, {PdfColor? lastColor}) {
  return pw.Table(
    columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
    border: pw.TableBorder.all(color: _border, width: 0.5),
    children: [
      for (var i = 0; i < rows.length; i++)
        pw.TableRow(
          children: [
            _cell(rows[i][0]),
            _cell(
              rows[i][1],
              right: true,
              bold: true,
              color: i == rows.length - 1 ? lastColor : null,
            ),
          ],
        ),
    ],
  );
}

/// Membuat PDF laporan. [orders] harus sudah tanpa transaksi yang dibatalkan
/// (pakai AppState.ordersCreatedBetween). Hasilnya berupa byte PDF siap dibagikan / disimpan.
Future<Uint8List> buildReportPdf({
  required String businessName,
  required String periodText,
  required List<LaundryOrder> orders,
  required List<Expense> expenses,
  required Set<ReportSection> sections,
  bool perMonth = false,
}) async {
  final sorted = [...orders]
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  final omzet = sumTotal(sorted);
  final received = sumPaid(sorted);
  final receivable = omzet - received;
  final expense = sumExpense(expenses);
  final profit = omzet - expense;
  final chosen = ReportSection.values.where(sections.contains).toList();

  final body = <pw.Widget>[
    // ---- judul
    pw.Text(
      _t(businessName.isEmpty ? 'LaundryKu' : businessName),
      style: pw.TextStyle(
        fontSize: 20,
        fontWeight: pw.FontWeight.bold,
        color: _primary,
      ),
    ),
    pw.SizedBox(height: 2),
    pw.Text('Laporan Keuangan', style: pw.TextStyle(fontSize: 13, color: _ink)),
    pw.SizedBox(height: 6),
    pw.Text(
      'Periode: $periodText',
      style: pw.TextStyle(fontSize: 10, color: _ink),
    ),
    pw.Text(
      'Dicetak: ${tanggalJam(DateTime.now())}  |  Transaksi dibatalkan tidak dihitung',
      style: pw.TextStyle(fontSize: 9, color: _muted),
    ),
    pw.SizedBox(height: 4),
    pw.Divider(color: _primary, thickness: 1.2),
  ];

  for (final section in chosen) {
    switch (section) {
      case ReportSection.ringkasan:
        body.add(_heading('Ringkasan'));
        body.add(
          _keyValues([
            ['Total omzet', rupiah(omzet)],
            ['Jumlah transaksi', '${sorted.length}'],
            ['Sudah diterima', rupiah(received)],
            ['   - Tunai', rupiah(paidByMethod(sorted, PayMethod.tunai))],
            ['   - QRIS', rupiah(paidByMethod(sorted, PayMethod.qris))],
            ['Piutang (belum dibayar)', rupiah(receivable)],
            ['Total pengeluaran', rupiah(expense)],
            ['Laba (omzet - pengeluaran)', rupiah(profit)],
          ], lastColor: profit >= 0 ? _success : _danger),
        );
        body.add(pw.SizedBox(height: 8));
        body.add(
          _keyValues([
            for (final st in OrderStatus.values)
              [
                'Status ${st.label}',
                '${sorted.where((o) => o.status == st).length} nota',
              ],
          ]),
        );
        break;

      case ReportSection.harian:
        body.add(_heading(perMonth ? 'Rekap Bulanan' : 'Rekap Harian'));
        final groups = <DateTime, List<LaundryOrder>>{};
        for (final o in sorted) {
          final d = perMonth
              ? DateTime(o.createdAt.year, o.createdAt.month)
              : startOfDay(o.createdAt);
          groups.putIfAbsent(d, () => <LaundryOrder>[]).add(o);
        }
        final keys = groups.keys.toList()..sort();
        body.add(
          _table(
            headers: [
              perMonth ? 'Bulan' : 'Tanggal',
              'Transaksi',
              'Omzet',
              'Uang Masuk',
            ],
            widths: const {
              0: pw.FlexColumnWidth(3),
              1: pw.FlexColumnWidth(1.4),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(2),
            },
            rightCols: {1, 2, 3},
            rows: [
              for (final d in keys)
                [
                  perMonth ? bulanTahun(d) : tanggal(d),
                  '${groups[d]!.length}',
                  rupiah(sumTotal(groups[d]!)),
                  rupiah(sumPaid(groups[d]!)),
                ],
            ],
            footer: [
              'Total',
              '${sorted.length}',
              rupiah(omzet),
              rupiah(received),
            ],
          ),
        );
        break;

      case ReportSection.transaksi:
        body.add(_heading('Transaksi'));
        body.add(
          _table(
            headers: [
              'Nota',
              'Tanggal',
              'Pelanggan',
              'Status',
              'Total',
              'Dibayar',
              'Sisa',
            ],
            widths: const {
              0: pw.FlexColumnWidth(2.3),
              1: pw.FlexColumnWidth(1.7),
              2: pw.FlexColumnWidth(2.4),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(1.7),
              5: pw.FlexColumnWidth(1.7),
              6: pw.FlexColumnWidth(1.5),
            },
            rightCols: {4, 5, 6},
            rows: [
              for (final o in sorted)
                [
                  o.invoice,
                  tanggal(o.createdAt),
                  o.customerName,
                  o.status.label,
                  rupiah(o.total),
                  rupiah(o.paid),
                  o.remaining == 0 ? 'Lunas' : rupiah(o.remaining),
                ],
            ],
            footer: [
              'Total',
              '',
              '',
              '',
              rupiah(omzet),
              rupiah(received),
              rupiah(receivable),
            ],
          ),
        );
        break;

      case ReportSection.rincianLayanan:
        body.add(_heading('Rincian Layanan per Nota'));
        body.add(
          _table(
            headers: [
              'Nota',
              'Pelanggan',
              'Layanan',
              'Jumlah',
              'Harga',
              'Subtotal',
            ],
            widths: const {
              0: pw.FlexColumnWidth(2.3),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(2.8),
              3: pw.FlexColumnWidth(1.3),
              4: pw.FlexColumnWidth(1.6),
              5: pw.FlexColumnWidth(1.7),
            },
            rightCols: {3, 4, 5},
            rows: [
              for (final o in sorted)
                for (final i in o.items)
                  [
                    o.invoice,
                    o.customerName,
                    i.name,
                    '${formatQty(i.qty)} ${i.unit.name}',
                    rupiah(i.price),
                    rupiah(i.subtotal),
                  ],
            ],
            footer: ['Total', '', '', '', '', rupiah(omzet)],
          ),
        );
        break;

      case ReportSection.layananTerlaris:
        body.add(_heading('Layanan Terlaris'));
        final byName = <String, _ServiceStat>{};
        for (final o in sorted) {
          for (final i in o.items) {
            final st = byName.putIfAbsent(
              i.name,
              () => _ServiceStat(i.unit.name),
            );
            st.qty += i.qty;
            st.omzet += i.subtotal;
            st.orders++;
          }
        }
        final ranked = byName.entries.toList()
          ..sort((a, b) => b.value.omzet.compareTo(a.value.omzet));
        body.add(
          _table(
            headers: ['#', 'Layanan', 'Jumlah', 'Nota', 'Omzet'],
            widths: const {
              0: pw.FixedColumnWidth(26),
              1: pw.FlexColumnWidth(4),
              2: pw.FlexColumnWidth(1.6),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(2),
            },
            rightCols: {2, 3, 4},
            rows: [
              for (var n = 0; n < ranked.length; n++)
                [
                  '${n + 1}',
                  ranked[n].key,
                  '${formatQty(ranked[n].value.qty)} ${ranked[n].value.unit}',
                  '${ranked[n].value.orders}',
                  rupiah(ranked[n].value.omzet),
                ],
            ],
          ),
        );
        break;

      case ReportSection.pembayaran:
        body.add(_heading('Pembayaran'));
        final pays = <_PayRow>[
          for (final o in sorted)
            for (final p in o.payments) _PayRow(p, o),
        ]..sort((a, b) => a.payment.date.compareTo(b.payment.date));
        body.add(
          _table(
            headers: ['Tanggal', 'Nota', 'Pelanggan', 'Metode', 'Jumlah'],
            widths: const {
              0: pw.FlexColumnWidth(2.2),
              1: pw.FlexColumnWidth(2.3),
              2: pw.FlexColumnWidth(2.4),
              3: pw.FlexColumnWidth(1.2),
              4: pw.FlexColumnWidth(1.8),
            },
            rightCols: {4},
            rows: [
              for (final r in pays)
                [
                  tanggalJam(r.payment.date),
                  r.order.invoice,
                  r.order.customerName,
                  r.payment.method.label,
                  rupiah(r.payment.amount),
                ],
            ],
            footer: ['Total', '', '', '', rupiah(received)],
          ),
        );
        break;

      case ReportSection.pengeluaran:
        body.add(_heading('Pengeluaran & Laba'));
        final exp = [...expenses]..sort((a, b) => a.date.compareTo(b.date));
        body.add(
          _table(
            headers: ['Tanggal', 'Kategori', 'Catatan', 'Jumlah'],
            widths: const {
              0: pw.FlexColumnWidth(1.8),
              1: pw.FlexColumnWidth(2.4),
              2: pw.FlexColumnWidth(3),
              3: pw.FlexColumnWidth(1.8),
            },
            rightCols: {3},
            rows: [
              for (final e in exp)
                [
                  tanggal(e.date),
                  e.category,
                  e.note.isEmpty ? '-' : e.note,
                  rupiah(e.amount),
                ],
            ],
            footer: ['Total', '', '', rupiah(expense)],
          ),
        );
        body.add(pw.SizedBox(height: 8));
        body.add(
          _keyValues([
            ['Total omzet', rupiah(omzet)],
            ['Total pengeluaran', '-${rupiah(expense)}'],
            ['Laba bersih', rupiah(profit)],
          ], lastColor: profit >= 0 ? _success : _danger),
        );
        break;
    }
  }

  final doc = pw.Document(
    title:
        'Laporan ${businessName.isEmpty ? 'LaundryKu' : businessName} - $periodText',
    author: businessName.isEmpty ? 'LaundryKu' : businessName,
    creator: 'Kasir LaundryKu',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      footer: (ctx) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Kasir LaundryKu',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              'Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (ctx) => body,
    ),
  );

  return doc.save();
}

class _ServiceStat {
  _ServiceStat(this.unit);
  final String unit;
  double qty = 0;
  int omzet = 0;
  int orders = 0;
}

class _PayRow {
  _PayRow(this.payment, this.order);
  final Payment payment;
  final LaundryOrder order;
}
