import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'car_race_controller.dart';
import 'car_sprite_cache.dart';
import 'chennai_route.dart';

/// Behind-the-car highway camera. Original Chennai-style city, not a copy of any commercial game.
class CityRacePainter extends CustomPainter {
  CityRacePainter({required this.controller});

  final CarRaceController controller;
  static const _asphalt = Color(0xFF2B3036);
  static const _asphaltNear = Color(0xFF353C44);
  static const _laneDash = Color(0xFFEDE6D6);
  static const _sidewalk = Color(0xFF8A8074);

  late Size _size;
  late double _horizon;

  double get _roadHalf =>
      CarRaceController.laneCount * CarRaceController.laneWidthM / 2;

  double get _bend {
    switch (controller.navHint.turn) {
      case NavTurn.left:
        return -0.46;
      case NavTurn.right:
        return 0.46;
      case NavTurn.slightLeft:
        return -0.22;
      case NavTurn.slightRight:
        return 0.22;
      default:
        return 0;
    }
  }

  Offset _project(double x, double z) {
    final curve = _bend * z * z * 0.0011;
    final depth = (z + 7.2).clamp(0.8, 220.0);
    final focal = _size.width * 0.92;
    final cam = controller.playerX;
    final ground = (_size.height - _horizon) * 12.4;
    return Offset(
      _size.width * 0.5 + focal * (x - cam * 0.28 + curve) / depth,
      _horizon + ground / depth,
    );
  }

  double _scaleAt(double z) => 26.0 / (z + 7.2);

  SidePair get _sides => controller.route.sidesForPlace(controller.currentPlace);

