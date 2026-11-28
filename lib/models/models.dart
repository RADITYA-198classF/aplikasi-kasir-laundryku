import 'package:flutter/material.dart';

import '../core/format.dart';

enum QtyUnit {
  kg('kg'),
  pcs('pcs'),
  m2('m²');

  const QtyUnit(this.label);
  final String label;
}

enum DurationUnit {
  hari('Hari', 24),
  jam('Jam', 1);

  const DurationUnit(this.label, this.hours);
  final String label;
  final int hours;
}

enum PayMethod {
  tunai('Tunai', Icons.attach_money),
  qris('QRIS', Icons.qr_code_scanner);

  const PayMethod(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Alur cucian: Antrian -> Diproses -> Selesai -> Diambil.
enum OrderStatus {
  antrian('Antrian', Icons.hourglass_empty, 'Mulai proses'),
  diproses('Diproses', Icons.autorenew, 'Tandai selesai'),
  selesai('Selesai', Icons.check_circle_outline, 'Tandai diambil'),
  diambil('Diambil', Icons.local_mall_outlined, '');

  const OrderStatus(this.label, this.icon, this.advanceLabel);
  final String label;
  final IconData icon;
  final String advanceLabel;

  OrderStatus? get next =>
      index + 1 < OrderStatus.values.length ? OrderStatus.values[index + 1] : null;
}

/// Nama layanan di keranjang: kategori + nama (kategori "Cuci Kiloan" tidak ditulis).
String serviceFullName(String categoryName, String serviceName) =>
    categoryName.toLowerCase().contains('kiloan') ? serviceName : '$categoryName $serviceName';

class ExpenseCategory {
  const ExpenseCategory(this.name, this.icon);
  final String name;
  final IconData icon;
}

const expenseCategories = [
  ExpenseCategory('Deterjen & Pewangi', Icons.cleaning_services_outlined),
  ExpenseCategory('Plastik & Kemasan', Icons.widgets_outlined),
  ExpenseCategory('Gas / LPG', Icons.local_fire_department_outlined),
  ExpenseCategory('Listrik', Icons.flash_on),
  ExpenseCategory('Air (PDAM / Galon)', Icons.opacity),
  ExpenseCategory('Gaji Karyawan', Icons.people_outline),
  ExpenseCategory('Sewa Tempat', Icons.store_outlined),
  ExpenseCategory('Perawatan & Servis Mesin', Icons.build_outlined),
  ExpenseCategory('Transportasi / Antar-Jemput', Icons.local_shipping_outlined),
  ExpenseCategory('Internet & Pulsa', Icons.wifi),
  ExpenseCategory('Lainnya', Icons.more_horiz),
];

IconData expenseIcon(String category) {
  for (final c in expenseCategories) {
    if (c.name == category) return c.icon;
  }
  return Icons.more_horiz;
}

/// Ikon tambahan dari font LaundryIcons (lihat pubspec.yaml).
class LkIcons {
  static const shoe = IconData(0xE900, fontFamily: 'LaundryIcons');
  static const teddyBear = IconData(0xE901, fontFamily: 'LaundryIcons');
}

IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('kiloan')) return Icons.local_laundry_service_outlined;
  if (n.contains('bed')) return Icons.hotel_outlined;
  if (n.contains('boneka')) return LkIcons.teddyBear;
  if (n.contains('sepatu')) return LkIcons.shoe;
  if (n.contains('tas')) return Icons.work_outline;
  if (n.contains('karpet')) return Icons.texture;
  return Icons.category_outlined;
}

class BusinessProfile {
  const BusinessProfile({
    required this.businessName,
    required this.ownerName,
    required this.email,
    required this.phone,
    this.hours = '',
    this.ownerWa = '',
  });

  final String businessName;
  final String ownerName;
  final String email;
  final String phone;
  final String hours;
  final String ownerWa;

  String get ownerFirstName {
    final t = ownerName.trim();
    return t.isEmpty ? 'Owner' : t.split(' ').first;
  }

  BusinessProfile copyWith({
    String? businessName,
    String? ownerName,
    String? phone,
    String? hours,
    String? ownerWa,
  }) {
    return BusinessProfile(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      email: email,
      phone: phone ?? this.phone,
      hours: hours ?? this.hours,
      ownerWa: ownerWa ?? this.ownerWa,
    );
  }
}

class Customer {
  const Customer({required this.id, required this.name, this.phone = ''});
  final String id;
  final String name;
  final String phone;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
}

class ServiceCategory {
  const ServiceCategory({required this.id, required this.name, this.flow = 'Cuci -> Pengeringan'});
  final String id;
  final String name;
  final String flow;
}

