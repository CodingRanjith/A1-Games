/// Add another playable car by appending a [CarConfig] and a GLB under assets/models/cars/.
class CarConfig {
  const CarConfig({
    required this.id,
    required this.name,
    required this.modelPath,
    required this.maxSpeed,
    required this.acceleration,
    required this.braking,
    required this.steering,
    this.modelScale = 2.2,
    this.colliderWidth = 1.9,
    this.colliderLength = 4.2,
    this.previewImage,
  });

  final String id;
  final String name;
  final String modelPath;
  final String? previewImage;
  final double maxSpeed;
  final double acceleration;
  final double braking;
  final double steering;
  final double modelScale;
  final double colliderWidth;
  final double colliderLength;
}

class CarConfigs {
  CarConfigs._();

  static const emberGt = CarConfig(
    id: 'ember_gt',
    name: 'Sport Sedan',
    modelPath: 'assets/models/cars/sedan-sports.glb',
    previewImage: 'assets/images/cars/ember_gt.png',
    maxSpeed: 7.0,
    acceleration: 0.55,
    braking: 0.48,
    steering: 1.0,
    modelScale: 1.65,
  );

  static const nightline = CarConfig(
    id: 'nightline',
    name: 'City Hatch',
    modelPath: 'assets/models/cars/hatchback-sports.glb',
    previewImage: 'assets/images/cars/nightline.png',
    maxSpeed: 6.8,
    acceleration: 0.42,
    braking: 0.55,
    steering: 1.22,
    modelScale: 2.1,
    colliderWidth: 1.8,
  );

  static const voltX = CarConfig(
    id: 'volt_x',
    name: 'Track Coupe',
    modelPath: 'assets/models/cars/race.glb',
    previewImage: 'assets/images/cars/volt_x.png',
    maxSpeed: 7.4,
    acceleration: 0.72,
    braking: 0.50,
    steering: 1.08,
    modelScale: 2.15,
  );

  static const titan = CarConfig(
    id: 'titan',
    name: 'Hauler Van',
    modelPath: 'assets/models/cars/van.glb',
    previewImage: 'assets/images/cars/titan.png',
    maxSpeed: 7.8,
    acceleration: 0.38,
    braking: 0.40,
    steering: 0.82,
    modelScale: 2.35,
    colliderWidth: 2.2,
    colliderLength: 5.0,
  );

  static const phantomRs = CarConfig(
    id: 'phantom_rs',
    name: 'Aero Racer',
    modelPath: 'assets/models/cars/race-future.glb',
    previewImage: 'assets/images/cars/phantom_rs.png',
    maxSpeed: 8.2,
    acceleration: 0.85,
    braking: 0.62,
    steering: 1.18,
    modelScale: 2.2,
  );

  static const truck = CarConfig(
    id: 'truck',
    name: 'Truck',
    modelPath: 'assets/models/traffic/truck.glb',
    previewImage: 'assets/images/cars/truck.png',
    maxSpeed: 5.6,
    acceleration: 0.32,
    braking: 0.36,
    steering: 0.72,
    modelScale: 2.6,
    colliderWidth: 2.4,
    colliderLength: 6.2,
  );

  static const bus = CarConfig(
    id: 'bus',
    name: 'Bus',
    modelPath: 'assets/models/cars/van.glb',
    previewImage: 'assets/images/cars/bus.png',
    maxSpeed: 5.2,
    acceleration: 0.3,
    braking: 0.34,
    steering: 0.68,
    modelScale: 2.8,
    colliderWidth: 2.5,
    colliderLength: 7.0,
  );

  static const List<CarConfig> all = [
    emberGt,
    nightline,
    voltX,
    titan,
    phantomRs,
    truck,
    bus,
  ];

  static const List<String> trafficModels = [
    'assets/models/traffic/sedan.glb',
    'assets/models/traffic/taxi.glb',
    'assets/models/traffic/suv.glb',
    'assets/models/traffic/truck.glb',
    'assets/models/traffic/delivery.glb',
  ];

  static CarConfig byId(String id) {
    return all.firstWhere((c) => c.id == id, orElse: () => emberGt);
  }
}
