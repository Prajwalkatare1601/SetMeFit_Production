import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A futuristic, cyber-aesthetic donut chart that displays 5 interactive health pillars:
/// Activities, Well-being, Diet, Medical, and Tongue.
///
/// Features:
/// - Replaces the legacy speedometer with a clean, high-tech glowing central core.
/// - Dynamic interactive tap animation with spring bounce and radial slice pop.
/// - Vibrant neon cyber-glass aesthetic matching the dark futuristic theme.
class WheelWithCenter extends StatefulWidget {
  final double diameter;
  final List<String> labels;
  final List<IconData> icons;
  final double visibleScore;
  final double delta;
  final double minScore;
  final double maxScore;
  final int selectedIndex;
  final ValueChanged<int> onSliceTap;

  const WheelWithCenter({
    Key? key,
    required this.diameter,
    required this.labels,
    required this.icons,
    required this.visibleScore,
    required this.delta,
    this.minScore = 250,
    this.maxScore = 1000,
    this.selectedIndex = -1,
    required this.onSliceTap,
  }) : super(key: key);

  @override
  State<WheelWithCenter> createState() => _WheelWithCenterState();
}

class _WheelWithCenterState extends State<WheelWithCenter>
    with TickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  final double gapDegrees = 2.4;

  // Animation controllers
  late final AnimationController _scoreCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _tapCtrl;

  late Animation<double> _scoreAnim;
  late Animation<double> _tapScaleAnim;
  late Animation<double> _tapPopAnim;

  int _selectedSlice = -1;
  int _animatingSlice = -1;

  // Futuristic Neon Pillar Colors
  static const List<Color> _sliceColors = [
    Color(0xFF6366F1), // Activities - Cyber Indigo
    Color(0xFF8B5CF6), // Well-being - Cosmic Violet
    Color(0xFF0EA5E9), // Diet - Electric Sky
    Color(0xFFEC4899), // Medical - Neon Rose
    Color(0xFF84CC16), // Tongue - Bio Lime
  ];

  static const List<List<Color>> _sliceGradients = [
    [Color(0xFF6366F1), Color(0xFF4338CA)], // Activities
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)], // Well-being
    [Color(0xFF0EA5E9), Color(0xFF0369A1)], // Diet
    [Color(0xFFEC4899), Color(0xFFBE185D)], // Medical
    [Color(0xFF84CC16), Color(0xFF4D7C0F)], // Tongue
  ];

  @override
  void initState() {
    super.initState();
    _selectedSlice = widget.selectedIndex >= 0 ? widget.selectedIndex : 0;

    final targetScore = (widget.visibleScore.isNaN || widget.visibleScore < 0)
        ? 0.0
        : widget.visibleScore;

    // Score count-up animation
    _scoreCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scoreAnim = Tween<double>(begin: 0.0, end: targetScore).animate(
      CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic),
    );
    _scoreCtrl.forward();

    // Subtle ambient breathing glow animation
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    // Tap feedback spring animation
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    // Internal curved intervals ensure bounds stay strictly within 0.0 .. 1.0
    _tapScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.88).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.88, end: 1.12).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
    ]).animate(_tapCtrl);

    _tapPopAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant WheelWithCenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibleScore != widget.visibleScore) {
      final safeOld = _scoreAnim.value.isNaN ? 0.0 : _scoreAnim.value;
      final safeNew = (widget.visibleScore.isNaN || widget.visibleScore < 0)
          ? 0.0
          : widget.visibleScore;
      _scoreAnim = Tween<double>(
        begin: safeOld,
        end: safeNew,
      ).animate(CurvedAnimation(parent: _scoreCtrl, curve: Curves.easeOutCubic));
      _scoreCtrl
        ..reset()
        ..forward();
    }
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex >= 0) {
      setState(() {
        _selectedSlice = widget.selectedIndex;
      });
    }
  }

  @override
  void dispose() {
    _scoreCtrl.dispose();
    _pulseCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  double _toPercent(double value) {
    if (value.isNaN) return 0.0;
    final min = widget.minScore;
    final max = widget.maxScore;
    if (max <= min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  String _ratingText(double p) {
    if (p < 0.35) return 'Needs Focus';
    if (p < 0.65) return 'Good Pace';
    if (p < 0.85) return 'Optimal';
    return 'Peak Form';
  }

  Color _activeColor() {
    if (_selectedSlice >= 0 && _selectedSlice < _sliceColors.length) {
      return _sliceColors[_selectedSlice];
    }
    return const Color(0xFF00E5FF);
  }

  void _handleSliceTap(int slice) {
    if (slice < 0 || slice >= widget.labels.length) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _selectedSlice = slice;
      _animatingSlice = slice;
    });

    _tapCtrl.forward(from: 0.0);

    // Provide a 220ms delay so the user experiences the spring bounce and neon expansion
    Future.delayed(const Duration(milliseconds: 220), () {
      if (mounted) {
        widget.onSliceTap(slice);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.diameter;
    final outerR = size / 2;
    final innerR = outerR * 0.54;
    final sliceCount = widget.labels.length;
    final activeCol = _activeColor();

    return GestureDetector(
      key: _key,
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Futuristic Donut Slices & HUD Orbit
            AnimatedBuilder(
              animation: Listenable.merge([_tapPopAnim, _pulseCtrl]),
              builder: (context, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _FuturisticWheelPainter(
                    sliceCount: sliceCount,
                    gapDeg: gapDegrees,
                    innerRadius: innerR,
                    selectedIndex: _selectedSlice,
                    animatingIndex: _animatingSlice,
                    popProgress: _tapPopAnim.value,
                    pulseProgress: _pulseCtrl.value,
                    sliceGradients: _sliceGradients,
                    sliceColors: _sliceColors,
                  ),
                );
              },
            ),

            // 2. Interactive Pillar Buttons (Positioned is direct child of Stack!)
            ...List.generate(sliceCount, (i) {
              final sweep = 2 * pi / sliceCount;
              final start = -pi / 2 + sweep * i;
              final bis = start + sweep / 2;
              final placeR = innerR + (outerR - innerR) * 0.52;

              final isSelected = i == _selectedSlice;
              final isTapped = i == _animatingSlice;

              final cx = size / 2 + cos(bis) * placeR;
              final cy = size / 2 + sin(bis) * placeR;

              return Positioned(
                left: cx - 36,
                top: cy - 28,
                width: 72,
                child: AnimatedBuilder(
                  animation: _tapCtrl,
                  builder: (context, child) {
                    final pop = isSelected
                        ? (7.0 + (_tapPopAnim.value * 3.0))
                        : 0.0;
                    final dx = cos(bis) * pop;
                    final dy = sin(bis) * pop;
                    final scale = isTapped
                        ? _tapScaleAnim.value
                        : (isSelected ? 1.05 : 0.95);

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: Transform.scale(
                        scale: scale,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Sleek Icon Pod with Glow
                            Container(
                              width: isSelected ? 32 : 26,
                              height: isSelected ? 32 : 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isSelected
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [Colors.white, Color(0xFFF1F5F9)],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          Colors.white.withOpacity(0.12),
                                          Colors.white.withOpacity(0.04),
                                        ],
                                      ),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.18),
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: _sliceColors[i].withOpacity(0.7),
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: Icon(
                                  widget.icons[i],
                                  size: isSelected ? 16 : 13,
                                  color: isSelected
                                      ? _sliceColors[i]
                                      : Colors.white70,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            // Pillar Category Title
                            Text(
                              widget.labels[i],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white60,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                fontSize: isSelected ? 9.5 : 8.5,
                                letterSpacing: 0.3,
                                shadows: isSelected
                                    ? [
                                        Shadow(
                                          color: _sliceColors[i].withOpacity(0.9),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }),

            // 3. Futuristic Central Core (Clean, Simple, Sci-Fi HUD)
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (context, _) {
                final pulse = _pulseCtrl.value;
                return Container(
                  width: innerR * 1.82,
                  height: innerR * 1.82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF131826),
                        Color(0xFF090B12),
                      ],
                    ),
                    border: Border.all(
                      color: activeCol.withOpacity(0.40 + (pulse * 0.20)),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: activeCol.withOpacity(0.25 + (pulse * 0.15)),
                        blurRadius: 20 + (pulse * 8),
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 4. Central Telemetry Content
            AnimatedBuilder(
              animation: _scoreAnim,
              builder: (context, _) {
                final displayScore = _scoreAnim.value.isNaN
                    ? 0
                    : _scoreAnim.value.toInt();
                final percent = _toPercent(displayScore.toDouble());

                return SizedBox(
                  width: innerR * 1.5,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Delta Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: (widget.delta >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF43F5E))
                              .withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: (widget.delta >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF43F5E))
                                .withOpacity(0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.delta >= 0
                                  ? Icons.arrow_drop_up_rounded
                                  : Icons.arrow_drop_down_rounded,
                              size: 14,
                              color: widget.delta >= 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF43F5E),
                            ),
                            Text(
                              '${widget.delta >= 0 ? '+' : ''}${widget.delta.toInt()}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: widget.delta >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF43F5E),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Large Bold Score
                      Text(
                        displayScore.toString(),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.0,
                          height: 1.05,
                        ),
                      ),

                      const SizedBox(height: 1),

                      // Futuristic Label
                      Text(
                        'HEALTH SCORE',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withOpacity(0.5),
                          letterSpacing: 1.5,
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Status Text
                      Text(
                        _ratingText(percent).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: activeCol,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(details.globalPosition);
    final center = Offset(box.size.width / 2, box.size.height / 2);
    final dx = local.dx - center.dx;
    final dy = local.dy - center.dy;
    final dist = sqrt(dx * dx + dy * dy);
    final outerR = box.size.width / 2;
    final innerR = outerR * 0.54;

    // Reject taps inside the center core or outside the donut ring
    if (dist < innerR || dist > outerR + 14) return;

    double angle = atan2(dy, dx);
    double angleFromTop = angle - (-pi / 2);
    angleFromTop %= (2 * pi);
    if (angleFromTop < 0) angleFromTop += 2 * pi;

    final slice = (angleFromTop / (2 * pi) * widget.labels.length).floor();
    if (slice >= 0 && slice < widget.labels.length) {
      _handleSliceTap(slice);
    }
  }
}

/// Custom painter that renders futuristic segmented donut arcs with radial pop and cyber HUD details.
class _FuturisticWheelPainter extends CustomPainter {
  final int sliceCount;
  final double gapDeg;
  final double innerRadius;
  final int selectedIndex;
  final int animatingIndex;
  final double popProgress;
  final double pulseProgress;
  final List<List<Color>> sliceGradients;
  final List<Color> sliceColors;

  _FuturisticWheelPainter({
    required this.sliceCount,
    required this.gapDeg,
    required this.innerRadius,
    required this.selectedIndex,
    required this.animatingIndex,
    required this.popProgress,
    required this.pulseProgress,
    required this.sliceGradients,
    required this.sliceColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || innerRadius <= 0) return;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = size.width / 2;
    final sweep = 2 * pi / sliceCount;
    final gap = gapDeg * pi / 180;

    // 1. Draw Outer Cyber Orbit HUD Ring
    final orbitPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.08);
    canvas.drawCircle(center, outerR + 2, orbitPaint);

    // 2. Draw Subtle Outer HUD Tick Marks
    final tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.14);
    for (int t = 0; t < 20; t++) {
      final a = t * (2 * pi / 20);
      final p1 = Offset(cx + cos(a) * (outerR + 2), cy + sin(a) * (outerR + 2));
      final p2 = Offset(cx + cos(a) * (outerR + 6), cy + sin(a) * (outerR + 6));
      canvas.drawLine(p1, p2, tickPaint);
    }

    // 3. Draw Donut Segments
    for (int i = 0; i < sliceCount; i++) {
      final start = -pi / 2 + i * sweep + gap / 2;
      final effSweep = sweep - gap;
      final bis = start + effSweep / 2;
      final isSelected = i == selectedIndex;
      final isAnimating = i == animatingIndex;

      canvas.save();

      // Radial pop for the selected / active slice
      final pop = isSelected
          ? (7.0 + (isAnimating ? popProgress * 3.0 : 0.0))
          : 0.0;
      if (pop > 0) {
        canvas.translate(cos(bis) * pop, sin(bis) * pop);
      }

      final rect = Rect.fromCircle(center: center, radius: outerR);
      final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

      final path = Path()
        ..addArc(rect, start, effSweep)
        ..arcTo(innerRect, start + effSweep, -effSweep, false)
        ..close();

      // Gradient Fill
      final gradients = sliceGradients[i % sliceGradients.length];
      final shader = SweepGradient(
        startAngle: start,
        endAngle: start + effSweep,
        colors: isSelected
            ? gradients
            : [
                gradients[0].withOpacity(0.70),
                gradients[1].withOpacity(0.70),
              ],
      ).createShader(rect);

      final fillPaint = Paint()..shader = shader;
      canvas.drawPath(path, fillPaint);

      // Selected Slice Outer Glow & Luminescent Border
      if (isSelected) {
        final strokePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.white.withOpacity(0.92);
        canvas.drawPath(path, strokePaint);

        // Hardware-accelerated glow stroke without complex mask filters
        final glowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0
          ..color = sliceColors[i % sliceColors.length].withOpacity(0.45);
        canvas.drawPath(path, glowPaint);
      } else {
        final borderPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0
          ..color = Colors.white.withOpacity(0.12);
        canvas.drawPath(path, borderPaint);
      }

      canvas.restore();
    }

    // 4. Draw Inner Cyber Ring
    final activeCol = selectedIndex >= 0 && selectedIndex < sliceColors.length
        ? sliceColors[selectedIndex]
        : const Color(0xFF00E5FF);

    final innerRim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = activeCol.withOpacity(0.35);
    canvas.drawCircle(center, innerRadius, innerRim);
  }

  @override
  bool shouldRepaint(covariant _FuturisticWheelPainter old) {
    return old.selectedIndex != selectedIndex ||
        old.animatingIndex != animatingIndex ||
        old.popProgress != popProgress ||
        old.pulseProgress != pulseProgress;
  }
}
