import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

/// ---------------------------------------------------------------------------
///  Modern Splash Screen for SetMeFit
///
///  Effects:
///   • Deep gradient background with animated floating particles
///   • Glowing pulsing orb behind the logo
///   • Letter-by-letter "SetMeFit" reveal with blur → sharp + fade + slide
///   • Shimmer sweep across the brand name
///   • Tagline fade-in with subtle slide
///   • Sleek progress indicator with glow
///   • Smooth scale-down + fade exit transition
/// ---------------------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  /// The screen to navigate to after the splash animation completes.
  final Widget Function() nextScreenBuilder;

  const SplashScreen({super.key, required this.nextScreenBuilder});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // --- Animation controllers ---
  late final AnimationController _orbController;
  late final AnimationController _particleController;
  late final AnimationController _exitController;

  // --- Particle data ---
  late final List<_Particle> _particles;
  final _random = Random();

  // --- State ---
  bool _showContent = false;

  @override
  void initState() {
    super.initState();

    // Immersive mode for a cinematic feel
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Orb pulsing
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Floating particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Exit transition
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Generate particles
    _particles = List.generate(30, (_) => _Particle.random(_random));

    // Trigger content after a very short delay so the first frame renders
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _showContent = true);
    });

    // Navigate away after splash duration
    Timer(const Duration(milliseconds: 4200), _navigateAway);
  }

  void _navigateAway() {
    if (!mounted) return;
    _exitController.forward().then((_) {
      if (!mounted) return;
      // Restore system UI
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, _) =>
              widget.nextScreenBuilder(),
          transitionsBuilder: (context, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _orbController.dispose();
    _particleController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: _exitController,
        builder: (context, child) {
          final exitProgress = _exitController.value;
          return Opacity(
            opacity: 1.0 - exitProgress,
            child: Transform.scale(
              scale: 1.0 - (exitProgress * 0.08),
              child: child,
            ),
          );
        },
        child: Stack(
          children: [
            // ── Background Gradient ──
            _buildBackground(),

            // ── Floating Particles ──
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              ),
            ),

            // ── Main Content ──
            SafeArea(
              child: Center(
                child: _showContent
                    ? _buildMainContent(size)
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────── Background ───────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF05050F),
            Color(0xFF0A0E21),
            Color(0xFF0D1B3E),
            Color(0xFF111340),
            Color(0xFF0A0E21),
          ],
          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
        ),
      ),
    );
  }

  // ─────────────── Main Content ───────────────

  Widget _buildMainContent(Size size) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 3),

        // ── Glowing Orb + Logo ──
        _buildGlowingOrb(),

        const SizedBox(height: 48),

        // ── Brand Name: "SetMeFit" ──
        _buildBrandName(),

        const SizedBox(height: 16),

        // ── Tagline ──
        _buildTagline(),

        const Spacer(flex: 2),

        // ── Progress Indicator ──
        _buildProgressIndicator(),

        const SizedBox(height: 48),
      ],
    );
  }

  // ─────────────── Glowing Orb ───────────────

  Widget _buildGlowingOrb() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (context, child) {
        final pulse = 0.85 + (_orbController.value * 0.15);
        final glowOpacity = 0.15 + (_orbController.value * 0.2);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(glowOpacity),
                  blurRadius: 80,
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(glowOpacity * 0.6),
                  blurRadius: 120,
                  spreadRadius: 40,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
              Color(0xFF00B0FF),
            ],
          ),
          border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Colors.white, Color(0xFFCCF5FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SET',
                  style: GoogleFonts.orbitron(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  'ME FIT',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: 4,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
          curve: Curves.elasticOut,
          delay: 200.ms,
        )
        .fadeIn(duration: 500.ms, delay: 200.ms);
  }

  // ─────────────── Brand Name ───────────────

  Widget _buildBrandName() {
    // Letter-by-letter staggered reveal
    const brand = 'SetMeFit';
    const letterDelay = 100; // ms between each letter
    const baseDelay = 800; // ms after orb starts

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(brand.length, (i) {
        final isUpperCase = brand[i] == brand[i].toUpperCase();
        return Text(
          brand[i],
          style: GoogleFonts.orbitron(
            fontSize: isUpperCase ? 44 : 38,
            fontWeight: isUpperCase ? FontWeight.w800 : FontWeight.w400,
            color: isUpperCase
                ? const Color(0xFF00E5FF)
                : Colors.white.withOpacity(0.9),
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: const Color(0xFF00E5FF).withOpacity(0.5),
                blurRadius: 12,
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: baseDelay + (i * letterDelay)),
            )
            .slideY(
              begin: 0.5,
              end: 0,
              duration: 400.ms,
              delay: Duration(milliseconds: baseDelay + (i * letterDelay)),
              curve: Curves.easeOutCubic,
            )
            .blurXY(
              begin: 8,
              end: 0,
              duration: 400.ms,
              delay: Duration(milliseconds: baseDelay + (i * letterDelay)),
            );
      }),
    )
        // Shimmer sweep across the entire brand name after letters land
        .animate(delay: const Duration(milliseconds: 2200))
        .shimmer(
          duration: 1200.ms,
          color: const Color(0xFF00E5FF).withOpacity(0.3),
        );
  }

  // ─────────────── Tagline ───────────────

  Widget _buildTagline() {
    return Text(
      'YOUR FITNESS JOURNEY STARTS HERE',
      style: GoogleFonts.rajdhani(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.5),
        letterSpacing: 4,
      ),
    )
        .animate()
        .fadeIn(
          duration: 600.ms,
          delay: 2000.ms,
        )
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 600.ms,
          delay: 2000.ms,
          curve: Curves.easeOut,
        );
  }

  // ─────────────── Progress Indicator ───────────────

  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 160,
      child: Column(
        children: [
          // Glowing line progress
          Container(
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: Colors.white.withOpacity(0.05),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(1),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 3500),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF00E5FF),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF00E5FF).withOpacity(0.6),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 2400.ms);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  Floating Particle System
// ═══════════════════════════════════════════════════════════════════════════════

class _Particle {
  final double x; // 0..1
  final double y; // 0..1
  final double radius;
  final double speed;
  final double opacity;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.color,
  });

  factory _Particle.random(Random r) {
    final colors = [
      const Color(0xFF00E5FF),
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFF00B0FF),
      Colors.white,
    ];
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      radius: 1.0 + r.nextDouble() * 2.5,
      speed: 0.3 + r.nextDouble() * 0.7,
      opacity: 0.1 + r.nextDouble() * 0.4,
      color: colors[r.nextInt(colors.length)],
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dy = (p.y + progress * p.speed) % 1.0;
      final dx = p.x + sin(progress * 2 * pi * p.speed) * 0.02;
      final paint = Paint()
        ..color = p.color.withOpacity(p.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(
        Offset(dx * size.width, dy * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}



