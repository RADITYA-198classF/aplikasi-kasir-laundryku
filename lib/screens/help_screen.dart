import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/common_widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    ['Bagaimana cara membuat transaksi?',
        'Buka tab Transaksi Baru, pilih atau tambah pelanggan, tambahkan layanan ke keranjang beserta jumlahnya, lalu tekan Buat Transaksi. Isi Bayar di muka jika pelanggan sudah membayar sebagian atau seluruhnya.'],
    ['Bagaimana cara mengubah status cucian?',
        'Buka transaksi dari tab Transaksi, lalu tekan tombol di bagian bawah detail. Status berjalan berurutan: Antrian, Diproses, Selesai, Diambil.'],
    ['Bagaimana cara menghubungi pelanggan?',
        'Di detail transaksi tekan tombol Chat. WhatsApp akan terbuka dengan pesan status cucian yang sudah terisi. Setelah mengubah status, tekan Beritahu pelanggan pada pesan yang muncul di bawah.'],
    ['Bagaimana mencatat pelunasan atau pembayaran sisa?',
        'Di detail transaksi tekan Catat Pembayaran, pilih Tunai atau QRIS, lalu simpan. Sisa tagihan dan status Lunas akan diperbarui otomatis.'],
    ['Bagaimana mengatur layanan dan harga?',
        'Dari Beranda buka Kelola Layanan. Anda bisa menambah, mengubah, menonaktifkan, atau menghapus layanan. Perubahan harga hanya berlaku untuk transaksi baru.'],
    ['Apa arti Terlambat, Hari Ini, dan Besok di Beranda?',
        'Ketiganya menghitung cucian yang belum selesai berdasarkan estimasi selesai. Terlambat berarti estimasinya sudah lewat. Ketuk kotaknya untuk melihat daftar transaksinya.'],
    ['Bagaimana mencatat pengeluaran?',
        'Dari Beranda buka Pengeluaran lalu tekan tombol +, atau tekan Catat Pengeluaran di tab Laporan. Pengeluaran dipakai untuk menghitung laba.'],
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: lkAppBar('Bantuan'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const Text('Pertanyaan yang sering muncul',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
          const SizedBox(height: 12),
          for (final item in _faq)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: Text(item[0],
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 14.5)),
                    children: [Text(item[1], style: const TextStyle(color: AppColors.muted, height: 1.5))],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
