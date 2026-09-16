import 'package:flutter/material.dart';

/// Painted cycle and bike plates. Used when those image files are not in the
/// running asset bundle yet.
class VehiclePlate extends StatelessWidget {
  const VehiclePlate({super.key, required this.id, this.color = const Color(0xFF3A3D42)});

  final String id;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PlatePainter(id, color),
      child: const SizedBox.expand(),
    );
  }
}

class _PlatePainter extends CustomPainter {
  _PlatePainter(this.id, this.color);

  final String id;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = Paint()..color = const Color(0xFFE8EAED);
    final red = Paint()..color = const Color(0xFFD62830);
    final dark = Paint()..color = const Color(0xFF1C1E22);
    if (id == 'cycle') {
      _ring(canvas, Offset(cx, size.height * 0.28), size.width * 0.22);
      _ring(canvas, Offset(cx, size.height * 0.74), size.width * 0.22);
      canvas.drawLine(
        Offset(cx, size.height * 0.28),
        Offset(cx, size.height * 0.74),
        paint..strokeWidth = size.width * 0.045,
      );
      canvas.drawCircle(Offset(cx, size.height * 0.34), size.width * 0.05, red);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, size.height * 0.46), width: size.width * 0.16, height: size.height * 0.12),
          const Radius.circular(4),
        ),
        dark,
      );
      return;
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.5), width: size.width * 0.34, height: size.height * 0.46),
        Radius.circular(size.width * 0.06),
      ),
      dark,
    );
    _ring(canvas, Offset(cx, size.height * 0.28), size.width * 0.26);
    _ring(canvas, Offset(cx, size.height * 0.74), size.width * 0.26);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.42), width: size.width * 0.18, height: size.height * 0.08),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF243648),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.58), width: size.width * 0.2, height: size.height * 0.035),
        const Radius.circular(2),
      ),
      red,
    );
  }

  void _ring(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFFE8EAED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.28,
    );
  }

  @override
  bool shouldRepaint(covariant _PlatePainter old) => old.id != id || old.color != color;
}
