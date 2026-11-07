import 'package:flutter/material.dart';

import '../models/models.dart';

/// Palet LaundryKu: biru sebagai warna utama, kuning hanya untuk tombol Transaksi Baru.
class AppColors {
  static const primaryDark = Color(0xFF0E3F94);
  static const primary = Color(0xFF1D5FD1);
  static const primaryLight = Color(0xFF2B7DE9);
  static const ink = Color(0xFF0F2A4A);
  static const soft = Color(0xFFE4EDFB);
  static const background = Color(0xFFF2F5FA);
  static const field = Color(0xFFF2F4F8);
  static const border = Color(0xFFD5DEEA);
  static const muted = Color(0xFF6B7C93);
  static const success = Color(0xFF1E8E5A);
  static const warning = Color(0xFFE8890C);
  static const danger = Color(0xFFC62828);
  static const amber = Color(0xFFF5B731);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryLight],
  );
}

Color statusColor(OrderStatus s) {
  const colors = [
    Color(0xFF6B7C93), // antrian
    Color(0xFF1D5FD1), // diproses
    Color(0xFF1E8E5A), // selesai
    Color(0xFF3D4F66), // diambil
  ];
  return colors[s.index];
}

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(primary: AppColors.primaryDark);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
  );
}

InputDecoration inputDeco(
  String label, {
  IconData? icon,
  String? hint,
  String? prefixText,
  String? suffixText,
  bool plain = false,
}) {
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixText: prefixText,
    suffixText: suffixText,
    prefixIcon: icon == null ? null : Icon(icon, color: AppColors.ink),
    filled: true,
    fillColor: plain ? Colors.white : AppColors.field,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(AppColors.border),
    enabledBorder: border(AppColors.border),
    focusedBorder: border(AppColors.primary, 1.8),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.8),
  );
}
