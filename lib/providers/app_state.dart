import 'package:flutter/foundation.dart';

import '../core/format.dart';
import '../data/laundry_repository.dart';
import '../models/models.dart';

/// Satu-satunya sumber data untuk semua layar (dipakai lewat package provider).
class AppState extends ChangeNotifier {
  AppState(this._repo);

  final LaundryRepository _repo;

  bool loggedIn = false;
  AuthSession session = const AuthSession();
  BusinessProfile profile =
      const BusinessProfile(businessName: '', ownerName: '', email: '', phone: '');
  List<ServiceCategory> categories = [];
  List<LaundryService> services = [];
  List<Customer> customers = [];
  List<LaundryOrder> orders = [];
  List<Expense> expenses = [];
  List<Employee> employees = [];

  // ------------------------------------------------------------ hak akses
  bool get isOwner => session.isOwner;
  bool _can(AppPermission p) => isOwner || session.permissions.contains(p);
  bool get canTransaksi => _can(AppPermission.transaksi);
  bool get canCancelPaid => _can(AppPermission.batalBayar);
  bool get canToggleService => _can(AppPermission.layanan);
  bool get canExpense => _can(AppPermission.pengeluaran);
  bool get canReport => _can(AppPermission.laporan);

  /// Nama yang tampil pada sapaan "Halo, ...".
  String get greetingName => isOwner ? profile.ownerFirstName : session.name;

  // ---------------------------------------------------------------- auth
  /// Mengembalikan pesan error, atau null jika berhasil.
  Future<String?> login(String email, String password) async {
    try {
      final s = await _repo.login(email, password);
      if (s == null) return 'Email atau password salah.';
      session = s;
      await _loadAll();
      loggedIn = true;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Tidak dapat terhubung ke server. Coba lagi.';
    }
  }

  Future<String?> register({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      await _repo.register(
        businessName: businessName,
        ownerName: ownerName,
        email: email,
        phone: phone,
        password: password,
      );
      return await login(email, password);
    } on StateError catch (e) {
      return e.message;
    } catch (_) {
      return 'Pendaftaran gagal. Coba lagi.';
    }
  }

  void logout() {
    loggedIn = false;
    session = const AuthSession();
    notifyListeners();
  }

  /// true jika berhasil, false jika password lama salah (mengganti password akun yang sedang login).
  Future<bool> changePassword(String oldPassword, String newPassword) => _repo.changePassword(
        employeeId: session.employeeId,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );

  Future<void> _loadAll() async {
    profile = await _repo.fetchProfile();
    categories = await _repo.fetchCategories();
    services = await _repo.fetchServices();
    customers = await _repo.fetchCustomers();
    orders = await _repo.fetchOrders();
    expenses = await _repo.fetchExpenses();
    employees = session.isOwner ? await _repo.fetchEmployees() : <Employee>[];
    _sortOrders();
  }

