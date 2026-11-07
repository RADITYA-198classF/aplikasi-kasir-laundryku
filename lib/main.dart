import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/mock_laundry_repository.dart';
import 'providers/app_state.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const LaundryKuApp());
}

class LaundryKuApp extends StatelessWidget {
  const LaundryKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      // Nanti ganti MockLaundryRepository() dengan ApiLaundryRepository() saat backend siap.
      create: (_) => AppState(MockLaundryRepository()),
      child: MaterialApp(
        title: 'Kasir LaundryKu',
        debugShowCheckedModeBanner: false,
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
