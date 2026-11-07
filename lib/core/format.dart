// Fungsi bantu format angka, tanggal, dan nomor telepon (tanpa paket tambahan).

const _bulan = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String _dua(int n) => n.toString().padLeft(2, '0');

/// 12500 -> "Rp 12.500"
String rupiah(num value) {
  final negative = value < 0;
  final s = value.abs().round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final remaining = s.length - i;
    buf.write(s[i]);
    if (remaining > 1 && remaining % 3 == 1) buf.write('.');
  }
  return '${negative ? '-' : ''}Rp ${buf.toString()}';
}

/// 2 -> "2", 2.5 -> "2,5"
String formatQty(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) {
    s = s.replaceAll(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  return s.replaceAll('.', ',');
}

String tanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';
String tanggalPendek(DateTime d) => '${d.day} ${_bulan[d.month - 1]}';
String jam(DateTime d) => '${_dua(d.hour)}:${_dua(d.minute)}';
String tanggalJam(DateTime d) => '${tanggal(d)}, ${jam(d)}';
String bulanTahun(DateTime d) => '${_bulanPanjang[d.month - 1]} ${d.year}';

String rangeText(DateTime from, DateTime to) =>
    sameDay(from, to) ? tanggal(from) : '${tanggal(from)} s/d ${tanggal(to)}';

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// 2026-11-04 -> "261104"
String invoiceDate(DateTime d) => '${_dua(d.year % 100)}${_dua(d.month)}${_dua(d.day)}';

String salam([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 11) return 'Selamat pagi';
  if (h < 15) return 'Selamat siang';
  if (h < 18) return 'Selamat sore';
  return 'Selamat malam';
}

/// 0812-3456-7890 -> 6281234567890 (format wa.me)
String normalizePhone(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.startsWith('0')) {
    d = '62${d.substring(1)}';
  } else if (d.startsWith('8')) {
    d = '62$d';
  }
  return d;
}
