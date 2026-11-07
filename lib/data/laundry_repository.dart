import '../models/models.dart';

/// Kontrak data aplikasi. Saat ini dipenuhi oleh MockLaundryRepository (data lokal).
/// Saat backend REST API sudah jadi, buat ApiLaundryRepository yang `extends` kelas ini,
/// lalu ganti satu baris di main.dart. Komentar di tiap method menunjukkan endpoint-nya.
abstract class LaundryRepository {
  /// POST /auth/login  -> sesi owner atau karyawan, null jika email/password salah
  Future<AuthSession?> login(String email, String password);

  /// POST /auth/register  (melempar StateError jika email sudah terdaftar)
  Future<void> register({
    required String businessName,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  });

  /// PUT /auth/password  -> false jika password lama salah (employeeId null = owner)
  Future<bool> changePassword({String? employeeId, required String oldPassword, required String newPassword});

  /// GET /employees
  Future<List<Employee>> fetchEmployees();

  /// POST /employees  (melempar StateError jika email sudah terdaftar)
  Future<Employee> createEmployee({
    required String name,
    required String phone,
    required String email,
    required String password,
    required Set<AppPermission> permissions,
  });

  /// PUT /employees/{id}
  Future<Employee> updateEmployee(Employee employee);

  /// DELETE /employees/{id}
  Future<void> deleteEmployee(String employeeId);

  /// PUT /employees/{id}/password  (owner mengganti tanpa password lama)
  Future<void> resetEmployeePassword(String employeeId, String newPassword);

  /// GET /business
  Future<BusinessProfile> fetchProfile();

  /// PUT /business
  Future<BusinessProfile> saveProfile(BusinessProfile profile);

  /// GET /categories
  Future<List<ServiceCategory>> fetchCategories();

  /// POST /categories
  Future<ServiceCategory> saveCategory(ServiceCategory category);

  /// GET /services
  Future<List<LaundryService>> fetchServices();

  /// POST /services (id kosong) atau PUT /services/{id}
  Future<LaundryService> saveService(LaundryService service);

  /// DELETE /services/{id}
  Future<void> deleteService(String id);

  /// GET /customers
  Future<List<Customer>> fetchCustomers();

  /// POST /customers (id kosong) atau PUT /customers/{id}
  Future<Customer> saveCustomer(Customer customer);

  /// DELETE /customers/{id}  (riwayat transaksi pelanggan tetap tersimpan)
  Future<void> deleteCustomer(String id);

  /// GET /orders
  Future<List<LaundryOrder>> fetchOrders();

  /// POST /orders
  Future<LaundryOrder> createOrder({
    required Customer customer,
    required List<OrderItem> items,
    String note = '',
    Payment? firstPayment,
  });

  /// PATCH /orders/{id}/status
  Future<LaundryOrder> updateStatus(String orderId, OrderStatus status);

  /// POST /orders/{id}/cancel
  Future<LaundryOrder> cancelOrder(String orderId);

  /// POST /orders/{id}/payments
  Future<LaundryOrder> addPayment(String orderId, PayMethod method, int amount);

  /// GET /expenses
  Future<List<Expense>> fetchExpenses();

  /// POST /expenses
  Future<Expense> saveExpense(Expense expense);

  /// DELETE /expenses/{id}
  Future<void> deleteExpense(String id);
}