class LaundryService {
  const LaundryService({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.unit,
    required this.price,
    required this.minQty,
    required this.durationValue,
    required this.durationUnit,
    this.active = true,
  });

  final String id;
  final String categoryId;
  final String name;
  final QtyUnit unit;
  final int price;
  final double minQty;
  final int durationValue;
  final DurationUnit durationUnit;
  final bool active;

  int get durationHours => durationValue * durationUnit.hours;
  String get durationLabel => '$durationValue ${durationUnit.label}';

  LaundryService copyWith({bool? active}) {
    return LaundryService(
      id: id,
      categoryId: categoryId,
      name: name,
      unit: unit,
      price: price,
      minQty: minQty,
      durationValue: durationValue,
      durationUnit: durationUnit,
      active: active ?? this.active,
    );
  }
}

class OrderItem {
  const OrderItem({
    required this.serviceId,
    required this.name,
    required this.unit,
    required this.price,
    required this.qty,
    required this.durationHours,
  });

  final String serviceId;
  final String name;
  final QtyUnit unit;
  final int price;
  final double qty;
  final int durationHours;

  int get subtotal => (qty * price).round();

  OrderItem withQty(double q) => OrderItem(
        serviceId: serviceId,
        name: name,
        unit: unit,
        price: price,
        qty: q,
        durationHours: durationHours,
      );
}

class Payment {
  const Payment({required this.date, required this.method, required this.amount});
  final DateTime date;
  final PayMethod method;
  final int amount;
}

class StatusLog {
  const StatusLog({required this.status, required this.time});
  final OrderStatus status;
  final DateTime time;
}

/// Estimasi selesai = waktu masuk + durasi layanan terlama di keranjang.
DateTime estimateDue(DateTime from, List<OrderItem> items) {
  var hours = 0;
  for (final i in items) {
    if (i.durationHours > hours) hours = i.durationHours;
  }
  return from.add(Duration(hours: hours));
}

class LaundryOrder {
  LaundryOrder({
    required this.id,
    required this.invoice,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.status,
    required this.createdAt,
    required this.dueAt,
    required this.payments,
    required this.logs,
    this.note = '',
    this.cancelled = false,
  });

  final String id;
  final String invoice;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime dueAt;
  final String note;
  final List<Payment> payments;
  final List<StatusLog> logs;
  final bool cancelled;

  int get total => items.fold<int>(0, (s, i) => s + i.subtotal);
  int get paid => payments.fold<int>(0, (s, p) => s + p.amount);
  int get remaining => total - paid > 0 ? total - paid : 0;
  bool get isPaid => remaining == 0;

  /// Belum selesai dikerjakan.
  bool get isActive =>
      !cancelled && (status == OrderStatus.antrian || status == OrderStatus.diproses);

  bool isOverdue([DateTime? now]) =>
      isActive && startOfDay(dueAt).isBefore(startOfDay(now ?? DateTime.now()));

  String get itemsSummary => items.map((i) => i.name).join(', ');

  DateTime? timeOf(OrderStatus s) {
    for (final l in logs) {
      if (l.status == s) return l.time;
    }
    return null;
  }

  LaundryOrder copyWith({
    OrderStatus? status,
    List<Payment>? payments,
    List<StatusLog>? logs,
    bool? cancelled,
  }) {
    return LaundryOrder(
      id: id,
      invoice: invoice,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      items: items,
      status: status ?? this.status,
      createdAt: createdAt,
      dueAt: dueAt,
      payments: payments ?? this.payments,
      logs: logs ?? this.logs,
      note: note,
      cancelled: cancelled ?? this.cancelled,
    );
  }
}

class Expense {
  const Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.amount,
    this.note = '',
  });

  final String id;
  final DateTime date;
  final String category;
  final int amount;
  final String note;
}

/// Hak akses karyawan (label sesuai halaman Karyawan Baru).
enum AppPermission {
  transaksi('Transaksi', 'Transaksi'),
  batalBayar('Batalkan Transaksi yang Sudah Dibayar', 'Batalkan transaksi'),
  layanan('Aktif/Nonaktifkan Layanan', 'Layanan'),
  pengeluaran('Pengeluaran', 'Pengeluaran'),
  laporan('Akses Laporan', 'Laporan');

  const AppPermission(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.permissions = const {},
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final Set<AppPermission> permissions;

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  Employee withPermissions(Set<AppPermission> p) =>
      Employee(id: id, name: name, email: email, phone: phone, permissions: p);
}

/// Hasil login: owner (employeeId null) atau karyawan dengan hak akses tertentu.
class AuthSession {
  const AuthSession({this.name = '', this.employeeId, this.permissions = const {}});
  final String name;
  final String? employeeId;
  final Set<AppPermission> permissions;

  bool get isOwner => employeeId == null;
}
