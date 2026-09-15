import 'package:flutter/material.dart';

/// Selectable player cars + traffic sprites. Original CC0 assets.
class RaceCarSpec {
  const RaceCarSpec({
    required this.id,
    required this.name,
    required this.tagline,
    required this.asset,
    required this.color,
    required this.cost,
    required this.accel,
    required this.brakeForce,
    required this.handling,
    required this.nitroBoost,
    required this.cruiseCap,
    required this.widthFactor,
  });

  final String id;
  final String name;
  final String tagline;
  final String asset;
  final Color color;
  final int cost;
  final double accel;
  final double brakeForce;
  final double handling;
  final double nitroBoost;
  final double cruiseCap;
  final double widthFactor;
}

class CarCatalog {
  CarCatalog._();

  static const String emberGt = 'assets/images/cars/ember_gt.png';
  static const String nightline = 'assets/images/cars/nightline.png';
  static const String voltX = 'assets/images/cars/volt_x.png';
  static const String titan = 'assets/images/cars/titan.png';
  static const String phantomRs = 'assets/images/cars/phantom_rs.png';

  static const String trafficBlue = 'assets/images/cars/traffic_blue.png';
  static const String trafficSilver = 'assets/images/cars/traffic_silver.png';
  static const String trafficTaxi = 'assets/images/cars/traffic_taxi.png';
  static const String trafficVan = 'assets/images/cars/traffic_van.png';
  static const String trafficHatch = 'assets/images/cars/traffic_hatch.png';

  static const String tree = 'assets/images/environment/tree.png';
  static const String palm = 'assets/images/environment/palm.png';
  static const String streetLight = 'assets/images/environment/street_light.png';
  static const String barrier = 'assets/images/environment/barrier.png';
  static const String trafficSign = 'assets/images/environment/traffic_sign.png';
  static const String cone = 'assets/images/environment/cone.png';
  static const String finishBanner = 'assets/images/environment/finish_banner.png';
  static const String asphalt = 'assets/images/roads/asphalt.png';
  static const String speedoRing = 'assets/images/ui/speedo_ring.png';

  static const String skylineTokyo = 'assets/images/city/skyline_tokyo.png';
  static const String skylineDubai = 'assets/images/city/skyline_dubai.png';
  static const String skylineNyc = 'assets/images/city/skyline_nyc.png';
  static const String skylineMumbai = 'assets/images/city/skyline_mumbai.png';
  static const String skylineParis = 'assets/images/city/skyline_paris.png';

  static const List<RaceCarSpec> playerCars = [
    RaceCarSpec(
      id: 'ember_gt',
      name: 'Ember GT',
      tagline: 'Balanced night racer',
      asset: emberGt,
      color: Color(0xFFD62830),
      cost: 0,
      accel: 0.55,
      brakeForce: 0.48,
      handling: 1.0,
      nitroBoost: 1.35,
      cruiseCap: 7.0,
      widthFactor: 1.0,
    ),
    RaceCarSpec(
      id: 'nightline',
      name: 'Nightline',
      tagline: 'Precise city handling',
      asset: nightline,
      color: Color(0xFF12203A),
      cost: 40,
      accel: 0.42,
      brakeForce: 0.55,
      handling: 1.22,
      nitroBoost: 1.15,
      cruiseCap: 6.8,
      widthFactor: 0.95,
    ),
    RaceCarSpec(
      id: 'volt_x',
      name: 'Volt X',
      tagline: 'Instant electric boost',
      asset: voltX,
      color: Color(0xFF14AABC),
      cost: 90,
      accel: 0.72,
      brakeForce: 0.50,
      handling: 1.08,
      nitroBoost: 1.7,
      cruiseCap: 7.4,
      widthFactor: 1.0,
    ),
    RaceCarSpec(
      id: 'titan',
      name: 'Titan',
      tagline: 'Heavy highway cruiser',
      asset: titan,
      color: Color(0xFFD26E28),
      cost: 140,
      accel: 0.38,
      brakeForce: 0.40,
      handling: 0.82,
      nitroBoost: 1.2,
      cruiseCap: 7.8,
      widthFactor: 1.18,
    ),
    RaceCarSpec(
      id: 'phantom_rs',
      name: 'Phantom RS',
      tagline: 'Top-tier street super',
      asset: phantomRs,
      color: Color(0xFFECEEF2),
      cost: 280,
      accel: 0.85,
      brakeForce: 0.62,
      handling: 1.18,
      nitroBoost: 1.85,
      cruiseCap: 8.2,
      widthFactor: 1.05,
    ),
  ];

  static const List<String> trafficSprites = [
    trafficBlue,
    trafficSilver,
    trafficTaxi,
    trafficVan,
    trafficHatch,
  ];

  static const List<String> allAssetPaths = [
    emberGt,
    nightline,
    voltX,
    titan,
    phantomRs,
    trafficBlue,
    trafficSilver,
    trafficTaxi,
    trafficVan,
    trafficHatch,
    tree,
    palm,
    streetLight,
    barrier,
    trafficSign,
    cone,
    finishBanner,
    asphalt,
    speedoRing,
    skylineTokyo,
    skylineDubai,
    skylineNyc,
    skylineMumbai,
    skylineParis,
  ];

  static RaceCarSpec byId(String id) {
    return playerCars.firstWhere(
      (c) => c.id == id,
      orElse: () => playerCars.first,
    );
  }
}
