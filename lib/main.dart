import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/api_laundry_repository.dart';
import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

/// Kunci global: error yang tidak tertangkap di layar mana pun tetap tampil sebagai SnackBar
/// (mis. server mati, atau status transaksi sudah diubah dari perangkat lain).
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

String friendlyError(Object error) {
  if (error is StateError) return error.message; // pesan dari server (422, 403, ...)
  if (error is DioException) {
    return error.response == null
        ? 'Tidak dapat terhubung ke server. Periksa koneksi lalu coba lagi.'
        : 'Permintaan ditolak server. Coba lagi.';
  }
  return 'Terjadi kesalahan. Coba lagi.';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
    messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(friendlyError(error))));
    return true;
  };
  runApp(const LaundryKuApp());
}

class LaundryKuApp extends StatelessWidget {
  const LaundryKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Backend Laravel. Untuk kembali ke data demo lokal: AppState(MockLaundryRepository()).
      create: (_) => AppState(ApiLaundryRepository()),
      child: MaterialApp(
        title: 'Kasir LaundryKu',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: messengerKey,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AppState, bool>((s) => s.loggedIn);
    return loggedIn ? const HomeShell() : const LoginScreen();
  }
}
