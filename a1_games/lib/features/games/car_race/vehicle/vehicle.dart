import 'package:vector_math/vector_math_64.dart';

import 'car_config.dart';

/// Runtime vehicle: pose, speed, wheels, collision size.
class Vehicle {
  Vehicle({required this.config})
      : position = Vector3.zero(),
        yaw = 0,
        pitch = 0,
        speed = 0,
        wheelSpin = 0,
        steerAngle = 0;

  final CarConfig config;
  Vector3 position;
  double yaw;
  double pitch;
  double speed;
  double wheelSpin;
  double steerAngle;

  double get maxSpeed => config.maxSpeed;
  double get colliderWidth => config.colliderWidth;
  double get colliderLength => config.colliderLength;

  void applyControls({
    required double dt,
    required double steerInput,
    required bool throttle,
    required bool brake,
    required double cruise,
  }) {
    steerAngle += (steerInput - steerAngle) * (10 * dt);
    yaw += (steerInput * 0.38 - yaw) * (8 * dt);
    pitch += (((throttle ? 0.04 : 0) + (brake ? -0.05 : 0)) - pitch) * (6 * dt);
    speed = cruise;
    wheelSpin += speed * 4.8 * dt;
    if (wheelSpin > 1000) wheelSpin -= 1000;
  }

  bool overlaps(Vehicle other) {
    final dx = (position.x - other.position.x).abs();
    final dz = (position.z - other.position.z).abs();
    return dx < (colliderWidth + other.colliderWidth) * 0.45 &&
        dz < (colliderLength + other.colliderLength) * 0.35;
  }
}
