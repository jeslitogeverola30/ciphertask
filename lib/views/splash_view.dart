import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with TickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  static const Color zinc950 = Color(0xFF09090b);
  static const Color zinc100 = Color(0xFFf4f4f5);
  static const Color zinc400 = Color(0xFFa1a1aa);
  static const Color zinc800 = Color(0xFF27272a);
  static const Color cyberRed = Color(0xFFff2b55);
  static const Color cyberRedSoft = Color(0xFFff5e7a);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _timer = Timer(const Duration(seconds: 3), _goNext);
  }

  void _goNext() {
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    if (auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/todos');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: zinc950,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _CyberpunkBackgroundPainter()),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.black.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14070c),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cyberRed.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.terminal_rounded,
                        size: 48,
                        color: zinc100,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'CIPHERTASK',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: zinc100,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Secure Workflow Management',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: zinc400,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        backgroundColor: zinc800,
                        color: cyberRedSoft,
                        minHeight: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'V 1.0.0',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: cyberRed.withValues(alpha: 0.55),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberpunkBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF09090b), Color(0xFF12040A), Color(0xFF0A0508)],
        stops: [0, 0.52, 1],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    final redGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.5),
        radius: 1.2,
        colors: [
          const Color(0xFFff2b55).withValues(alpha: 0.28),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, redGlow);

    final sideGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.95, 0.8),
        radius: 0.9,
        colors: [
          const Color(0xFFff5e7a).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(rect);
    canvas.drawRect(rect, sideGlow);

    final horizonY = size.height * 0.58;
    final gridPaint = Paint()
      ..color = const Color(0xFFff2b55).withValues(alpha: 0.13)
      ..strokeWidth = 1;

    for (int i = 0; i <= 16; i++) {
      final t = i / 16;
      final depth = math.pow(t, 1.65).toDouble();
      final y = horizonY + (size.height - horizonY) * depth;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final vanishingPoint = Offset(size.width * 0.5, horizonY);
    for (int i = 0; i <= 18; i++) {
      final x = size.width * i / 18;
      canvas.drawLine(Offset(x, size.height), vanishingPoint, gridPaint);
    }

    final signalPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFff5e7a).withValues(alpha: 0.3);

    for (int line = 0; line < 4; line++) {
      final path = Path();
      final baseY = size.height * (0.16 + (line * 0.09));

      for (double x = 0; x <= size.width; x += 6) {
        final normalizedX = x / size.width;
        final waveA = math.sin(
          (normalizedX * math.pi * 2 * (2.2 + (line * 0.32))) + (line * 0.7),
        );
        final waveB = math.cos((normalizedX * math.pi * 2 * 5.2) - line);
        final y = baseY + (waveA * (8 + line * 2)) + (waveB * 2.6);

        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, signalPaint);
    }

    final scanlinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.02)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanlinePaint);
    }

    final nodePaint = Paint()
      ..color = const Color(0xFFff8aa0).withValues(alpha: 0.32);
    for (int i = 0; i < 70; i++) {
      final dx = ((i * 97) % 1000) / 1000 * size.width;
      final dy = ((i * 57) % 1000) / 1000 * size.height;
      final radius = 0.6 + (((i * 13) % 10) / 20);
      canvas.drawCircle(Offset(dx, dy), radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_CyberpunkBackgroundPainter oldDelegate) => false;
}
