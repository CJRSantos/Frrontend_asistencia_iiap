import 'package:flutter/material.dart';

class LeafLogo extends StatelessWidget {
  final double size;
  final Color color;

  const LeafLogo({
    super.key,
    this.size = 48,
    this.color = const Color(0xFFA2E082),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LeafPainter(color: color),
    );
  }
}

class _LeafPainter extends CustomPainter {
  final Color color;

  _LeafPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Leaf outer boundary (tilted ~45 degrees, stem bottom-left, tip top-right)
    final leafOuter = Path();
    leafOuter.moveTo(w * 0.12, h * 0.82);
    // Upper curve to tip
    leafOuter.cubicTo(
      w * 0.08, h * 0.38,
      w * 0.38, h * 0.08,
      w * 0.88, h * 0.14,
    );
    // Lower curve back to base
    leafOuter.cubicTo(
      w * 0.92, h * 0.62,
      w * 0.62, h * 0.92,
      w * 0.12, h * 0.82,
    );

    // Diagonal vein gap
    final veinGap = Path();
    veinGap.moveTo(w * 0.08, h * 0.84);
    veinGap.lineTo(w * 0.80, h * 0.14);
    veinGap.lineTo(w * 0.85, h * 0.19);
    veinGap.lineTo(w * 0.13, h * 0.89);
    veinGap.close();

    final leafPath = Path.combine(PathOperation.difference, leafOuter, veinGap);

    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant _LeafPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