  void _sortOrders() {
    orders = List<LaundryOrder>.of(orders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // -------------------------------------------------------------- profil
  Future<void> saveProfile(BusinessProfile p) async {
    profile = await _repo.saveProfile(p);
    notifyListeners();
  }

  // ------------------------------------------------------------ karyawan
  Employee? employeeById(String id) {
    for (final e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Mengembalikan pesan error, atau null jika akun karyawan berhasil dibuat.
  Future<String?> createEmployee({
    required String name,
    required String phone,
    required String email,
    required String password,
    required Set<AppPermission> permissions,
  }) async {
    try {
      final e = await _repo.createEmployee(
        name: name,
        phone: phone,
        email: email,
        password: password,
        permissions: permissions,
      );
      employees = [...employees, e];
      notifyListeners();
      return null;
    } on StateError catch (e) {
      return e.message;
    } catch (_) {
      return 'Akun karyawan gagal dibuat. Coba lagi.';
    }
  }

  Future<void> saveEmployeePermissions(String id, Set<AppPermission> permissions) async {
    final current = employeeById(id);
    if (current == null) return;
    final saved = await _repo.updateEmployee(current.withPermissions(permissions));
    employees = [for (final e in employees) e.id == saved.id ? saved : e];
    notifyListeners();
  }

  Future<void> deleteEmployee(String id) async {
    await _repo.deleteEmployee(id);
    employees = employees.where((e) => e.id != id).toList();
    notifyListeners();
  }

  Future<void> resetEmployeePassword(String id, String newPassword) =>
      _repo.resetEmployeePassword(id, newPassword);

  // ------------------------------------------------------------- layanan
  Future<ServiceCategory> addCategory(String name, String flow) async {
    final c = await _repo.saveCategory(ServiceCategory(id: '', name: name, flow: flow));
    categories = [...categories, c];
    notifyListeners();
    return c;
  }

  Future<LaundryService> saveService(LaundryService s) async {
    final saved = await _repo.saveService(s);
    final exists = services.any((x) => x.id == saved.id);
    services = exists
        ? [for (final x in services) x.id == saved.id ? saved : x]
        : [...services, saved];
    notifyListeners();
    return saved;
  }

  Future<void> deleteService(String id) async {
    await _repo.deleteService(id);
    services = services.where((s) => s.id != id).toList();
    notifyListeners();
  }

  ServiceCategory? categoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  // ----------------------------------------------------------- pelanggan
  Future<Customer> saveCustomer(Customer c) async {
    final saved = await _repo.saveCustomer(c);
    final exists = customers.any((x) => x.id == saved.id);
    customers = exists
        ? [for (final x in customers) x.id == saved.id ? saved : x]
        : [...customers, saved];
    notifyListeners();
    return saved;
  }

  Future<void> deleteCustomer(String id) async {
    await _repo.deleteCustomer(id);
    customers = customers.where((c) => c.id != id).toList();
    notifyListeners();
  }

  int customerOrderCount(String customerId) =>
      orders.where((o) => !o.cancelled && o.customerId == customerId).length;

  // ----------------------------------------------------------- transaksi
  LaundryOrder? orderById(String id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  Future<LaundryOrder> createOrder({
    required Customer customer,
    required List<OrderItem> items,
    String note = '',
    Payment? firstPayment,
  }) async {
    final o = await _repo.createOrder(
      customer: customer,
      items: items,
      note: note,
      firstPayment: firstPayment,
    );
    orders = [o, ...orders];
    notifyListeners();
    return o;
  }

  Future<LaundryOrder> advanceStatus(String orderId) async {
    final current = orderById(orderId);
    final next = current?.status.next;
    if (current == null || current.cancelled || next == null) {
      throw StateError('Status tidak dapat diubah');
    }
    final updated = await _repo.updateStatus(orderId, next);
    _replaceOrder(updated);
    return updated;
  }

  Future<LaundryOrder> addPayment(String orderId, PayMethod method, int amount) async {
    final updated = await _repo.addPayment(orderId, method, amount);
    _replaceOrder(updated);
    return updated;
  }

  Future<LaundryOrder> cancelOrder(String orderId) async {
    final updated = await _repo.cancelOrder(orderId);
    _replaceOrder(updated);
    return updated;
  }

  void _replaceOrder(LaundryOrder updated) {
    orders = [for (final o in orders) o.id == updated.id ? updated : o];
    notifyListeners();
  }

  // --------------------------------------------------------- pengeluaran
  Future<void> saveExpense(Expense e) async {
    final saved = await _repo.saveExpense(e);
    expenses = [saved, ...expenses];
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _repo.deleteExpense(id);
    expenses = expenses.where((e) => e.id != id).toList();
    notifyListeners();
  }

  List<Expense> expensesBetween(DateTime from, DateTime to) {
    final start = startOfDay(from);
    final end = startOfDay(to).add(const Duration(days: 1));
    final list = expenses.where((e) => !e.date.isBefore(start) && e.date.isBefore(end)).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // ------------------------------------------------------------ statistik
  /// Transaksi yang dibatalkan tidak dihitung di omzet, laporan, maupun hitungan cucian.
  List<LaundryOrder> ordersCreatedBetween(DateTime from, DateTime to) {
    final start = startOfDay(from);
    final end = startOfDay(to).add(const Duration(days: 1));
    return orders
        .where((o) => !o.cancelled && !o.createdAt.isBefore(start) && o.createdAt.isBefore(end))
        .toList();
  }

  int countStatus(OrderStatus s) => orders.where((o) => !o.cancelled && o.status == s).length;

  List<LaundryOrder> get cancelledOrders => orders.where((o) => o.cancelled).toList();

  List<LaundryOrder> get overdueOrders => orders.where((o) => o.isOverdue()).toList();

  List<LaundryOrder> dueOn(DateTime day) =>
      orders.where((o) => o.isActive && sameDay(o.dueAt, day)).toList();

  List<LaundryOrder> get todayOrders {
    final now = DateTime.now();
    return orders.where((o) => !o.cancelled && sameDay(o.createdAt, now)).toList();
  }
}

int sumTotal(Iterable<LaundryOrder> os) => os.fold<int>(0, (s, o) => s + o.total);
int sumPaid(Iterable<LaundryOrder> os) => os.fold<int>(0, (s, o) => s + o.paid);
int sumExpense(Iterable<Expense> es) => es.fold<int>(0, (s, e) => s + e.amount);

int paidByMethod(Iterable<LaundryOrder> os, PayMethod m) {
  var sum = 0;
  for (final o in os) {
    for (final p in o.payments) {
      if (p.method == m) sum += p.amount;
    }
  }
  return sum;
}
