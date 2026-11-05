import 'dart:math';
import 'package:flutter/material.dart';

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

class _WheelWithCenterState extends State<WheelWithCenter> with SingleTickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  static const Color kGreen = Color(0xFF2BB673);
  final double gapDegrees = 0.6;

  late final AnimationController _ctrl;
  late Animation<double> _anim;

  late final List<List<Color>> _sliceGradients = [
    [const Color(0xFFBBA7F2), const Color(0xFF9F7ED9)],
    [const Color(0xFFF8CC62), const Color(0xFFF4B63E)],
    [const Color(0xFF71E1D8), const Color(0xFF5DE0C9)],
    [const Color(0xFF8DE6DF), const Color(0xFF71C8C3)],
    [const Color(0xFF7ACAF0), const Color(0xFF58B4DA)],
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0.0, end: _toPercent(widget.visibleScore)).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  double _toPercent(double value) {
    final min = widget.minScore;
    final max = widget.maxScore;
    if (max <= min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(covariant WheelWithCenter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibleScore != widget.visibleScore) {
      final newT = _toPercent(widget.visibleScore);
      _anim = Tween<double>(begin: _anim.value, end: newT).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl..reset()..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _ratingText(double p) {
    if (p < 0.33) return 'Poor';
    if (p < 0.66) return 'Good';
    return 'Excellent';
  }

  Color _ratingColor(double p) {
    if (p < 0.33) return Colors.red;
    if (p < 0.66) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.diameter;
    final outerR = size / 2;
    final innerR = outerR * 0.52;
    final sliceCount = widget.labels.length;

    // Adjusted font scaling for smaller diameters
    final scoreFont = (innerR * 0.55).clamp(24.0, 80.0);
    final deltaFont = (innerR * 0.18).clamp(10.0, 16.0);
    final ratingFont = (innerR * 0.22).clamp(11.0, 24.0);

    return GestureDetector(
      key: _key,
      onTapDown: _onTapDown,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _WheelPainter(
                sliceCount: sliceCount,
                gapDeg: gapDegrees,
                innerRadius: innerR,
                selectedIndex: widget.selectedIndex,
                gradients: _sliceGradients,
                rimColor: const Color(0xFF0B0B0B),
                centerBorderColor: Colors.black.withOpacity(0.06),
              ),
            ),

            // Labels & Icons
            ...List.generate(sliceCount, (i) {
              final sweep = 2 * pi / sliceCount;
              final start = -pi / 2 + sweep * i;
              final bis = start + sweep / 2;
              // Slightly adjusted placement to avoid crowding the edge
              final placeR = innerR + (outerR - innerR) * 0.58;
              final cx = size / 2 + cos(bis) * placeR;
              final cy = size / 2 + sin(bis) * placeR;
              final selected = i == widget.selectedIndex;

              return Positioned(
                left: cx - 35, // Narrower hitbox
                top: cy - 28,
                width: 70,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: EdgeInsets.all(selected ? 8 : 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white.withOpacity(0.06),
                        shape: BoxShape.circle,
                        boxShadow: selected ? [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))] : null,
                      ),
                      child: Icon(widget.icons[i], size: selected ? 18 : 14, color: selected ? Colors.black : Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: selected ? 10 : 9,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Semicircle gauge
            Positioned(
              left: size / 2 - innerR,
              top: size / 2 - innerR * 1.15,
              width: innerR * 2,
              height: innerR * 1.06,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (context, _) {
                  final p = _anim.value.clamp(0.0, 1.0);
                  return CustomPaint(
                      size: Size(innerR * 2, innerR * 1.06),
                      painter: _SemiGaugePainter(percent: p, minScore: widget.minScore, maxScore: widget.maxScore)
                  );
                },
              ),
            ),

            // Center circle (White area)
            Container(
              width: innerR * 1.76,
              height: innerR * 1.76,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 4))],
                border: Border.all(color: Colors.black.withOpacity(0.04), width: 1.2),
              ),
            ),

            // Central Score Text
            SizedBox(
              width: innerR * 1.1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(widget.delta >= 0 ? Icons.arrow_upward : Icons.arrow_downward, size: deltaFont, color: widget.delta >= 0 ? kGreen : const Color(0xFFD9534F)),
                    const SizedBox(width: 4),
                    Text('${widget.delta >= 0 ? '+' : '-'}${widget.delta.abs().toInt()}', style: TextStyle(fontSize: deltaFont, fontWeight: FontWeight.bold, color: widget.delta >= 0 ? kGreen : const Color(0xFFD9534F))),
                  ]),
                  Text(widget.visibleScore.toInt().toString(), style: TextStyle(fontSize: scoreFont, fontWeight: FontWeight.w900, color: Colors.black87, height: 1.1)),
                  Text(_ratingText(_toPercent(widget.visibleScore)), style: TextStyle(fontSize: ratingFont, fontWeight: FontWeight.w800, color: _ratingColor(_toPercent(widget.visibleScore)))),
                ],
              ),
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
    final innerR = outerR * 0.52;
    if (dist < innerR || dist > outerR) return;
    double angle = atan2(dy, dx);
    double angleFromTop = angle - (-pi / 2);
    angleFromTop %= (2 * pi);
    if (angleFromTop < 0) angleFromTop += 2 * pi;
    final slice = (angleFromTop / (2 * pi) * widget.labels.length).floor();
    widget.onSliceTap(slice);
  }
}

class _WheelPainter extends CustomPainter {
  final int sliceCount;
  final double gapDeg;
  final double innerRadius;
  final int selectedIndex;
  final List<List<Color>> gradients;
  final Color rimColor;
  final Color centerBorderColor;

