import '../core/format.dart';
import '../models/models.dart';
import 'laundry_repository.dart';

class _SeedLine {
  const _SeedLine(this.serviceId, this.qty);
  final String serviceId;
  final double qty;
}

class _SeedOrder {
  const _SeedOrder(this.daysAgo, this.hour, this.customer, this.lines, this.status,
      this.paidShare, this.method);
  final int daysAgo;
  final int hour;
  final int customer;
  final List<_SeedLine> lines;
  final OrderStatus status;
  final double paidShare;
  final PayMethod method;
}

/// Repository demo: semua data disimpan di memori dan kembali ke awal saat aplikasi ditutup.
class MockLaundryRepository extends LaundryRepository {
  MockLaundryRepository() {
    _seedDemo();
  }

  String _email = 'admin@laundryku.com';
  String _password = 'admin123';
  BusinessProfile _profile = const BusinessProfile(
    businessName: 'LaundryKu Surabaya',
    ownerName: 'Admin',
    email: 'admin@laundryku.com',
    phone: '081234567890',
    hours: '08.00 - 20.00',
  );

  final List<ServiceCategory> _categories = [];
  final List<LaundryService> _services = [];
  final List<Customer> _customers = [];
  final List<LaundryOrder> _orders = [];
  final List<Expense> _expenses = [];
  final List<Employee> _employees = [];
  final Map<String, String> _employeePass = {};
  int _idCounter = 100;

  String _nextId(String prefix) => '$prefix-${_idCounter++}';
  Future<void> _wait([int ms = 220]) => Future<void>.delayed(Duration(milliseconds: ms));

  int _orderIndex(String id) {
    final i = _orders.indexWhere((o) => o.id == id);
    if (i < 0) throw StateError('Transaksi tidak ditemukan');
    return i;
  }

  String _makeInvoice(DateTime d) {
    final n = _orders.where((o) => sameDay(o.createdAt, d)).length + 1;
    return 'INV-${invoiceDate(d)}-${n.toString().padLeft(4, '0')}';
  }

  // ---------------------------------------------------------------- auth
  @override
  Future<AuthSession?> login(String email, String password) async {
    await _wait(500);
    final e = email.trim().toLowerCase();
    if (e == _email && password == _password) {
      return AuthSession(name: _profile.ownerName);
    }
    for (final emp in _employees) {
      if (emp.email == e && _employeePass[emp.id] == password) {
        return AuthSession(name: emp.name, employeeId: emp.id, permissions: emp.permissions);
      }
    }
    return null;
  }

