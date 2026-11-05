import 'package:flutter/material.dart';
import '../domain/workout_point.dart';

class RouteCanvas extends CustomPainter {
  final List<WorkoutPoint> points;

  RouteCanvas(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    final center = Offset(size.width / 2, size.height / 2);
    path.moveTo(center.dx, center.dy);

    for (final p in points) {
      path.lineTo(center.dx + p.x, center.dy - p.y);
    }

    canvas.drawPath(path, paint);

    // Start marker
    canvas.drawCircle(center, 6, Paint()..color = Colors.green);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