  _WheelPainter({
    required this.sliceCount,
    required this.gapDeg,
    required this.innerRadius,
    required this.selectedIndex,
    required this.gradients,
    required this.rimColor,
    required this.centerBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final outerR = size.width / 2;
    final sweep = 2 * pi / sliceCount;
    final gap = gapDeg * pi / 180;

    for (int i = 0; i < sliceCount; i++) {
      final start = -pi / 2 + i * sweep + gap / 2;
      final effSweep = sweep - gap;
      final isSelected = i == selectedIndex;

      canvas.save();
      if (isSelected) {
        final bis = start + effSweep / 2;
        canvas.translate(cos(bis) * 6, sin(bis) * 6);
      }

      final rect = Rect.fromCircle(center: center, radius: outerR);
      final shader = SweepGradient(startAngle: start, endAngle: start + effSweep, colors: gradients[i % gradients.length]).createShader(rect);
      final fillPaint = Paint()..shader = shader;

      final path = Path()
        ..addArc(rect, start, effSweep)
        ..arcTo(Rect.fromCircle(center: center, radius: innerRadius), start + effSweep, -effSweep, false)
        ..close();

      canvas.drawPath(path, fillPaint);

      final divider = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.6, outerR * 0.006)
        ..color = Colors.black.withOpacity(0.12);
      final dividerStart = start - gap / 2;
      canvas.drawArc(Rect.fromCircle(center: center, radius: (outerR + innerRadius) / 2), dividerStart, 0.001, false, divider);

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 4 : 2
        ..color = Colors.black.withOpacity(isSelected ? 0.48 : 0.28);

      final innerRect = Rect.fromCircle(center: center, radius: innerRadius + (isSelected ? 2.0 : 1.0));
      canvas.drawArc(innerRect, start + effSweep, -effSweep, false, stroke);

      canvas.restore();
    }

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = innerRadius * 0.06
      ..color = rimColor;
    canvas.drawCircle(center, innerRadius, rimPaint);

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, innerRadius * 0.028)
      ..color = centerBorderColor;
    canvas.drawCircle(center, innerRadius - 2.0, border);
  }

  @override
  bool shouldRepaint(covariant _WheelPainter old) => old.selectedIndex != selectedIndex;
}

class _SemiGaugePainter extends CustomPainter {
  final double percent;
  final double minScore;
  final double maxScore;
  static const Color kGreen = Color(0xFF2BB673);

  _SemiGaugePainter({required this.percent, this.minScore = 300, this.maxScore = 900});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 1.02);
    final radius = min(size.width / 2, size.height) * 0.95;

    const start = -pi;
    const sweep = pi;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // muted track behind arc (keep this so semicircle is still visible subtly)
    canvas.drawArc(rect, start, sweep, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.14
      ..strokeCap = StrokeCap.round
      ..color = Colors.black.withOpacity(0.06));

    // ---- REMOVED: colorful gradient arc (intentional) ----

    // inner contrast ring (thin)
    final innerRect = Rect.fromCircle(center: center, radius: radius - radius * 0.24);
    canvas.drawArc(innerRect, start + 0.04, sweep - 0.08, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.black.withOpacity(0.06));

    // indicator knob position (kept)
    final angle = start + sweep * percent;
    final knob = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);

    // knob shadow
    canvas.drawCircle(knob.translate(2.0, 2.0), radius * 0.05, Paint()..color = Colors.black.withOpacity(0.16));
    // white outer ring
    canvas.drawCircle(knob, radius * 0.05, Paint()..color = Colors.white);
    // inner dot uses exact green (for green region) or color by percent
    final pick = percent < 0.33 ? const Color(0xFFD9534F) : (percent < 0.66 ? const Color(0xFFF5B041) : kGreen);
    canvas.drawCircle(knob, radius * 0.034, Paint()..color = pick);
    // thin white outline for crispness
    canvas.drawCircle(knob, radius * 0.034, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, radius * 0.008)
      ..color = Colors.white.withOpacity(0.95));

    // tiny triangular needle inside rim (subtle)
    final needleCenter = Offset(center.dx + cos(angle) * (radius * 0.78), center.dy + sin(angle) * (radius * 0.78));
    final triSize = radius * 0.06;
    final triPath = Path();
    final ang1 = angle - 0.12;
    final ang2 = angle + 0.12;
    triPath.moveTo(needleCenter.dx + cos(angle) * triSize, needleCenter.dy + sin(angle) * triSize);
    triPath.lineTo(needleCenter.dx + cos(ang1) * triSize * 1.6, needleCenter.dy + sin(ang1) * triSize * 1.6);
    triPath.lineTo(needleCenter.dx + cos(ang2) * triSize * 1.6, needleCenter.dy + sin(ang2) * triSize * 1.6);
    triPath.close();
    canvas.drawPath(triPath, Paint()..color = Colors.black);

    // min / max labels, horizontally shifted so they are symmetric visually
    final labelStyle = TextStyle(color: Colors.black.withOpacity(0.78), fontSize: max(10.0, radius * 0.11), fontWeight: FontWeight.w600);
    _drawText(canvas, minScore.toInt().toString(), Offset(center.dx - radius - 12, center.dy - radius * 0.12), labelStyle, TextAlign.left);
    _drawText(canvas, maxScore.toInt().toString(), Offset(center.dx + radius - 16, center.dy - radius * 0.12), labelStyle, TextAlign.right);
  }

  void _drawText(Canvas canvas, String text, Offset pos, TextStyle style, TextAlign align) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textAlign: align)..layout();
    final dx = pos.dx - (align == TextAlign.center ? tp.width / 2 : (align == TextAlign.right ? tp.width : 0));
    final dy = pos.dy - tp.height / 2;
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) => old.percent != percent;
}
