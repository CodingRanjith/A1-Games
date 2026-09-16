import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../camera/drive_camera.dart';
import '../car_race_controller.dart';
import '../car_sprite_cache.dart';
import '../vehicle/car_config.dart';
import 'model3d.dart';
import 'model_cache.dart';

class Scene3dPainter extends CustomPainter {
  Scene3dPainter({
    required this.controller,
    required this.camera,
    this.previewMode = false,
    this.previewCar,
    this.previewModelPath,
    this.previewTexture,
    this.previewScale = 2.2,
  });

  final CarRaceController controller;
  final CameraRig camera;
  final bool previewMode;
  final CarConfig? previewCar;
  final String? previewModelPath;
  final String? previewTexture;
  final double previewScale;

  static final Vector3 _light = Vector3(0.28, 0.9, 0.35)..normalize();

  @override
  void paint(Canvas canvas, Size size) {
    _paintSky(canvas, size);
    if (!previewMode) {
      _paintDriveWorld(canvas, size);
    }

    if (!previewMode) {
      camera.follow(
        carPos: Vector3(controller.playerX, 0, 0),
        yaw: controller.visualYaw,
        dt: 0.016,
        speed: controller.speed,
        curve: controller.roadCurvature,
        phase: controller.wheelSpin,
        shake: controller.nitroActive ? math.sin(controller.wheelSpin * 4) * 0.08 : 0,
      );
    }

    final view = camera.viewMatrix;
    final proj = camera.projection(size.width / math.max(1, size.height));
    final vp = proj * view;

    if (previewMode) {
      final custom = previewModelPath;
      if (custom != null) {
        _drawAsset(
          canvas,
          size,
          path: custom,
          textureOverride: previewTexture,
          vp: vp,
          x: 0,
          y: 0,
          z: 0,
          yaw: controller.visualYaw,
          scale: previewScale,
        );
        return;
      }
      final cfg = previewCar ?? CarConfigs.byId(controller.spec.id);
      _drawAsset(
        canvas,
        size,
        path: cfg.modelPath,
        vp: vp,
        x: 0,
        y: 0,
        z: 0,
        yaw: controller.visualYaw,
        scale: cfg.modelScale,
        wheelSpin: controller.wheelSpin,
      );
      return;
    }

    final playerPath = CarConfigs.byId(controller.spec.id).modelPath;
    final playerScale = CarConfigs.byId(controller.spec.id).modelScale;
    final playerDrawn = _drawAsset(
      canvas,
      size,
      vp: vp,
      path: playerPath,
      x: controller.playerX,
      y: 0,
      z: 0.2,
      yaw: controller.visualYaw,
      scale: playerScale,
      wheelSpin: controller.wheelSpin,
      steer: controller.steerInput,
    );
    if (!playerDrawn) {
      _drawFallbackCar(canvas, size, vp);
    }

    if (controller.nitroActive) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFFFF7A18).withValues(alpha: 0.07),
      );
    }
    _paintSpeedStreaks(canvas, size);
  }

  void _paintSpeedStreaks(Canvas canvas, Size size) {
    final t = ((controller.speed - 2.2) / 2.8).clamp(0.0, 1.0);
    if (t < 0.08) return;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05 + t * 0.12)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final drift = controller.roadScroll * 18;
    for (var i = 0; i < 10; i++) {
      final x = (i * 97 + drift) % size.width;
      final y = size.height * (0.55 + (i % 5) * 0.08);
      canvas.drawLine(Offset(x, y), Offset(x - 8 - t * 28, y + 18 + t * 22), paint);
    }
  }

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF6EAEDE),
            Color(0xFFB9D7EE),
            Color(0xFFE7D7C4),
            Color(0xFF8FA38A),
          ],
          stops: [0, 0.34, 0.52, 1],
        ).createShader(rect),
    );
  }

  void _paintDriveWorld(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.38;
    final vanishX = w * (0.5 - controller.visualYaw * 0.42 - controller.playerX * 0.015);
    final vanish = Offset(vanishX.clamp(w * 0.28, w * 0.72), horizon);
    final scroll = controller.roadScroll;

    canvas.drawRect(
      Rect.fromLTWH(0, horizon - 70, w, 70),
      Paint()..color = const Color(0xFF9BB0C4).withValues(alpha: 0.55),
    );
    for (var i = 0; i < 16; i++) {
      final x = ((i * 64) - (scroll * 6) % 64) % (w + 70) - 30;
      final bh = 18.0 + (i % 6) * 9;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, horizon - bh, 38, bh), const Radius.circular(2)),
        Paint()..color = Color.lerp(const Color(0xFF7E8C99), const Color(0xFFC4B6A6), (i % 3) / 2)!,
      );
    }

    Offset edge(double u, double side, double extra) {
      final y = horizon + (h - horizon) * u;
      final center = vanish.dx + (w * 0.5 - vanish.dx) * u;
      final spread = 16 + w * 0.70 * u * u;
      return Offset(center + (spread + extra) * side, y);
    }

    final leftWalk = Path()
      ..moveTo(edge(0.02, -1, 0).dx, edge(0.02, -1, 0).dy)
      ..lineTo(edge(1, -1, 0).dx, edge(1, -1, 0).dy)
      ..lineTo(0, h)
      ..lineTo(0, horizon)
      ..close();
    final rightWalk = Path()
      ..moveTo(edge(0.02, 1, 0).dx, edge(0.02, 1, 0).dy)
      ..lineTo(edge(1, 1, 0).dx, edge(1, 1, 0).dy)
      ..lineTo(w, h)
      ..lineTo(w, horizon)
      ..close();
    canvas.drawPath(leftWalk, Paint()..color = const Color(0xFFB7B1A6));
    canvas.drawPath(rightWalk, Paint()..color = const Color(0xFFB7B1A6));

    final road = Path()
      ..moveTo(edge(0.02, -1, 0).dx, edge(0.02, -1, 0).dy)
      ..lineTo(edge(1, -1, 0).dx, edge(1, -1, 0).dy)
      ..lineTo(edge(1, 1, 0).dx, edge(1, 1, 0).dy)
      ..lineTo(edge(0.02, 1, 0).dx, edge(0.02, 1, 0).dy)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF3A4048));
    canvas.drawPath(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5A616A).withValues(alpha: 0.2),
            const Color(0xFF1E2228).withValues(alpha: 0.35),
          ],
        ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)),
    );

    final buildings = [
      const Color(0xFFD7C4AE),
      const Color(0xFF8FA4B8),
      const Color(0xFFC46B4A),
      const Color(0xFFE6E1D6),
      const Color(0xFF6E8494),
    ];
    for (var i = 0; i < 9; i++) {
      final u0 = ((i + (scroll * 0.04) % 1) % 9) / 9;
      final u1 = (u0 + 0.09).clamp(0.0, 1.0);
      if (u1 <= 0.03) continue;
      for (final side in [-1.0, 1.0]) {
        final a = edge(u0, side, 8);
        final b = edge(u1, side, 8);
        final height = (1.15 - u0) * h * 0.34;
        final path = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(b.dx + side * (18 + u1 * 70), b.dy - height * u1)
          ..lineTo(a.dx + side * (10 + u0 * 46), a.dy - height * u0)
          ..close();
        canvas.drawPath(path, Paint()..color = buildings[(i + (side < 0 ? 1 : 0)) % buildings.length]);
        final win = Paint()..color = const Color(0xFFFFF4D2).withValues(alpha: 0.55 + 0.3 * (i % 2));
        final wx = a.dx + side * (14 + u0 * 20);
        final wy = a.dy - height * u0 * 0.45;
        canvas.drawRect(Rect.fromCenter(center: Offset(wx, wy), width: 4 + u0 * 10, height: 3 + u0 * 8), win);
      }
    }

    final dash = (scroll * 0.08) % 1.0;
    for (var i = 0; i < 14; i++) {
      final u = ((i / 14) + dash) % 1.0;
      if (u < 0.04) continue;
      final c = edge(u, 0, 0);
      final len = 4 + u * 28;
      canvas.drawLine(
        Offset(c.dx, c.dy - len),
        Offset(c.dx, c.dy + 2),
        Paint()
          ..color = const Color(0xFFE6D36A)
          ..strokeWidth = 1.5 + u * 5
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final walker in controller.walkers) {
      if (walker.z < 6 || walker.z > 62) continue;
      final u = (1 - walker.z / 68).clamp(0.08, 0.82);
      final side = walker.side.toDouble();
      final p = edge(u, side, 16 + walker.lateral * 4);
      final person = 8 + u * 36;
      final bob = math.sin(walker.phase) * person * 0.06;
      canvas.drawLine(
        Offset(p.dx, p.dy - person * 0.45 + bob),
        Offset(p.dx, p.dy),
        Paint()
          ..color = walker.suit
          ..strokeWidth = math.max(2, person * 0.16)
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(Offset(p.dx, p.dy - person * 0.62 + bob), person * 0.16, Paint()..color = walker.skin);
    }

    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.78), width: w * 0.28, height: 18),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
  }

  bool _drawAsset(
    Canvas canvas,
    Size size, {
    required Matrix4 vp,
    required String path,
    required double x,
    required double y,
    required double z,
    double yaw = 0,
    double scale = 1,
    double wheelSpin = 0,
    double steer = 0,
    String? textureOverride,
  }) {
    final model = ModelCache.peek(path);
    if (model == null) {
      ModelCache.load(path);
      return false;
    }
    final image = ModelCache.image(textureOverride ?? model.textureAsset);
    if (image == null && textureOverride != null) {
      ModelCache.loadImage(textureOverride);
    }
    final modelMatrix = Matrix4.identity()
      ..translateByDouble(x, y, z, 1)
      ..rotateY(yaw)
      ..scaleByDouble(scale, scale, scale, 1);

    for (final part in model.parts) {
      var world = modelMatrix.clone()..multiply(part.nodeMatrix);
      if (part.isWheel) {
        if (part.isFrontWheel && steer.abs() > 0.02) {
          world.rotateY(steer * 0.45);
        }
        world.rotateX(wheelSpin);
      }
      _drawPart(canvas, size, vp, world, part, image);
    }
    return true;
  }

  void _drawPart(
    Canvas canvas,
    Size size,
    Matrix4 vp,
    Matrix4 world,
    MeshPart part,
    ui.Image? image,
  ) {
    final mvp = vp * world;
    final n = part.positions.length ~/ 3;
    if (n < 3 || part.indices.length < 3) return;

    final xy = Float32List(n * 2);
    final uv = Float32List(n * 2);
    final cols = Int32List(n);
    final clipW = Float32List(n);
    final tmp = Vector4.zero();
    final nrm = Vector3.zero();
    final iw = image?.width.toDouble() ?? 1;
    final ih = image?.height.toDouble() ?? 1;

    for (var i = 0; i < n; i++) {
      tmp.setValues(part.positions[i * 3], part.positions[i * 3 + 1], part.positions[i * 3 + 2], 1);
      mvp.transform(tmp);
      final w = tmp.w;
      if (w < 0.08) {
        clipW[i] = -1;
        continue;
      }
      clipW[i] = w;
      final ndcX = tmp.x / w;
      final ndcY = tmp.y / w;
      xy[i * 2] = (ndcX + 1) * 0.5 * size.width;
      xy[i * 2 + 1] = (1 - ndcY) * 0.5 * size.height;
      uv[i * 2] = part.uvs.length > i * 2 + 1 ? part.uvs[i * 2] * iw : 0;
      uv[i * 2 + 1] = part.uvs.length > i * 2 + 1 ? part.uvs[i * 2 + 1] * ih : 0;
      tmp.setValues(part.normals[i * 3], part.normals[i * 3 + 1], part.normals[i * 3 + 2], 0);
      world.transform(tmp);
      nrm.setValues(tmp.x, tmp.y, tmp.z);
      if (nrm.length2 > 0.0001) nrm.normalize();
      final lit = (0.38 + 0.62 * math.max(0.0, nrm.dot(_light))).clamp(0.25, 1.0);
      final c = (lit * 255).toInt().clamp(0, 255);
      cols[i] = (0xFF << 24) | (c << 16) | (c << 8) | c;
    }

    final kept = <int>[];
    final src = part.indices;
    for (var i = 0; i + 2 < src.length; i += 3) {
      final a = src[i];
      final b = src[i + 1];
      final c = src[i + 2];
      if (a >= n || b >= n || c >= n) continue;
      if (clipW[a] < 0 || clipW[b] < 0 || clipW[c] < 0) continue;
      final minX = math.min(xy[a * 2], math.min(xy[b * 2], xy[c * 2]));
      final maxX = math.max(xy[a * 2], math.max(xy[b * 2], xy[c * 2]));
      final minY = math.min(xy[a * 2 + 1], math.min(xy[b * 2 + 1], xy[c * 2 + 1]));
      final maxY = math.max(xy[a * 2 + 1], math.max(xy[b * 2 + 1], xy[c * 2 + 1]));
      if (maxX - minX > size.width * 1.4 || maxY - minY > size.height * 1.4) continue;
      kept.add(a);
      kept.add(b);
      kept.add(c);
    }
    if (kept.length < 3) return;

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.low;
    if (image != null) {
      paint.shader = ui.ImageShader(
        image,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
      );
    } else {
      paint.color = const Color(0xFF7A8B78);
    }

    try {
      canvas.drawVertices(
        ui.Vertices.raw(
          ui.VertexMode.triangles,
          xy,
          textureCoordinates: image != null ? uv : null,
          colors: cols,
          indices: Uint16List.fromList(kept),
        ),
        BlendMode.modulate,
        paint,
      );
    } catch (_) {
      // Skip a malformed primitive rather than crashing a frame.
    }
  }

  void _drawFallbackCar(Canvas canvas, Size size, Matrix4 vp) {
    final img = CarSpriteCache.get(controller.playerSprite);
    final p = _project(vp, Vector3(controller.playerX, 0.6, 0.4), size);
    if (p == null) return;
    final rect = Rect.fromCenter(center: p, width: 72, height: 110);
    if (img != null) {
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        rect,
        Paint()..filterQuality = FilterQuality.low,
      );
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = controller.spec.color,
      );
    }
  }

  Offset? _project(Matrix4 vp, Vector3 p, Size size) {
    final v = Vector4(p.x, p.y, p.z, 1);
    vp.transform(v);
    if (v.w.abs() < 0.001) return null;
    return Offset((v.x / v.w + 1) * 0.5 * size.width, (1 - v.y / v.w) * 0.5 * size.height);
  }

  @override
  bool shouldRepaint(covariant Scene3dPainter oldDelegate) => true;
}