  @override
  void paint(Canvas canvas, Size size) {
    _size = size;
    _horizon = size.height * 0.16;

    canvas.save();
    canvas.translate(size.width * 0.5, size.height * 0.55);
    canvas.rotate(-controller.steerInput * 0.045);
    canvas.translate(-size.width * 0.5, -size.height * 0.55);

    _paintSky(canvas, size);
    _paintFarLand(canvas, size);
    _paintScenery(canvas, size);
    _paintRoad(canvas);
    _paintRails(canvas);
    _paintTraffic(canvas);
    _paintPlayer(canvas);
    canvas.restore();

    if (controller.nitroActive) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFFF7A18).withValues(alpha: 0.08),
      );
    }
    if (controller.nearMissFlash) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.07),
      );
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final sand = _sides.left == SideKind.sand || _sides.right == SideKind.sand;
    final colors = sand
        ? const [Color(0xFF8EC8E8), Color(0xFFE7D2A4), Color(0xFFF0D7A8)]
        : const [Color(0xFF6EAEDE), Color(0xFFC5D8EA), Color(0xFFD9C8B4)];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(Rect.fromLTWH(0, 0, size.width, _horizon + 18)),
    );
  }

  void _paintRoad(Canvas canvas) {
    const nearZ = 4.2;
    const farZ = 118.0;
    final half = _roadHalf;
    final fl = _project(-half, farZ);
    final fr = _project(half, farZ);
    final nl = _project(-half, nearZ);
    final nr = _project(half, nearZ);

    final road = Path()
      ..moveTo(fl.dx, fl.dy)
      ..lineTo(fr.dx, fr.dy)
      ..lineTo(nr.dx, nr.dy)
      ..lineTo(nl.dx, nl.dy)
      ..close();
    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_asphalt, const Color(0xFF4A515A), _asphaltNear],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(Rect.fromPoints(fl, nr)),
    );

    _edgeLine(canvas, -half, nearZ, farZ);
    _edgeLine(canvas, half, nearZ, farZ);
    _roadWear(canvas, half);

    final walkL = Path()
      ..moveTo(_project(-half - 1.6, farZ).dx, _project(-half - 1.6, farZ).dy)
      ..lineTo(_project(-half, farZ).dx, _project(-half, farZ).dy)
      ..lineTo(_project(-half, nearZ).dx, _project(-half, nearZ).dy)
      ..lineTo(_project(-half - 2.4, nearZ).dx, _project(-half - 2.4, nearZ).dy)
      ..close();
    canvas.drawPath(walkL, Paint()..color = _sidewalk.withValues(alpha: 0.7));

    final walkR = Path()
      ..moveTo(_project(half, farZ).dx, _project(half, farZ).dy)
      ..lineTo(_project(half + 1.8, farZ).dx, _project(half + 1.8, farZ).dy)
      ..lineTo(_project(half + 2.6, nearZ).dx, _project(half + 2.6, nearZ).dy)
      ..lineTo(_project(half, nearZ).dx, _project(half, nearZ).dy)
      ..close();
    canvas.drawPath(walkR, Paint()..color = const Color(0xFF6E675C));

    for (var lane = 1; lane < CarRaceController.laneCount; lane++) {
      final x = -half + lane * CarRaceController.laneWidthM;
      _dashedLane(canvas, x);
    }
  }

  void _edgeLine(Canvas canvas, double x, double nearZ, double farZ) {
    final a = _project(x, farZ);
    final b = _project(x, nearZ);
    canvas.drawLine(
      a,
      b,
      Paint()
        ..color = const Color(0xFFF2F4F6)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.square,
    );
  }

  void _roadWear(Canvas canvas, double half) {
    final scroll = controller.roadScroll;
    for (var i = 0; i < 10; i++) {
      final z = 8 + ((i * 11 + scroll * 0.35) % 90);
      final x = -half * 0.55 + (i % 4) * half * 0.28;
      final a = _project(x, z);
      final b = _project(x + 0.8, z + 3.2);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = const Color(0xFF1C2126).withValues(alpha: 0.35)
          ..strokeWidth = (5 * _scaleAt(z)).clamp(1.0, 8.0),
      );
    }
  }

  void _dashedLane(Canvas canvas, double x) {
    const seg = 7.0;
    final scroll = controller.roadScroll % (seg * 2);
    for (var z = 6.0; z < 110; z += seg * 2) {
      final z0 = z - scroll;
      final z1 = z0 + seg;
      if (z1 < 5) continue;
      final a = _project(x, z0.clamp(5.0, 110.0));
      final b = _project(x, z1.clamp(5.0, 110.0));
      final w = (2.6 * _scaleAt(z0)).clamp(1.1, 5.5);
      canvas.drawLine(
        a,
        b,
        Paint()
          ..color = _laneDash.withValues(alpha: 0.88)
          ..strokeWidth = w
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  void _paintFarLand(Canvas canvas, Size size) {
    final sides = _sides;
    final left = _landColor(sides.left);
    final right = _landColor(sides.right);
    canvas.drawRect(Rect.fromLTWH(0, _horizon - 6, size.width * 0.5, 24), Paint()..color = left);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.5, _horizon - 6, size.width * 0.5, 24), Paint()..color = right);
  }

  Color _landColor(SideKind kind) {
    switch (kind) {
      case SideKind.sand:
        return const Color(0xFFE2C27A);
      case SideKind.green:
        return const Color(0xFF6E8F52);
      case SideKind.city:
        return const Color(0xFF9AA4AE);
    }
  }

  void _paintScenery(Canvas canvas, Size size) {
    const farZ = 108.0;
    const nearZ = 4.0;
    final half = _roadHalf + 1.15;
    final sides = _sides;
    _fillSide(canvas, size, -1, half, farZ, nearZ, _landColor(sides.left));
    _fillSide(canvas, size, 1, half, farZ, nearZ, _landColor(sides.right));
    _paintSideProps(canvas, -1, half, sides.left);
    _paintSideProps(canvas, 1, half, sides.right);
  }

  void _fillSide(Canvas canvas, Size size, double sign, double half, double farZ, double nearZ, Color color) {
    final edgeNear = _project(sign * half, nearZ);
    final edgeFar = _project(sign * half, farZ);
    final path = Path()
      ..moveTo(sign < 0 ? 0 : size.width, _horizon)
      ..lineTo(edgeFar.dx, edgeFar.dy)
      ..lineTo(edgeNear.dx, edgeNear.dy)
      ..lineTo(sign < 0 ? 0 : size.width, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintSideProps(Canvas canvas, double sign, double half, SideKind kind) {
    final x = sign * (half + (kind == SideKind.city ? 7.5 : 6.2));
    switch (kind) {
      case SideKind.city:
        _cityBlocks(canvas, x, sign < 0);
      case SideKind.sand:
        _sandDunes(canvas, x, beach: sign > 0);
      case SideKind.green:
        _palms(canvas, x);
    }
  }

  void _cityBlocks(Canvas canvas, double x, bool tall) {
    const step = 13.0;
    final scroll = controller.roadScroll % step;
    const colors = [
      Color(0xFFD9C7B4),
      Color(0xFF8EA0B4),
      Color(0xFFC46A45),
      Color(0xFFE7E1D6),
      Color(0xFF5E7384),
    ];
    for (var i = 8; i >= 0; i--) {
      final z = 8 + i * step - scroll;
      if (z < 5.5) continue;
      final p = _project(x, z);
      final s = _scaleAt(z);
      final w = (tall ? 42 : 30) * s;
      final h = ((tall ? 34 : 20) + (i % 4) * 8) * s;
      final body = Rect.fromCenter(center: Offset(p.dx, p.dy - h * 0.45), width: w, height: h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(2 * s)),
        Paint()..color = colors[(i + (tall ? 1 : 3)) % colors.length],
      );
      final glass = Paint()..color = const Color(0xFFD7E7F2).withValues(alpha: 0.85);
      for (var r = 0; r < 3; r++) {
        for (var c = 0; c < 2; c++) {
          canvas.drawRect(
            Rect.fromLTWH(
              body.left + w * (0.18 + c * 0.36),
              body.top + h * (0.16 + r * 0.22),
              w * 0.16,
              h * 0.1,
            ),
            glass,
          );
        }
      }
    }
  }

  void _sandDunes(Canvas canvas, double x, {required bool beach}) {
    const step = 12.0;
    final scroll = controller.roadScroll % step;
    for (var i = 9; i >= 0; i--) {
      final z = 7 + i * step - scroll;
      if (z < 5) continue;
      final p = _project(x, z);
      final s = _scaleAt(z);
      canvas.drawOval(
        Rect.fromCenter(
          center: p.translate(0, -4 * s),
          width: (beach ? 36 : 48) * s,
          height: (beach ? 14 : 18) * s,
        ),
        Paint()..color = beach ? const Color(0xFFF0D59A) : const Color(0xFFC9974A),
      );
      if (i.isEven) {
        canvas.drawOval(
          Rect.fromCenter(center: p.translate(8 * s, -8 * s), width: 10 * s, height: 6 * s),
          Paint()..color = const Color(0xFF8A9A62),
        );
      }
    }
  }

  void _paintRails(Canvas canvas) {
    for (final side in [-1.0, 1.0]) {
      final x = side * (_roadHalf + 0.55);
      final far = _project(x, 100);
      final near = _project(x, 4.4);
      canvas.drawLine(
        far,
        near,
        Paint()
          ..color = const Color(0xFFD7DCE1)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        far,
        near,
        Paint()
          ..color = const Color(0xFF8E979F)
          ..strokeWidth = 1.2,
      );
      const step = 5.5;
      final scroll = controller.roadScroll % step;
      for (var z = 6.0; z < 96; z += step) {
        final zz = z - scroll;
        if (zz < 4.5) continue;
        final p = _project(x, zz);
        final s = _scaleAt(zz);
        canvas.drawLine(
          p,
          Offset(p.dx, p.dy - 10 * s),
          Paint()
            ..color = const Color(0xFFC5CCD2)
            ..strokeWidth = (1.4 * s).clamp(1.0, 4.0),
        );
      }
    }
  }

  void _palms(Canvas canvas, double x) {
    const step = 14.0;
    final scroll = controller.roadScroll % step;
    for (var i = 8; i >= 0; i--) {
      final z = 10 + i * step - scroll;
      if (z < 6) continue;
      final p = _project(x, z);
      final s = _scaleAt(z);
      final h = 46 * s;
      canvas.drawLine(
        p,
        Offset(p.dx, p.dy - h),
        Paint()
          ..color = const Color(0xFF6B4A32)
          ..strokeWidth = (2.2 * s).clamp(1.2, 6),
      );
      final frond = Paint()
        ..color = const Color(0xFF3E7A3A)
        ..strokeWidth = (1.6 * s).clamp(1, 4)
        ..strokeCap = StrokeCap.round;
      final top = Offset(p.dx, p.dy - h);
      canvas.drawLine(top, top.translate(-10 * s, 6 * s), frond);
      canvas.drawLine(top, top.translate(10 * s, 6 * s), frond);
      canvas.drawLine(top, top.translate(-4 * s, -8 * s), frond);
      canvas.drawLine(top, top.translate(4 * s, -8 * s), frond);
    }
  }

  void _paintTraffic(Canvas canvas) {
    final cars = List<TrafficCar>.from(controller.traffic)
      ..sort((a, b) => b.z.compareTo(a.z));
    for (final car in cars) {
      if (car.z < 4.8 || car.z > 112) continue;
      _drawCarSprite(canvas, car.sprite, car.color, car.x, car.z);
    }
  }

  void _paintPlayer(Canvas canvas) {
    _drawCarSprite(
      canvas,
      controller.playerSprite,
      controller.spec.color,
      controller.playerX,
      6.4,
      player: true,
    );
  }

  void _drawCarSprite(
    Canvas canvas,
    String sprite,
    Color color,
    double x,
    double z, {
    bool player = false,
  }) {
    final p = _project(x, z);
    final s = _scaleAt(z);
    final w = (player ? 108.0 : 92.0) * s * (player ? controller.spec.widthFactor : 1);
    final h = (player ? 150.0 : 128.0) * s * (player ? controller.spec.widthFactor : 1);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(p.dx, p.dy + h * 0.28), width: w * 0.9, height: h * 0.18),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    final img = CarSpriteCache.get(sprite);
    final dst = Rect.fromCenter(center: Offset(p.dx, p.dy - h * 0.08), width: w, height: h);
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        Paint()..filterQuality = FilterQuality.medium,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(dst, Radius.circular(w * 0.16)),
        Paint()..color = color,
      );
    }
    if (player && controller.nitroActive) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(p.dx, p.dy + h * 0.42), width: w * 0.35, height: h * 0.22),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(p.dx, p.dy + h * 0.42),
            w * 0.22,
            [const Color(0xFFFF9A3C), const Color(0x00FF7A18)],
          ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CityRacePainter oldDelegate) => true;
}