  @override
  Future<void> register({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _wait(600);
    if (_emailTaken(email)) {
      throw StateError('Email sudah terdaftar. Silakan masuk.');
    }
    // Usaha baru: data kosong, katalog layanan memakai bawaan.
    _employees.clear();
    _employeePass.clear();
    _orders.clear();
    _customers.clear();
    _expenses.clear();
    _seedCatalog();
    _email = email.trim().toLowerCase();
    _password = password;
    _profile = BusinessProfile(
      businessName: businessName,
      ownerName: ownerName,
      email: _email,
      phone: phone,
    );
  }

  bool _emailTaken(String email) {
    final e = email.trim().toLowerCase();
    return e == _email || _employees.any((x) => x.email == e);
  }

  @override
  Future<bool> changePassword({
    String? employeeId,
    required String oldPassword,
    required String newPassword,
  }) async {
    await _wait();
    if (employeeId == null) {
      if (oldPassword != _password) return false;
      _password = newPassword;
      return true;
    }
    if (_employeePass[employeeId] != oldPassword) return false;
    _employeePass[employeeId] = newPassword;
    return true;
  }

  // ------------------------------------------------------- karyawan
  @override
  Future<List<Employee>> fetchEmployees() async {
    await _wait(120);
    return List<Employee>.of(_employees);
  }

  @override
  Future<Employee> createEmployee({
    required String name,
    required String phone,
    required String email,
    required String password,
    required Set<AppPermission> permissions,
  }) async {
    await _wait(400);
    if (_emailTaken(email)) throw StateError('Email sudah dipakai akun lain.');
    final emp = Employee(
      id: _nextId('emp'),
      name: name,
      email: email.trim().toLowerCase(),
      phone: phone,
      permissions: Set<AppPermission>.of(permissions),
    );
    _employees.add(emp);
    _employeePass[emp.id] = password;
    return emp;
  }

  @override
  Future<Employee> updateEmployee(Employee employee) async {
    await _wait(200);
    final i = _employees.indexWhere((x) => x.id == employee.id);
    if (i >= 0) _employees[i] = employee;
    return employee;
  }

  @override
  Future<void> deleteEmployee(String employeeId) async {
    await _wait(250);
    _employees.removeWhere((e) => e.id == employeeId);
    _employeePass.remove(employeeId);
  }

  @override
  Future<void> resetEmployeePassword(String employeeId, String newPassword) async {
    await _wait(250);
    _employeePass[employeeId] = newPassword;
  }

  @override
  Future<BusinessProfile> fetchProfile() async {
    await _wait(120);
    return _profile;
  }

  @override
  Future<BusinessProfile> saveProfile(BusinessProfile profile) async {
    await _wait();
    _profile = profile;
    return _profile;
  }

  // ---------------------------------------------------------- layanan
  @override
  Future<List<ServiceCategory>> fetchCategories() async {
    await _wait(120);
    return List<ServiceCategory>.of(_categories);
  }

  @override
  Future<ServiceCategory> saveCategory(ServiceCategory category) async {
    await _wait(150);
    final created = ServiceCategory(id: _nextId('cat'), name: category.name, flow: category.flow);
    _categories.add(created);
    return created;
  }

  @override
  Future<List<LaundryService>> fetchServices() async {
    await _wait(120);
    return List<LaundryService>.of(_services);
  }

  @override
  Future<LaundryService> saveService(LaundryService s) async {
    await _wait(150);
    if (s.id.isEmpty) {
      final created = LaundryService(
        id: _nextId('svc'),
        categoryId: s.categoryId,
        name: s.name,
        unit: s.unit,
        price: s.price,
        minQty: s.minQty,
        durationValue: s.durationValue,
        durationUnit: s.durationUnit,
        active: s.active,
      );
      _services.add(created);
      return created;
    }
    final i = _services.indexWhere((x) => x.id == s.id);
    if (i >= 0) _services[i] = s;
    return s;
  }

  @override
  Future<void> deleteService(String id) async {
    await _wait(150);
    _services.removeWhere((s) => s.id == id);
  }

  // ------------------------------------------------------- pelanggan
  @override
  Future<List<Customer>> fetchCustomers() async {
    await _wait(120);
    return List<Customer>.of(_customers);
  }

  @override
  Future<Customer> saveCustomer(Customer c) async {
    await _wait(150);
    if (c.id.isEmpty) {
      final created = Customer(id: _nextId('cus'), name: c.name, phone: c.phone);
      _customers.add(created);
      return created;
    }
    final i = _customers.indexWhere((x) => x.id == c.id);
    if (i >= 0) _customers[i] = c;
    return c;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await _wait(200);
    _customers.removeWhere((c) => c.id == id);
  }

  // ------------------------------------------------------- transaksi
  @override
  Future<List<LaundryOrder>> fetchOrders() async {
    await _wait(150);
    return List<LaundryOrder>.of(_orders);
  }

  @override
  Future<LaundryOrder> createOrder({
    required Customer customer,
    required List<OrderItem> items,
    String note = '',
    Payment? firstPayment,
  }) async {
    await _wait(400);
    final now = DateTime.now();
    final order = LaundryOrder(
      id: _nextId('ord'),
      invoice: _makeInvoice(now),
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      items: List<OrderItem>.of(items),
      status: OrderStatus.antrian,
      createdAt: now,
      dueAt: estimateDue(now, items),
      note: note,
      payments: firstPayment == null ? [] : [firstPayment],
      logs: [StatusLog(status: OrderStatus.antrian, time: now)],
    );
    _orders.add(order);
    return order;
  }

  @override
  Future<LaundryOrder> updateStatus(String orderId, OrderStatus status) async {
    await _wait(200);
    final i = _orderIndex(orderId);
    final old = _orders[i];
    final updated = old.copyWith(
      status: status,
      logs: [...old.logs, StatusLog(status: status, time: DateTime.now())],
    );
    _orders[i] = updated;
    return updated;
  }

  @override
  Future<LaundryOrder> addPayment(String orderId, PayMethod method, int amount) async {
    await _wait(200);
    final i = _orderIndex(orderId);
    final old = _orders[i];
    final updated = old.copyWith(
      payments: [...old.payments, Payment(date: DateTime.now(), method: method, amount: amount)],
    );
    _orders[i] = updated;
    return updated;
  }

  @override
  Future<LaundryOrder> cancelOrder(String orderId) async {
    await _wait(250);
    final i = _orderIndex(orderId);
    final updated = _orders[i].copyWith(cancelled: true);
    _orders[i] = updated;
    return updated;
  }

  // ----------------------------------------------------- pengeluaran
  @override
  Future<List<Expense>> fetchExpenses() async {
    await _wait(120);
    return List<Expense>.of(_expenses);
  }

  @override
  Future<Expense> saveExpense(Expense e) async {
    await _wait(150);
    final created = Expense(
      id: _nextId('exp'),
      date: e.date,
      category: e.category,
      amount: e.amount,
      note: e.note,
    );
    _expenses.add(created);
    return created;
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _wait(150);
    _expenses.removeWhere((e) => e.id == id);
  }

  // ---------------------------------------------------------------- seed
  void _seedCatalog() {
    _categories
      ..clear()
      ..addAll(const [
        ServiceCategory(id: 'cat-1', name: 'Cuci Kiloan', flow: 'Cuci -> Pengeringan -> Setrika'),
        ServiceCategory(id: 'cat-2', name: 'Bed Cover', flow: 'Cuci -> Pengeringan'),
        ServiceCategory(id: 'cat-3', name: 'Boneka', flow: 'Cuci -> Pengeringan'),
        ServiceCategory(id: 'cat-4', name: 'Sepatu', flow: 'Cuci -> Pengeringan'),
        ServiceCategory(id: 'cat-5', name: 'Tas', flow: 'Cuci -> Pengeringan -> Setrika'),
        ServiceCategory(id: 'cat-6', name: 'Karpet', flow: 'Cuci -> Pengeringan'),
      ]);
    LaundryService s(String id, String cat, String name, QtyUnit unit, int price, double min,
            int dur, DurationUnit du) =>
        LaundryService(
          id: id,
          categoryId: cat,
          name: name,
          unit: unit,
          price: price,
          minQty: min,
          durationValue: dur,
          durationUnit: du,
        );
    _services
      ..clear()
      ..addAll([
        s('svc-1', 'cat-1', 'Express 1 Hari', QtyUnit.kg, 15000, 0, 1, DurationUnit.hari),
        s('svc-2', 'cat-1', 'Express 3 Jam', QtyUnit.kg, 25000, 0, 3, DurationUnit.jam),
        s('svc-3', 'cat-1', 'Express 6 Jam', QtyUnit.kg, 20000, 0, 6, DurationUnit.jam),
        s('svc-4', 'cat-1', 'Reguler 2 Hari', QtyUnit.kg, 10000, 0, 2, DurationUnit.hari),
        s('svc-5', 'cat-1', 'Reguler 3 Hari', QtyUnit.kg, 7000, 0, 3, DurationUnit.hari),
        s('svc-6', 'cat-2', 'King', QtyUnit.pcs, 25000, 1, 3, DurationUnit.hari),
        s('svc-7', 'cat-2', 'Queen', QtyUnit.pcs, 18000, 1, 3, DurationUnit.hari),
        s('svc-8', 'cat-2', 'Single', QtyUnit.pcs, 15000, 1, 3, DurationUnit.hari),
        s('svc-9', 'cat-3', 'Besar', QtyUnit.pcs, 25000, 1, 5, DurationUnit.hari),
        s('svc-10', 'cat-3', 'Kecil', QtyUnit.pcs, 20000, 1, 5, DurationUnit.hari),
        s('svc-11', 'cat-4', 'Deep Clean', QtyUnit.pcs, 35000, 1, 3, DurationUnit.hari),
        s('svc-12', 'cat-4', 'Fast Clean', QtyUnit.pcs, 25000, 1, 3, DurationUnit.hari),
        s('svc-13', 'cat-5', 'Besar', QtyUnit.pcs, 20000, 1, 3, DurationUnit.hari),
        s('svc-14', 'cat-5', 'Kecil', QtyUnit.pcs, 15000, 1, 3, DurationUnit.hari),
        s('svc-15', 'cat-6', 'Standar', QtyUnit.m2, 15000, 1, 7, DurationUnit.hari),
        s('svc-16', 'cat-6', 'Turki', QtyUnit.m2, 25000, 1, 7, DurationUnit.hari),
      ]);
  }

  static const _seedOrders = [
    _SeedOrder(6, 8, 0, [_SeedLine('svc-5', 4)], OrderStatus.diambil, 1, PayMethod.tunai),
    _SeedOrder(6, 10, 3, [_SeedLine('svc-4', 3.5), _SeedLine('svc-12', 1)], OrderStatus.diambil, 1, PayMethod.qris),
    _SeedOrder(5, 9, 1, [_SeedLine('svc-1', 2.5)], OrderStatus.diambil, 1, PayMethod.qris),
    _SeedOrder(5, 14, 2, [_SeedLine('svc-2', 2)], OrderStatus.diambil, 1, PayMethod.tunai),
    _SeedOrder(4, 8, 4, [_SeedLine('svc-7', 1)], OrderStatus.diambil, 1, PayMethod.tunai),
    _SeedOrder(4, 9, 5, [_SeedLine('svc-4', 3)], OrderStatus.diproses, 0, PayMethod.tunai),
    _SeedOrder(3, 10, 0, [_SeedLine('svc-13', 1), _SeedLine('svc-15', 3)], OrderStatus.diambil, 1, PayMethod.tunai),
    _SeedOrder(3, 13, 3, [_SeedLine('svc-4', 4.5)], OrderStatus.selesai, 0, PayMethod.tunai),
    _SeedOrder(2, 8, 1, [_SeedLine('svc-5', 5)], OrderStatus.diproses, 0.5, PayMethod.tunai),
    _SeedOrder(2, 11, 4, [_SeedLine('svc-9', 2)], OrderStatus.diproses, 0, PayMethod.tunai),
    _SeedOrder(5, 15, 2, [_SeedLine('svc-4', 2)], OrderStatus.diproses, 0, PayMethod.tunai),
    _SeedOrder(1, 9, 5, [_SeedLine('svc-1', 2)], OrderStatus.antrian, 1, PayMethod.qris),
    _SeedOrder(1, 12, 0, [_SeedLine('svc-4', 5.5)], OrderStatus.selesai, 1, PayMethod.tunai),
    _SeedOrder(0, 8, 3, [_SeedLine('svc-2', 1.5)], OrderStatus.selesai, 1, PayMethod.qris),
    _SeedOrder(0, 10, 1, [_SeedLine('svc-5', 4)], OrderStatus.antrian, 0.5, PayMethod.tunai),
    _SeedOrder(0, 12, 4, [_SeedLine('svc-11', 2)], OrderStatus.diproses, 0, PayMethod.tunai),
    _SeedOrder(0, 14, 2, [_SeedLine('svc-6', 1), _SeedLine('svc-8', 1)], OrderStatus.antrian, 1, PayMethod.tunai),
  ];

  void _seedDemo() {
    _seedCatalog();
    _customers.addAll(const [
      Customer(id: 'cus-1', name: 'Budi Santoso', phone: '081234567891'),
      Customer(id: 'cus-2', name: 'Siti Rahmawati', phone: '082145678901'),
      Customer(id: 'cus-3', name: 'Andi Pratama', phone: '085233344455'),
      Customer(id: 'cus-4', name: 'Dewi Lestari', phone: '081377788899'),
      Customer(id: 'cus-5', name: 'Rizky Maulana', phone: '087855566677'),
      Customer(id: 'cus-6', name: 'Nadia Putri', phone: '089612345678'),
    ]);

    final now = DateTime.now();
    final today = startOfDay(now);
    final seeded = [..._seedOrders]..sort((a, b) {
        final d = b.daysAgo.compareTo(a.daysAgo);
        return d != 0 ? d : a.hour.compareTo(b.hour);
      });

    for (final s in seeded) {
      final day = today.subtract(Duration(days: s.daysAgo));
      var created = day.add(Duration(hours: s.hour));
      if (created.isAfter(now)) {
        created = day.add(Duration(minutes: (now.difference(day).inMinutes * s.hour / 18).floor()));
      }
      final customer = _customers[s.customer];
      final items = <OrderItem>[];
      for (final line in s.lines) {
        final svc = _services.firstWhere((x) => x.id == line.serviceId);
        items.add(OrderItem(
          serviceId: svc.id,
          name: serviceFullName(
              _categories.firstWhere((c) => c.id == svc.categoryId).name, svc.name),
          unit: svc.unit,
          price: svc.price,
          qty: line.qty,
          durationHours: svc.durationHours,
        ));
      }
      final logs = <StatusLog>[];
      for (var i = 0; i <= s.status.index; i++) {
        var t = created.add(Duration(hours: i * 8));
        if (t.isAfter(now)) t = now;
        logs.add(StatusLog(status: OrderStatus.values[i], time: t));
      }
      final total = items.fold<int>(0, (sum, i) => sum + i.subtotal);
      final paidAmount = (total * s.paidShare).round();
      _orders.add(LaundryOrder(
        id: _nextId('ord'),
        invoice: _makeInvoice(created),
        customerId: customer.id,
        customerName: customer.name,
        customerPhone: customer.phone,
        items: items,
        status: s.status,
        createdAt: created,
        dueAt: estimateDue(created, items),
        payments: paidAmount > 0
            ? [Payment(date: created, method: s.method, amount: paidAmount)]
            : [],
        logs: logs,
      ));
    }

    Expense e(int daysAgo, String cat, int amount, [String note = '']) => Expense(
          id: _nextId('exp'),
          date: today.subtract(Duration(days: daysAgo)),
          category: cat,
          amount: amount,
          note: note,
        );
    _expenses.addAll([
      e(1, 'Deterjen & Pewangi', 85000, 'Deterjen 5 kg'),
      e(2, 'Gas / LPG', 60000),
      e(3, 'Listrik', 250000, 'Token listrik'),
      e(5, 'Internet & Pulsa', 100000),
    ]);

    // Akun karyawan contoh: bisa membuat transaksi dan mencatat pengeluaran.
    const demo = Employee(
      id: 'emp-1',
      name: 'Sari',
      email: 'sari@laundryku.com',
      phone: '081298765432',
      permissions: {AppPermission.transaksi, AppPermission.pengeluaran},
    );
    _employees.add(demo);
    _employeePass[demo.id] = 'sari123';
  }
}
