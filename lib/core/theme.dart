import 'package:flutter/material.dart';

import '../models/models.dart';

/// Palet LaundryKu "Fresh Laundry": biru laut → biru langit → putih, seperti air bersih dan busa sabun.
class AppColors {
  static const primaryDark = Color(0xFF0B4FB3);
  static const primary = Color(0xFF1E88E5);
  static const primaryLight = Color(0xFF4FC3F7);
  static const ink = Color(0xFF0B2545);
  static const soft = Color(0xFFE3F2FD);
  static const background = Color(0xFFF2F8FF);
  static const field = Color(0xFFEDF5FD);
  static const border = Color(0xFFD0E4F7);
  static const muted = Color(0xFF4F6B89);
  static const success = Color(0xFF0FA36B);
  static const warning = Color(0xFFF28A0F);
  static const danger = Color(0xFFE0264A);
  static const amber = Color(0xFFFFDD57);

  static const _navy = Color(0xFF0A3D91);
  static const _ocean = Color(0xFF1255B5);
  static const _azure = Color(0xFF1976D2);
  static const _sky = Color(0xFF2488E2);

  /// Gradien utama (panel, header, avatar): biru tua → biru langit. Tetap cukup gelap agar teks putih terbaca.
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [_navy, _ocean, _azure, _sky],
    stops: [0, 0.4, 0.78, 1],
  );

  /// Versi mendatar untuk AppBar, bilah bawah, tombol, dan chip.
  static const gradientH = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [_navy, _ocean, _azure, _sky],
    stops: [0, 0.4, 0.78, 1],
  );

  /// Gradien splash: biru tua di atas memudar menjadi putih di bawah.
  static const splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A3D91), Color(0xFF1976D2), Color(0xFF5BB4F5), Color(0xFFBFE3FB), Color(0xFFFFFFFF)],
    stops: [0, 0.3, 0.5, 0.74, 1],
  );

  /// Gradien pastel untuk latar ikon dan avatar: biru muda → putih.
  static const softGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD6EBFF), Color(0xFFFFFFFF)],
  );

  /// Gradien segar (putih → biru langit) khusus tombol Transaksi Baru, kontras dengan bilah biru tua.
  static const freshGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8F9FF), Color(0xFF38BDF8)],
  );
}

Color statusColor(OrderStatus s) {
  const colors = [
    Color(0xFF6A8099), // antrian
    Color(0xFF1976D2), // diproses
    Color(0xFF0FA36B), // selesai
    Color(0xFF27457A), // diambil
  ];
  return colors[s.index];
}

/// Latar tombol terisi: gradien biasa, lebih terang saat ditekan, abu lembut saat nonaktif.
Widget _gradientButtonBackground(BuildContext context, Set<WidgetState> states, Widget? child) {
  if (states.contains(WidgetState.disabled)) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(100)),
      child: child,
    );
  }
  final pressed = states.contains(WidgetState.pressed);
  final gradient = pressed
      ? LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            for (final c in AppColors.gradientH.colors) Color.lerp(c, Colors.white, 0.18)!,
          ],
          stops: AppColors.gradientH.stops,
        )
      : AppColors.gradientH;
  return ClipRRect(
    borderRadius: BorderRadius.circular(100),
    child: DecoratedBox(decoration: BoxDecoration(gradient: gradient), child: child),
  );
}

Widget _plainButtonBackground(BuildContext context, Set<WidgetState> states, Widget? child) =>
    child ?? const SizedBox.shrink();

double _glowElevation(Set<WidgetState> states) {
  if (states.contains(WidgetState.disabled)) return 0;
  return states.contains(WidgetState.pressed) ? 1 : 5;
}

/// Tombol terisi warna solid (tanpa gradien): aksi berbahaya dan tombol di atas panel gradien.
ButtonStyle solidFilledStyle({required Color background, Color? foreground}) =>
    FilledButton.styleFrom(backgroundColor: background, foregroundColor: foreground)
        .copyWith(backgroundBuilder: _plainButtonBackground, elevation: const WidgetStatePropertyAll(0));

/// Untuk FilledButton.tonal agar tetap memakai warna tonal bawaan, bukan gradien.
final ButtonStyle tonalSolidStyle =
    ButtonStyle(backgroundBuilder: _plainButtonBackground, elevation: const WidgetStatePropertyAll(0));

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primaryDark,
    secondaryContainer: AppColors.soft,
    onSecondaryContainer: AppColors.primaryDark,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundBuilder: _gradientButtonBackground,
        elevation: WidgetStateProperty.resolveWith(_glowElevation),
        shadowColor: const WidgetStatePropertyAll(Color(0xAA1E88E5)),
      ),
    ),
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
