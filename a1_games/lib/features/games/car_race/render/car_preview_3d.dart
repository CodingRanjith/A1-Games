import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'model_cache.dart';
import 'scene3d_painter.dart';
import '../camera/drive_camera.dart';
import '../car_race_controller.dart';
import '../car_catalog.dart';
import '../vehicle/car_config.dart';

/// Orbiting 3D car viewer for the garage. Loads only the selected GLB.
class CarPreview3d extends StatefulWidget {
  const CarPreview3d({super.key, required this.config});

  final CarConfig config;

  @override
  State<CarPreview3d> createState() => _CarPreview3dState();
}

class _CarPreview3dState extends State<CarPreview3d> with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  final _dummy = CarRaceController(spec: CarCatalog.playerCars.first);
  final _cam = CameraRig(distance: 6.4, height: 2.4, lookHeight: 0.9, lag: 20);

  @override
  void initState() {
    super.initState();
    ModelCache.load(widget.config.modelPath).then((_) {
      if (mounted) setState(() {});
    });
    _tick = AnimationController(vsync: this, duration: const Duration(seconds: 12))
      ..repeat();
  }

  @override
  void didUpdateWidget(covariant CarPreview3d oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.modelPath != widget.config.modelPath) {
      ModelCache.load(widget.config.modelPath).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    _dummy.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tick,
      builder: (context, _) {
        _dummy.playerX = 0;
        _dummy.visualYaw = _tick.value * math.pi * 2;
        _dummy.wheelSpin = _tick.value * 40;
        _cam.eye = Vector3(0, 2.2, -6.2);
        _cam.target = Vector3(0, 0.8, 0);
        return CustomPaint(
          painter: Scene3dPainter(
            controller: _dummy,
            camera: _cam,
            previewMode: true,
            previewCar: widget.config,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
