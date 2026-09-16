import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import '../games/car_race/camera/drive_camera.dart';
import '../games/car_race/car_catalog.dart';
import '../games/car_race/car_race_controller.dart';
import '../games/car_race/characters/character_models.dart';
import '../games/car_race/render/model_cache.dart';
import '../games/car_race/render/scene3d_painter.dart';
import 'driver_catalog.dart';

/// Orbiting 3D character. Drag to inspect every side.
class CharacterPreview3d extends StatefulWidget {
  const CharacterPreview3d({super.key, required this.driver});

  final DriverSpec driver;

  @override
  State<CharacterPreview3d> createState() => _CharacterPreview3dState();
}

class _CharacterPreview3dState extends State<CharacterPreview3d>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  )..repeat();
  final _dummy = CarRaceController(spec: CarCatalog.playerCars.first);
  final _cam = CameraRig(distance: 4.6, height: 1.7, lookHeight: 1.15, lag: 20);
  double _yaw = 0.4;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ModelCache.load(CharacterModels.idle);
    await ModelCache.loadImage(CharacterModels.textureFor(widget.driver.id));
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant CharacterPreview3d oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driver.id != widget.driver.id) {
      ModelCache.loadImage(CharacterModels.textureFor(widget.driver.id)).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _dummy.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (_) => _dragging = true,
      onHorizontalDragUpdate: (d) => setState(() => _yaw += d.delta.dx * 0.012),
      onHorizontalDragEnd: (_) => _dragging = false,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) {
          final yaw = _dragging ? _yaw : _yaw + _spin.value * math.pi * 2;
          _dummy.visualYaw = yaw;
          _cam.eye = Vector3(0, 1.8, -4.4);
          _cam.target = Vector3(0, 1.15, 0);
          return CustomPaint(
            painter: Scene3dPainter(
              controller: _dummy,
              camera: _cam,
              previewMode: true,
              previewModelPath: CharacterModels.idle,
              previewTexture: CharacterModels.textureFor(widget.driver.id),
              previewScale: 2.15,
            ),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
