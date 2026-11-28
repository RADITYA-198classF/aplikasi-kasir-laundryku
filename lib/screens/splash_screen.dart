import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../widgets/common_widgets.dart';

/// Layar pembuka: tampil sebentar saat aplikasi dibuka, lalu pindah ke [next]
/// (di main.dart berisi AuthGate, yang memilih layar Masuk atau Beranda).
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.next,
    this.duration = const Duration(milliseconds: 2400),
  });

  final Widget next;

  /// Lama splash tampil sebelum berpindah layar.
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeOut),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(_textFade);

    _controller.forward();
    _timer = Timer(widget.duration, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (context, animation, secondaryAnimation) => widget.next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned(top: -90, right: -70, child: AuroraGlow(size: 320, color: Color(0xFFFFFFFF), opacity: 0.45)),
              const Positioned(bottom: -120, left: -90, child: AuroraGlow(size: 380, color: Color(0xFF7FDBFF), opacity: 0.4)),
              const Positioned(top: 220, left: -140, child: AuroraGlow(size: 300, color: Color(0xFFBDE8FF), opacity: 0.5)),
              SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: const _Logo(),
                  ),
                ),
                const SizedBox(height: 28),
                FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: const Column(
                      children: [
                        Text(
                          'LaundryKu',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Kasir laundry yang rapi dan cepat',
                          style: TextStyle(color: Color(0xCC0B2545), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 5),
                FadeTransition(
                  opacity: _textFade,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Logo: ikon mesin cuci biru di dalam gelembung putih.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withAlpha(60),
        border: Border.all(color: Colors.white.withAlpha(140), width: 1.5),
      ),
      child: Container(
        width: 112,
        height: 112,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.local_laundry_service_outlined,
          size: 56,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
