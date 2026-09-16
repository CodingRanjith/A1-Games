import 'dart:math' as math;

import 'package:vector_math/vector_math_64.dart';

/// Third-person chase rig. Speed opens the lens, steering leans the frame,
/// and route curvature rolls the camera the way a drive cam should.
class CameraRig {
  CameraRig({
    this.distance = 7.4,
    this.height = 2.85,
    this.lookHeight = 1.15,
    this.lag = 6.8,
  })  : baseDistance = distance,
        baseHeight = height;

  double distance;
  double height;
  double lookHeight;
  double lag;
  double baseDistance;
  double baseHeight;
  double roll = 0;
  double fov = 56;

  Vector3 eye = Vector3(0, 2.85, -7.4);
  Vector3 target = Vector3(0, 1.15, 6);

  static final presets = [
    CameraRig(distance: 6.8, height: 2.4, lookHeight: 0.85, lag: 9),
    CameraRig(distance: 9.6, height: 3.5, lookHeight: 0.95, lag: 6.2),
    CameraRig(distance: 13.5, height: 5.2, lookHeight: 1.2, lag: 4.2),
  ];

  void copyFrom(CameraRig other) {
    baseDistance = other.distance;
    baseHeight = other.height;
    lookHeight = other.lookHeight;
    lag = other.lag;
  }

  void follow({
    required Vector3 carPos,
    required double yaw,
    required double dt,
    double speed = 2.4,
    double curve = 0,
    double phase = 0,
    double shake = 0,
  }) {
    final safeDt = dt.clamp(0.001, 0.05);
    final speedN = ((speed - 1.1) / 3.6).clamp(0.0, 1.0);
    final desiredDist = baseDistance * (0.9 + speedN * 0.34);
    final desiredHeight = baseHeight * (0.94 + speedN * 0.16);
    final lookAhead = 8.5 + speedN * 8;
    final bob = math.sin(phase * 2.1) * (0.015 + speedN * 0.045);

    final backX = -math.sin(yaw) * desiredDist * 0.42;
    final backZ = -math.cos(yaw) * desiredDist;
    final desiredEye = Vector3(
      carPos.x + backX,
      carPos.y + desiredHeight + bob + shake,
      carPos.z + backZ,
    );
    final desiredTarget = Vector3(
      carPos.x + math.sin(yaw) * 1.6,
      carPos.y + lookHeight,
      carPos.z + lookAhead,
    );
    final k = 1 - math.exp(-lag * safeDt);
    eye = Vector3(
      eye.x + (desiredEye.x - eye.x) * k,
      eye.y + (desiredEye.y - eye.y) * k,
      eye.z + (desiredEye.z - eye.z) * k,
    );
    target = Vector3(
      target.x + (desiredTarget.x - target.x) * k,
      target.y + (desiredTarget.y - target.y) * k,
      target.z + (desiredTarget.z - target.z) * k,
    );

    final lean = -yaw * 0.42 - curve * 42;
    roll += (lean - roll) * (1 - math.exp(-7 * safeDt));
    fov += ((52 + speedN * 16) - fov) * (1 - math.exp(-3.5 * safeDt));
    distance = desiredDist;
    height = desiredHeight;
  }

  Matrix4 get viewMatrix {
    final m = makeViewMatrix(eye, target, Vector3(0, 1, 0));
    return m..rotateZ(roll);
  }

  Matrix4 projection(double aspect) =>
      makePerspectiveMatrix(radians(fov.clamp(46, 74)), aspect, 0.28, 280);
}
