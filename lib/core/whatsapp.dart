import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import 'format.dart';

/// Isi pesan WhatsApp ke pelanggan sesuai status cucian saat ini.
String statusMessage(LaundryOrder o, BusinessProfile profile) {
  final shop = profile.businessName.isEmpty ? 'LaundryKu' : profile.businessName;
  final b = StringBuffer('Halo ${o.customerName}, ');
  if (o.cancelled) {
    b.write('transaksi Anda (${o.invoice}) telah dibatalkan. Salam, $shop.');
    return b.toString();
  }
  switch (o.status) {
    case OrderStatus.antrian:
      b.write('cucian Anda (${o.invoice}) sudah kami terima dan masuk antrian.');
      break;
    case OrderStatus.diproses:
      b.write('cucian Anda (${o.invoice}) sedang kami proses.');
      break;
    case OrderStatus.selesai:
      b.write('cucian Anda (${o.invoice}) sudah selesai dan siap diambil.');
      break;
    case OrderStatus.diambil:
      b.write('terima kasih, cucian Anda (${o.invoice}) sudah diambil.');
      break;
  }
  if (o.isActive) b.write(' Estimasi selesai ${tanggal(o.dueAt)}.');
  b.write(' Total tagihan ${rupiah(o.total)}');
  b.write(o.isPaid ? ' (sudah lunas).' : ', sisa ${rupiah(o.remaining)}.');
  if (profile.ownerWa.isNotEmpty) b.write(' Ada kendala? Hubungi owner: ${profile.ownerWa}.');
  b.write(' Salam, $shop.');
  return b.toString();
}

/// Membuka WhatsApp dengan pesan siap kirim. Mengembalikan false jika gagal.
Future<bool> openWhatsApp(LaundryOrder o, BusinessProfile profile) async {
  final phone = normalizePhone(o.customerPhone);
  if (phone.isEmpty) return false;
  final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(statusMessage(o, profile))}');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}
