import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:a1_games/app/theme/app_colors.dart';

import 'car_catalog.dart';
import 'car_race_controller.dart';
import 'car_sprite_cache.dart';

class CityRacePainter extends CustomPainter {
  CityRacePainter({required this.controller});

  final CarRaceController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final city = controller.city;
    _paintSky(canvas, size, city);
    _paintSkyline(canvas, size, city);
    _paintRoad(canvas, size);
    if (controller.showBridge) _paintBridge(canvas, size, city);
    _paintRoadside(canvas, size);
    if (controller.showStartGantry || controller.showFinishGantry) {
      _paintGantry(canvas, size, start: controller.showStartGantry);
    }
    _paintTraffic(canvas, size);
    _paintPlayer(canvas, size);
    if (controller.nitroActive) _paintNitroWash(canvas, size);
    if (controller.nearMissFlash) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.08),
      );
    }
  }

  void _paintSky(Canvas canvas, Size size, CityTheme city) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: city.skyColors,
        ).createShader(rect),
    );

    final orb = Offset(size.width * 0.78, size.height * 0.12);
    canvas.drawCircle(
      orb,
      28,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.9),
            city.neonA.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: orb, radius: 48)),
    );
  }

  void _paintSkyline(Canvas canvas, Size size, CityTheme city) {
    final horizon = size.height * 0.38;
    final scroll = controller.cityScroll * size.width * 1.4;
    final skyline = CarSpriteCache.get(city.skylineAsset);
    if (skyline != null) {
      final h = size.height * 0.34;
      final w = size.width * 1.15;
      final y = horizon - h * 0.82;
      for (final extra in [0.0, w]) {
        final dx = -((scroll * 0.45) % w) + extra;
        canvas.drawImageRect(
          skyline,
          Rect.fromLTWH(0, 0, skyline.width.toDouble(), skyline.height.toDouble()),
          Rect.fromLTWH(dx, y, w, h),
          Paint()..filterQuality = FilterQuality.low,
        );
      }
    }

    final rng = math.Random(CityTheme.values.indexOf(city) * 97 + 13);
    canvas.drawRect(
      Rect.fromLTWH(0, horizon - 40, size.width, 80),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            city.neonB.withValues(alpha: 0.12),
            Colors.black.withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(0, horizon - 40, size.width, 80)),
    );

    for (var layer = 0; layer < 2; layer++) {
      final yBase = horizon - layer * 18;
      var x = -((scroll * (0.35 + layer * 0.25)) % 90);
      while (x < size.width + 40) {
        final w = 18.0 + rng.nextInt(28);
        final h = 30.0 + rng.nextInt(70) + layer * 10;
        final building = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, yBase - h, w, h),
          const Radius.circular(2),
        );
        canvas.drawRRect(
          building,
          Paint()
            ..color = Color.lerp(
              const Color(0xFF0E1420),
              city.neonB,
              0.08 + layer * 0.05,
            )!,
        );
        final winPaint = Paint()
          ..color = (rng.nextBool() ? city.neonA : city.neonB)
              .withValues(alpha: 0.35 + rng.nextDouble() * 0.45);
        for (var wy = yBase - h + 6; wy < yBase - 8; wy += 10) {
          for (var wx = x + 4; wx < x + w - 4; wx += 8) {
            if (rng.nextDouble() > 0.35) {
              canvas.drawRect(Rect.fromLTWH(wx, wy, 3, 4), winPaint);
            }
          }
        }
        x += w + 6 + rng.nextInt(10);
      }
    }
  }

  void _paintRoad(Canvas canvas, Size size) {
    final top = size.height * 0.36;
    final road = Path()
      ..moveTo(size.width * 0.28, top)
      ..lineTo(size.width * 0.72, top)
      ..lineTo(size.width * 0.98, size.height)
      ..lineTo(size.width * 0.02, size.height)
      ..close();

    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFF2A2A32),
            Color(0xFF1A1A22),
            Color(0xFF121218),
          ],
        ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
    );

    // Shoulders
    final leftShoulder = Path()
      ..moveTo(size.width * 0.22, top)
      ..lineTo(size.width * 0.28, top)
      ..lineTo(size.width * 0.02, size.height)
      ..lineTo(size.width * -0.08, size.height)
      ..close();
    final rightShoulder = Path()
      ..moveTo(size.width * 0.72, top)
      ..lineTo(size.width * 0.78, top)
      ..lineTo(size.width * 1.08, size.height)
      ..lineTo(size.width * 0.98, size.height)
      ..close();
    final shoulderPaint = Paint()..color = const Color(0xFF3A3A42);
    canvas.drawPath(leftShoulder, shoulderPaint);
    canvas.drawPath(rightShoulder, shoulderPaint);

    final edge = Paint()
      ..color = const Color(0xFFFFD166)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width * 0.28, top), Offset(size.width * 0.02, size.height), edge);
    canvas.drawLine(Offset(size.width * 0.72, top), Offset(size.width * 0.98, size.height), edge);

    final scroll = controller.roadScroll;
    for (final laneT in [0.33, 0.5, 0.67]) {
      for (var i = 0; i < 12; i++) {
        final t = ((i / 12) + scroll) % 1.0;
        final y = ui.lerpDouble(top, size.height, t)!;
        final perspective = ui.lerpDouble(0.28, 1.0, t)!;
        final cx = size.width * laneT;
        final x = size.width * 0.5 + (cx - size.width * 0.5) * perspective * 1.65;
        final dashH = 10.0 * perspective;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x, y), width: 4 * perspective, height: dashH),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      }
    }
  }

  void _paintBridge(Canvas canvas, Size size, CityTheme city) {
    final y = size.height * 0.48;
    canvas.drawRect(
      Rect.fromLTWH(0, y, size.width, 18),
      Paint()..color = const Color(0xFF1C2430).withValues(alpha: 0.92),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, y - 36, size.width, 10),
      Paint()..color = city.neonB.withValues(alpha: 0.35),
    );
    for (final x in [size.width * 0.12, size.width * 0.88]) {
      canvas.drawRect(
        Rect.fromLTWH(x - 6, y - 36, 12, 90),
        Paint()..color = const Color(0xFF2A3340),
      );
    }
  }

  Offset _lanePoint(Size size, double lane, double yT) {
    final top = size.height * 0.36;
    final y = ui.lerpDouble(top, size.height, yT.clamp(0.0, 1.0))!;
    final laneCenter = (lane + 0.5) / CarRaceController.laneCount;
    final left = ui.lerpDouble(size.width * 0.28, size.width * 0.02, yT)!;
    final right = ui.lerpDouble(size.width * 0.72, size.width * 0.98, yT)!;
    final x = left + (right - left) * laneCenter;
    return Offset(x, y);
  }

  Offset _shoulderPoint(Size size, bool left, double yT) {
    final top = size.height * 0.36;
    final y = ui.lerpDouble(top, size.height, yT.clamp(0.0, 1.0))!;
    final roadL = ui.lerpDouble(size.width * 0.28, size.width * 0.02, yT)!;
    final roadR = ui.lerpDouble(size.width * 0.72, size.width * 0.98, yT)!;
    final spread = ui.lerpDouble(18, 52, yT.clamp(0.0, 1.0))!;
    final x = left ? roadL - spread : roadR + spread;
    return Offset(x, y);
  }

  void _paintRoadside(Canvas canvas, Size size) {
    for (final prop in controller.props) {
      final p = _shoulderPoint(size, prop.left, prop.y);
      final scale = ui.lerpDouble(0.28, 1.05, prop.y.clamp(0.0, 1.0))!;
      final asset = switch (prop.kind) {
        RoadsideKind.tree => CarCatalog.tree,
        RoadsideKind.palm => CarCatalog.palm,
        RoadsideKind.light => CarCatalog.streetLight,
        RoadsideKind.barrier => CarCatalog.barrier,
        RoadsideKind.sign => CarCatalog.trafficSign,
        RoadsideKind.cone => CarCatalog.cone,
      };
      final img = CarSpriteCache.get(asset);
      if (img != null) {
        final h = (prop.kind == RoadsideKind.barrier || prop.kind == RoadsideKind.cone)
            ? 28 * scale
            : 70 * scale;
        final w = h * (img.width / img.height);
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
          Rect.fromCenter(center: p, width: w, height: h),
          Paint()..filterQuality = FilterQuality.low,
        );
      }
    }
  }

  void _paintGantry(Canvas canvas, Size size, {required bool start}) {
    final yT = start ? 0.08 : 0.12;
    final left = _shoulderPoint(size, true, yT);
    final right = _shoulderPoint(size, false, yT);
    final y = left.dy;
    canvas.drawLine(
      Offset(left.dx, y),
      Offset(right.dx, y),
      Paint()
        ..color = const Color(0xFF2A3340)
        ..strokeWidth = 8,
    );
    final banner = CarSpriteCache.get(CarCatalog.finishBanner);
    final rect = Rect.fromLTRB(left.dx, y - 18, right.dx, y + 6);
    if (banner != null) {
      canvas.drawImageRect(
        banner,
        Rect.fromLTWH(0, 0, banner.width.toDouble(), banner.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.low,
      );
    } else {
      canvas.drawRect(rect, Paint()..color = Colors.black);
    }
  }

  void _paintTraffic(Canvas canvas, Size size) {
    for (final car in controller.traffic) {
      final p = _lanePoint(size, car.lane.toDouble(), car.y);
      final scale = ui.lerpDouble(0.35, 1.15, car.y.clamp(0.0, 1.0))!;
      _drawVehicle(
        canvas,
        p,
        scale,
        car.color,
        sprite: car.sprite,
        headlights: false,
      );
    }
  }

  void _paintPlayer(Canvas canvas, Size size) {
    final p = _lanePoint(size, controller.playerLaneAnim, 0.78);
    _drawVehicle(
      canvas,
      p,
      1.22,
      controller.spec.color,
      sprite: controller.playerSprite,
      headlights: true,
    );
  }

  void _drawVehicle(
    Canvas canvas,
    Offset center,
    double scale,
    Color color, {
    required String sprite,
    required bool headlights,
  }) {
    final w = 38 * scale;
    final h = 64 * scale;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + h * 0.42),
        width: w * 0.9,
        height: 10 * scale,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );

    final img = CarSpriteCache.get(sprite);
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        Rect.fromCenter(center: center, width: w, height: h),
        Paint()..filterQuality = FilterQuality.low,
      );
    } else {
      _drawFallbackCar(canvas, center, scale, color);
    }

    if (headlights) {
      final light = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55),
            const Color(0xFFFFE066).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(center.dx, center.dy - h * 0.55),
          radius: 44 * scale,
        ));
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - h * 0.85),
          width: w * 1.6,
          height: h * 0.9,
        ),
        light,
      );
    }
  }

  void _drawFallbackCar(Canvas canvas, Offset center, double scale, Color color) {
    final w = 34 * scale;
    final h = 56 * scale;
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: w, height: h),
      Radius.circular(8 * scale),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
        ).createShader(body.outerRect),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - h * 0.08),
          width: w * 0.62,
          height: h * 0.28,
        ),
        Radius.circular(4 * scale),
      ),
      Paint()..color = const Color(0xFF89C2D9).withValues(alpha: 0.85),
    );
  }

  void _paintNitroWash(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.gameCarRace.withValues(alpha: 0.06),
    );
    final p = _lanePoint(size, controller.playerLaneAnim, 0.78);
    for (var i = 0; i < 8; i++) {
      final y = p.dy + 30 + i * 10.0;
      canvas.drawLine(
        Offset(p.dx - 10, y),
        Offset(p.dx - 6, y + 16),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(p.dx + 10, y),
        Offset(p.dx + 6, y + 16),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CityRacePainter oldDelegate) => true;
}
