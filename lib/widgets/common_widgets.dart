import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../models/models.dart';

PreferredSizeWidget lkAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: AppColors.primaryDark,
    foregroundColor: Colors.white,
    flexibleSpace: const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.gradientH)),
    elevation: 0,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    centerTitle: false,
    title: Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500)),
    actions: [
      ...?actions,
      const Padding(padding: EdgeInsets.only(right: 14), child: Center(child: BrandPill())),
    ],
  );
}

/// Logo teks "Kasir LaundryKu" dalam pil putih.
class BrandPill extends StatelessWidget {
  const BrandPill({super.key, this.large = false});
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 20 : 12, vertical: large ? 10 : 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
      child: Text.rich(
        TextSpan(children: [
          const TextSpan(text: 'Kasir ', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)),
          TextSpan(
            text: 'LaundryKu',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w800,
              foreground: Paint()
                ..shader = AppColors.gradientH.createShader(Rect.fromLTWH(0, 0, large ? 175 : 100, 24)),
            ),
          ),
        ]),
        style: TextStyle(fontSize: large ? 22 : 13),
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color = Colors.white,
    this.radius = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [BoxShadow(color: Color(0x140B2545), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  const IconCircle(this.icon, {super.key, this.size = 34, this.color = AppColors.primaryDark, this.bg = AppColors.soft});
  final IconData icon;
  final double size;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: bg == AppColors.soft
          ? const BoxDecoration(gradient: AppColors.softGradient, shape: BoxShape.circle)
          : BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.55, color: color),
    );
  }
}

/// Kartu putih dengan judul berikon di bagian atas.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.icon, required this.title, required this.child, this.trailing});
  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconCircle(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Panel gradien biru dengan lingkaran dekoratif.
class GradientPanel extends StatelessWidget {
  const GradientPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.lightStatusBar = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;

  /// true jika panel ini berada di paling atas layar (ikon status bar dibuat putih).
  final bool lightStatusBar;

  Widget _circle(double d, int alpha) => Container(
        width: d,
        height: d,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withAlpha(alpha)),
      );

  @override
  Widget build(BuildContext context) {
    final panel = ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.gradient),
        child: Stack(
          children: [
            const Positioned(right: -70, top: -70, child: AuroraGlow(size: 240, color: Color(0xFFFFFFFF), opacity: 0.3)),
            const Positioned(left: -80, bottom: -100, child: AuroraGlow(size: 260, color: Color(0xFF7FDBFF), opacity: 0.4)),
            Positioned(right: -40, top: -40, child: _circle(160, 18)),
            Positioned(left: -30, bottom: -60, child: _circle(130, 12)),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
    if (!lightStatusBar) return panel;
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light, child: panel);
  }
}

/// Tombol melayang dengan latar gradien (menggantikan FloatingActionButton polos).
class LkFab extends StatelessWidget {
  const LkFab({
    super.key,
    required this.onPressed,
    required this.child,
    this.tooltip,
    this.gradient = AppColors.gradient,
    this.foregroundColor = Colors.white,
    this.shadowColor = const Color(0x660B4FB3),
    this.shape = const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
  });

  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;
  final Gradient gradient;
  final Color foregroundColor;
  final Color shadowColor;
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: shape,
        gradient: gradient,
        shadows: [BoxShadow(color: shadowColor, blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: Colors.transparent,
        foregroundColor: foregroundColor,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: shape,
        child: child,
      ),
    );
  }
}

/// CircleAvatar dengan latar gradien (soft = pastel untuk avatar kecil di daftar).
class GradientAvatar extends StatelessWidget {
  const GradientAvatar({super.key, required this.child, this.radius, this.soft = false});
  final Widget child;
  final double? radius;
  final bool soft;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: soft ? AppColors.softGradient : AppColors.gradient,
      ),
      child: CircleAvatar(radius: radius, backgroundColor: Colors.transparent, child: child),
    );
  }
}

/// Cahaya lembut berbentuk lingkaran radial, seperti busa/gelembung (hiasan latar panel dan splash).
class AuroraGlow extends StatelessWidget {
  const AuroraGlow({super.key, required this.size, required this.color, this.opacity = 0.5});
  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Chip pilihan: saat terpilih berlatar gradien dengan cahaya, saat tidak terpilih putih berbingkai.
class LkChoiceChip extends StatelessWidget {
  const LkChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
    this.labelStyle,
  });

  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? avatar;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: selected ? AppColors.gradientH : null,
        color: selected ? null : Colors.white,
        borderRadius: radius,
        border: selected ? null : Border.all(color: AppColors.border),
        boxShadow: selected
            ? const [BoxShadow(color: Color(0x661E88E5), blurRadius: 10, offset: Offset(0, 4))]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: () => onSelected(!selected),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 34),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (avatar != null) ...[avatar!, const SizedBox(width: 6)],
                  DefaultTextStyle.merge(style: labelStyle, child: label),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, required this.color, this.icon, this.solid = false, this.onDark = false});
  final String text;
  final Color color;
  final IconData? icon;
  final bool solid;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final bg = onDark ? Colors.white.withAlpha(45) : (solid ? color : color.withAlpha(30));
    final fg = onDark ? Colors.white : (solid ? Colors.white : color);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.onDark = false, this.cancelled = false});
  final OrderStatus status;
  final bool onDark;
  final bool cancelled;

  @override
  Widget build(BuildContext context) => cancelled
      ? Pill('Dibatalkan', color: AppColors.danger, icon: Icons.cancel_outlined, onDark: onDark)
      : Pill(status.label, color: statusColor(status), icon: status.icon, onDark: onDark);
}

class PayPill extends StatelessWidget {
  const PayPill({super.key, required this.paid, this.onDark = false});
  final bool paid;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Pill(
        paid ? 'Lunas' : 'Belum lunas',
        color: paid ? AppColors.success : AppColors.warning,
        icon: paid ? Icons.check_circle_outline : Icons.schedule,
        onDark: onDark,
      );
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.primaryDark,
    this.iconBg = AppColors.soft,
    this.extra,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final Color iconBg;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCircle(icon, size: 36, color: iconColor, bg: iconBg),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink)),
          if (extra != null) ...[const SizedBox(height: 8), extra!],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message});
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconCircle(icon, size: 68),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

/// Kotak abu-abu kecil untuk keadaan kosong di dalam kartu.
class EmptyBox extends StatelessWidget {
  const EmptyBox({super.key, required this.icon, required this.title, this.message});
  final IconData icon;
  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
      decoration: BoxDecoration(color: AppColors.field, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(icon, color: AppColors.muted, size: 28),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(message!, textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(this.label, this.value, {super.key, this.bold = false, this.valueColor = AppColors.ink});
  final String label;
  final String value;
  final bool bold;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: bold ? AppColors.ink : AppColors.muted, fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value, textAlign: TextAlign.right,
                style: TextStyle(color: valueColor, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 16 : 14)),
          ),
        ],
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  const PageTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10, left: 2),
        child: Text(text, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
      );
}

/// Dialog konfirmasi hapus. Mengembalikan true jika pengguna menekan tombol hapus.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Hapus',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
        FilledButton(
          style: solidFilledStyle(background: AppColors.danger),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok == true;
}
