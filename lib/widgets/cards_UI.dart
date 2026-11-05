import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardItem {
  final String title;
  final IconData icon;
  final Color color;
  const CardItem(this.title, this.icon, this.color);
}

/// Top horizontal section of selectable cards used in the original page.
class SectionCardRow extends StatelessWidget {
  final List<CardItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const SectionCardRow({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final it = items[index];
          final bool isActive = index == selectedIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 90,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isActive ? it.color.withOpacity(0.18) : Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive ? it.color : Colors.white12,
                  width: isActive ? 2.5 : 1.0,
                ),
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: it.color.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  )
                ]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.icon, color: it.color, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    it.title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Animated background layer (extracted so other files can reuse it)
class AnimatedBackgroundLayer extends StatelessWidget {
  final bool isActive;
  final AnimationController silhouetteController;

  const AnimatedBackgroundLayer({super.key, required this.isActive, required this.silhouetteController});

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox.shrink();

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: true,
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF15102A), Color(0x00121030)],
                ),
              ),
            ),
            Positioned.fill(child: _SilhouetteAnimation(controller: silhouetteController)),
            Container(color: Colors.black.withOpacity(0.32)),
          ],
        ),
      ),
    );
  }
}

class _SilhouetteAnimation extends StatelessWidget {
  final AnimationController controller;
  const _SilhouetteAnimation({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(animation: controller, builder: (context, child) {
      final t = controller.value;
      return Stack(fit: StackFit.expand, children: [
        _movingSilhouette(t, vertical: 0.65, scale: 1.0, offset: 0.0),
        _movingSilhouette(t, vertical: 0.75, scale: 0.8, offset: 0.33),
        _movingSilhouette(t, vertical: 0.55, scale: 0.9, offset: 0.66),
      ]);
    });
  }

  Widget _movingSilhouette(double t, {required double vertical, double scale = 1.0, double offset = 0.0}) {
    final progress = ((t + offset) % 1.0);
    final x = -0.3 + 1.6 * progress;
    return FractionalTranslation(
      translation: Offset(x, 0),
      child: Align(
        alignment: Alignment(0, vertical * 2 - 1),
        child: Transform.scale(scale: scale, child: Opacity(opacity: (0.9 - (scale * 0.1)).clamp(0.0, 1.0), child: _SilhouetteShape())),
      ),
    );
  }
}

class _SilhouetteShape extends StatelessWidget {
  const _SilhouetteShape({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 160, height: 80, child: CustomPaint(painter: _RunnerPainter()));
  }
}

class _RunnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.85);
    final body = Path()
      ..moveTo(size.width * 0.2, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.3, size.height * 0.28, size.width * 0.45, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.32, size.width * 0.7, size.height * 0.5)
      ..lineTo(size.width * 0.75, size.height * 0.6)
      ..lineTo(size.width * 0.65, size.height * 0.7)
      ..lineTo(size.width * 0.52, size.height * 0.68)
      ..lineTo(size.width * 0.4, size.height * 0.74)
      ..close();
    final head = Path()..addOval(Rect.fromCircle(center: Offset(size.width * 0.22, size.height * 0.28), radius: 8));
    canvas.drawPath(body, paint);
    canvas.drawPath(head, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}