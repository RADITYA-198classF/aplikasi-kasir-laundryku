import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'laundry_repository.dart';

/// Alamat API, dipilih otomatis sesuai platform sehingga bisa dijalankan di mana saja:
///   - Emulator Android (Android Studio)        -> http://10.0.2.2:8000/api
///   - Chrome / Windows / macOS / Linux / iOS    -> http://localhost:8000/api
/// HP Android asli (satu Wi-Fi dengan laptop) atau server lain: timpa lewat --dart-define, contoh:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
const String _kApiBaseUrlOverride = String.fromEnvironment('API_BASE_URL');

String get kApiBaseUrl {
  if (_kApiBaseUrlOverride.isNotEmpty) return _kApiBaseUrlOverride;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8000/api'; // 10.0.2.2 = laptop, dilihat dari emulator Android
  }
  return 'http://localhost:8000/api';
}

/// Implementasi LaundryRepository yang memanggil backend Laravel (REST API + Sanctum).
class ApiLaundryRepository extends LaundryRepository {
  ApiLaundryRepository({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl: baseUrl ?? kApiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: {'Accept': 'application/json'},
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = _token;
          if (t != null) options.headers['Authorization'] = 'Bearer $t';
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  String? _token;

  // ------------------------------------------------------------------ helper
  /// Pesan error dari server (validasi 422 / message), atau [fallback].
  String _errorMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return '${first.first}';
      }
      final m = data['message'];
      if (m is String && m.isNotEmpty) return m;
    }
    return fallback;
  }

  /// Error dari server -> StateError(pesan). Error jaringan (tanpa respons) dilempar apa adanya
  /// supaya AppState menampilkan "Tidak dapat terhubung ke server".
  Future<T> _guard<T>(
    Future<T> Function() run, {
    String fallback = 'Permintaan gagal. Coba lagi.',
  }) async {
    try {
      return await run();
    } on DioException catch (e) {
      if (e.response != null) throw StateError(_errorMessage(e, fallback));
      rethrow;
    }
  }

  DateTime _dt(dynamic v) => DateTime.parse('$v').toLocal();
  int _int(dynamic v) => (v as num).toInt();
  String _s(dynamic v) => v == null ? '' : '$v';

  String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<dynamic> _list(Response<dynamic> r) => r.data as List<dynamic>;
  Map<String, dynamic> _map(Response<dynamic> r) =>
      Map<String, dynamic>.from(r.data as Map);

  Set<AppPermission> _perms(dynamic raw) {
    final names = (raw as List? ?? const []).map((e) => '$e').toSet();
    return AppPermission.values.where((p) => names.contains(p.name)).toSet();
  }

  List<String> _permNames(Set<AppPermission> p) =>
      p.map((e) => e.name).toList();

  QtyUnit _unit(dynamic v) =>
      QtyUnit.values.firstWhere((e) => e.name == v, orElse: () => QtyUnit.kg);
  DurationUnit _durUnit(dynamic v) => DurationUnit.values.firstWhere(
    (e) => e.name == v,
    orElse: () => DurationUnit.hari,
  );
  PayMethod _method(dynamic v) => PayMethod.values.firstWhere(
    (e) => e.name == v,
    orElse: () => PayMethod.tunai,
  );
  OrderStatus _status(dynamic v) => OrderStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => OrderStatus.antrian,
  );

  // ------------------------------------------------------------------ mapper
  AuthSession _session(Map<String, dynamic> j) => AuthSession(
    name: _s(j['name']),
    employeeId: j['employee_id'] == null ? null : '${j['employee_id']}',
    permissions: _perms(j['permissions']),
  );

  Employee _employee(Map<String, dynamic> j) => Employee(
    id: '${j['id']}',
    name: _s(j['name']),
    email: _s(j['email']),
    phone: _s(j['phone']),
    permissions: _perms(j['permissions']),
  );

  BusinessProfile _profile(Map<String, dynamic> j) => BusinessProfile(
    businessName: _s(j['business_name']),
    ownerName: _s(j['owner_name']),
    email: _s(j['email']),
    phone: _s(j['phone']),
    hours: _s(j['hours']),
    ownerWa: _s(j['owner_wa']),
  );

  ServiceCategory _category(Map<String, dynamic> j) => ServiceCategory(
    id: '${j['id']}',
    name: _s(j['name']),
    flow: _s(j['flow']),
  );

  LaundryService _service(Map<String, dynamic> j) => LaundryService(
    id: '${j['id']}',
    categoryId: '${j['category_id']}',
    name: _s(j['name']),
    unit: _unit(j['unit']),
    price: _int(j['price']),
    minQty: (j['min_qty'] as num).toDouble(),
    durationValue: _int(j['duration_value']),
    durationUnit: _durUnit(j['duration_unit']),
    active: j['active'] == true,
  );

  Customer _customer(Map<String, dynamic> j) =>
      Customer(id: '${j['id']}', name: _s(j['name']), phone: _s(j['phone']));

  OrderItem _item(Map<String, dynamic> j) => OrderItem(
    serviceId: _s(j['service_id']),
    name: _s(j['name']),
    unit: _unit(j['unit']),
    price: _int(j['price']),
    qty: (j['qty'] as num).toDouble(),
    durationHours: _int(j['duration_hours']),
  );

  LaundryOrder _order(Map<String, dynamic> j) => LaundryOrder(
    id: '${j['id']}',
    invoice: _s(j['invoice']),
    customerId: _s(j['customer_id']),
    customerName: _s(j['customer_name']),
    customerPhone: _s(j['customer_phone']),
    items: [
      for (final i in (j['items'] as List))
        _item(Map<String, dynamic>.from(i as Map)),
    ],
    status: _status(j['status']),
    createdAt: _dt(j['created_at']),
    dueAt: _dt(j['due_at']),
    note: _s(j['note']),
    cancelled: j['cancelled'] == true,
    payments: [
      for (final p in (j['payments'] as List))
        Payment(
          date: _dt((p as Map)['date']),
          method: _method(p['method']),
          amount: _int(p['amount']),
        ),
    ],
    logs: [
      for (final l in (j['logs'] as List))
        StatusLog(status: _status((l as Map)['status']), time: _dt(l['time'])),
    ],
  );

  Expense _expense(Map<String, dynamic> j) => Expense(
    id: '${j['id']}',
    date: DateTime.parse('${j['date']}'),
    category: _s(j['category']),
    amount: _int(j['amount']),
    note: _s(j['note']),
  );

  // -------------------------------------------------------------------- auth
  @override
  Future<AuthSession?> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email.trim(), 'password': password},
      );
      final body = _map(res);
      _token = body['token'] as String;
      return _session(Map<String, dynamic>.from(body['session'] as Map));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 422) return null; // email/password salah
      rethrow;
    }
  }

  @override
  Future<void> register({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  }) => _guard(
    () => _dio.post(
      '/auth/register',
      data: {
        'business_name': businessName,
        'owner_name': ownerName,
        'email': email.trim(),
        'phone': phone,
        'password': password,
      },
    ),
    fallback: 'Pendaftaran gagal. Coba lagi.',
  );

  @override
  Future<bool> changePassword({
    String? employeeId,
    required String oldPassword,
    required String newPassword,
  }) async {
    // Server mengganti password akun pemilik token, jadi employeeId tidak perlu dikirim.
    try {
      await _dio.put(
        '/auth/password',
        data: {'old_password': oldPassword, 'new_password': newPassword},
      );
      return true;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 422 &&
          data is Map &&
          data['code'] == 'wrong_password')
        return false;
      rethrow;
    }
  }

  /// Mencabut token di server lalu melupakannya. Panggil dari tombol Keluar (opsional).
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } on DioException catch (_) {
      // Tetap keluar secara lokal walau server tidak terjangkau.
    } finally {
      _token = null;
    }
  }

  // ---------------------------------------------------------------- karyawan
  @override
  Future<List<Employee>> fetchEmployees() => _guard(() async {
    final res = await _dio.get('/employees');
    return [
      for (final e in _list(res))
        _employee(Map<String, dynamic>.from(e as Map)),
    ];
  });

  @override
  Future<Employee> createEmployee({
    required String name,
    required String phone,
    required String email,
    required String password,
    required Set<AppPermission> permissions,
  }) => _guard(() async {
    final res = await _dio.post(
      '/employees',
      data: {
        'name': name,
        'phone': phone,
        'email': email.trim(),
        'password': password,
        'permissions': _permNames(permissions),
      },
    );
    return _employee(_map(res));
  }, fallback: 'Akun karyawan gagal dibuat. Coba lagi.');

  @override
  Future<Employee> updateEmployee(Employee employee) => _guard(() async {
    final res = await _dio.put(
      '/employees/${employee.id}',
      data: {
        'name': employee.name,
        'phone': employee.phone,
        'email': employee.email,
        'permissions': _permNames(employee.permissions),
      },
    );
    return _employee(_map(res));
  });

  @override
  Future<void> deleteEmployee(String employeeId) =>
      _guard(() => _dio.delete('/employees/$employeeId'));

  @override
  Future<void> resetEmployeePassword(String employeeId, String newPassword) =>
      _guard(
        () => _dio.put(
          '/employees/$employeeId/password',
          data: {'new_password': newPassword},
        ),
      );

  // ------------------------------------------------------------- profil usaha
  @override
  Future<BusinessProfile> fetchProfile() =>
      _guard(() async => _profile(_map(await _dio.get('/business'))));

  @override
  Future<BusinessProfile> saveProfile(BusinessProfile p) => _guard(() async {
    final res = await _dio.put(
      '/business',
      data: {
        'business_name': p.businessName,
        'owner_name': p.ownerName,
        'phone': p.phone,
        'hours': p.hours,
        'owner_wa': p.ownerWa,
      },
    );
    return _profile(_map(res));
  });

  // ----------------------------------------------------------------- layanan
  @override
  Future<List<ServiceCategory>> fetchCategories() => _guard(() async {
    final res = await _dio.get('/categories');
    return [
      for (final c in _list(res))
        _category(Map<String, dynamic>.from(c as Map)),
    ];
  });

  @override
  Future<ServiceCategory> saveCategory(ServiceCategory c) => _guard(() async {
    final body = {'name': c.name, 'flow': c.flow};
    final res = c.id.isEmpty
        ? await _dio.post('/categories', data: body)
        : await _dio.put('/categories/${c.id}', data: body);
    return _category(_map(res));
  });

  @override
  Future<List<LaundryService>> fetchServices() => _guard(() async {
    final res = await _dio.get('/services');
    return [
      for (final s in _list(res)) _service(Map<String, dynamic>.from(s as Map)),
    ];
  });

  @override
  Future<LaundryService> saveService(LaundryService s) => _guard(() async {
    final body = {
      'category_id': int.parse(s.categoryId),
      'name': s.name,
      'unit': s.unit.name,
      'price': s.price,
      'min_qty': s.minQty,
      'duration_value': s.durationValue,
      'duration_unit': s.durationUnit.name,
      'active': s.active,
    };
    final res = s.id.isEmpty
        ? await _dio.post('/services', data: body)
        : await _dio.put('/services/${s.id}', data: body);
    return _service(_map(res));
  });

  @override
  Future<void> deleteService(String id) =>
      _guard(() => _dio.delete('/services/$id'));

  // --------------------------------------------------------------- pelanggan
  @override
  Future<List<Customer>> fetchCustomers() => _guard(() async {
    final res = await _dio.get('/customers');
    return [
      for (final c in _list(res))
        _customer(Map<String, dynamic>.from(c as Map)),
    ];
  });

  @override
  Future<Customer> saveCustomer(Customer c) => _guard(() async {
    final body = {'name': c.name, 'phone': c.phone};
    final res = c.id.isEmpty
        ? await _dio.post('/customers', data: body)
        : await _dio.put('/customers/${c.id}', data: body);
    return _customer(_map(res));
  });

  @override
  Future<void> deleteCustomer(String id) =>
      _guard(() => _dio.delete('/customers/$id'));

  // --------------------------------------------------------------- transaksi
  @override
  Future<List<LaundryOrder>> fetchOrders() => _guard(() async {
    final res = await _dio.get('/orders');
    return [
      for (final o in _list(res)) _order(Map<String, dynamic>.from(o as Map)),
    ];
  });

  @override
  Future<LaundryOrder> createOrder({
    required Customer customer,
    required List<OrderItem> items,
    String note = '',
    Payment? firstPayment,
  }) => _guard(() async {
    // Harga/durasi dihitung ulang di server dari katalog; klien hanya mengirim id layanan + jumlah.
    final res = await _dio.post(
      '/orders',
      data: {
        'customer_id': int.parse(customer.id),
        'items': [
          for (final i in items)
            {'service_id': int.parse(i.serviceId), 'qty': i.qty},
        ],
        if (note.trim().isNotEmpty) 'note': note.trim(),
        if (firstPayment != null)
          'first_payment': {
            'method': firstPayment.method.name,
            'amount': firstPayment.amount,
          },
      },
    );
    return _order(_map(res));
  });

  @override
  Future<LaundryOrder> updateStatus(String orderId, OrderStatus status) =>
      _guard(
        () async => _order(
          _map(
            await _dio.patch(
              '/orders/$orderId/status',
              data: {'status': status.name},
            ),
          ),
        ),
      );

  @override
  Future<LaundryOrder> cancelOrder(String orderId) => _guard(
    () async => _order(_map(await _dio.post('/orders/$orderId/cancel'))),
  );

  @override
  Future<LaundryOrder> addPayment(
    String orderId,
    PayMethod method,
    int amount,
  ) => _guard(
    () async => _order(
      _map(
        await _dio.post(
          '/orders/$orderId/payments',
          data: {'method': method.name, 'amount': amount},
        ),
      ),
    ),
  );

  // ------------------------------------------------------------- pengeluaran
  @override
  Future<List<Expense>> fetchExpenses() => _guard(() async {
    final res = await _dio.get('/expenses');
    return [
      for (final e in _list(res)) _expense(Map<String, dynamic>.from(e as Map)),
    ];
  });

  @override
  Future<Expense> saveExpense(Expense e) => _guard(() async {
    final body = {
      'date': _date(e.date),
      'category': e.category,
      'amount': e.amount,
      'note': e.note,
    };
    final res = e.id.isEmpty
        ? await _dio.post('/expenses', data: body)
        : await _dio.put('/expenses/${e.id}', data: body);
    return _expense(_map(res));
  });

  @override
  Future<void> deleteExpense(String id) =>
      _guard(() => _dio.delete('/expenses/$id'));

  @override
  Future<void> logReportDownload({
    required String periodLabel,
    required DateTime from,
    required DateTime to,
    required List<String> sections,
  }) async {
    try {
      await _dio.post(
        '/reports/downloads',
        data: {
          'format': 'pdf',
          'period_label': periodLabel,
          'from': _date(from),
          'to': _date(to),
          'sections': sections,
        },
      );
    } on DioException catch (_) {
      // Gagal mencatat riwayat tidak boleh membatalkan unduhan PDF.
    }
  }

  // ------------------------------------------- endpoint tambahan (opsional dipakai UI)
  /// GET /dashboard: ringkasan beranda yang dihitung server.
  Future<Map<String, dynamic>> fetchDashboard() =>
      _guard(() async => _map(await _dio.get('/dashboard')));

  /// GET /reports/summary: period = today | 7days | month | custom (custom wajib from & to).
  Future<Map<String, dynamic>> fetchReportSummary({
    String period = 'today',
    DateTime? from,
    DateTime? to,
    bool perMonth = false,
  }) => _guard(
    () async => _map(
      await _dio.get(
        '/reports/summary',
        queryParameters: {
          'period': period,
          if (from != null) 'from': _date(from),
          if (to != null) 'to': _date(to),
          'group_by': perMonth ? 'month' : 'day',
        },
      ),
    ),
  );

  /// GET /orders/{id}/whatsapp: {phone, message, url} untuk memberi tahu pelanggan.
  Future<Map<String, dynamic>> fetchWhatsApp(String orderId) =>
      _guard(() async => _map(await _dio.get('/orders/$orderId/whatsapp')));
}
