import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'car_catalog.dart';
import 'chennai_route.dart';
import 'camera/drive_camera.dart';
import 'vehicle/car_config.dart';

class SidewalkWalker {
  SidewalkWalker({
    required this.id,
    required this.side,
    required this.x,
    required this.z,
    required this.suit,
    required this.hair,
    required this.skin,
  });

  final int id;
  final int side;
  double x;
  double z;
  double phase = 0;
  double lateral = 0;
  double lateralDir = 1;
  final Color suit;
  final Color hair;
  final Color skin;
}

class TrafficCar {
  TrafficCar({
    required this.id,
    required this.lane,
    required this.x,
    required this.z,
    required this.color,
    required this.speedFactor,
    required this.sprite,
    required this.modelPath,
  });

  final int id;
  int lane;
  double x;
  double z;
  final Color color;
  final double speedFactor;
  final String sprite;
  final String modelPath;
}

class CarRaceController extends ChangeNotifier {
  CarRaceController({
    required this.spec,
    this.engineLevel = 0,
    this.nitroLevel = 0,
    this.fromIndex = 0,
    int? toIndex,
    RaceMap? map,
  })  : route = map ?? RaceMaps.chennai,
        toIndex = toIndex ?? (map ?? RaceMaps.chennai).waypoints.length - 1,
        navHint = (map ?? RaceMaps.chennai).hintAt(0),
        endAlong = (map ?? RaceMaps.chennai).raceMeters;

  static const int laneCount = 4;
  static const int fieldSize = 8;
  static const double laneWidthM = 3.5;

  final RaceCarSpec spec;
  final int engineLevel;
  final int nitroLevel;
  final RaceMap route;
  final int fromIndex;
  final int toIndex;

  final Random _random = Random();
  final List<TrafficCar> traffic = [];
  final List<SidewalkWalker> walkers = [];

  int playerLane = 1;
  double playerLaneAnim = 1;
  double playerX = 0;
  double steerInput = 0;
  double visualYaw = 0;
  double wheelSpin = 0;
  int cameraPreset = 1;
  double roadScroll = 0;
  double speed = 2.4;
  double peakSpeed = 2.4;
  double alongMeters = 0;
  double worldX = 0;
  double worldY = 0;
  double heading = 0;
  double displayHeading = 0;
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int coins = 0;
  int carsPassed = 0;
  bool isRunning = false;
  bool isPaused = false;
  bool isGameOver = false;
  bool isFinished = false;
  bool nearMissFlash = false;
  bool throttleHeld = false;
  bool brakeHeld = false;
  bool nitroActive = false;
  double nitroFuel = 1;
  double _nitroLeft = 0;
  NavHint navHint;

  bool satelliteView = false;
  String driverId = 'ace';
  Color driverSuit = const Color(0xFFE63946);
  Color driverHair = const Color(0xFF1B1B1B);
  Color driverSkin = const Color(0xFFE0B48A);
  double startAlong = 0;
  double endAlong;

  Timer? _tick;
  int _nextId = 0;
  double _spawnCooldown = 0;
  DateTime? _startedAt;

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  double get speedKmh => (speed * 42).clamp(40, 160);

  double get peakKmh => (peakSpeed * 42).clamp(40, 160);

  double get distanceKm => ((alongMeters - startAlong) / 1000).clamp(0, 999);

  double get remainingKm => ((endAlong - alongMeters) / 1000).clamp(0, 999);

  double get tripKm => ((endAlong - startAlong) / 1000).clamp(0.1, 999);

  String get fromName => route.waypoints[fromIndex.clamp(0, route.waypoints.length - 1)].place;

  String get toName => route.waypoints[toIndex.clamp(0, route.waypoints.length - 1)].place;

  GeoPoint get carGeo => route.geoFromMeters(worldX, worldY);

  String get etaLabel {
    final kmh = speedKmh.clamp(28, 160).toDouble();
    return route.etaLabel(remainingKm, kmh: kmh);
  }

  double get raceProgress {
    final span = (endAlong - startAlong).clamp(1.0, route.raceMeters).toDouble();
    return ((alongMeters - startAlong) / span).clamp(0.0, 1.0);
  }

  String get currentPlace => route.placeAt(alongMeters);

  String get currentRoad => route.roadAt(alongMeters);

  /// Heading change per meter, used to bend the visible road with the map.
  double get roadCurvature {
    final ahead = (alongMeters + 90).clamp(startAlong, endAlong);
    final now = route.sampleAt(alongMeters);
    final next = route.sampleAt(ahead);
    final span = max(24.0, ahead - alongMeters);
    return _wrap(next.heading - now.heading) / span;
  }

  List<NavHint> get upcomingTurns =>
      route.upcoming(alongMeters, untilAlong: endAlong);

  String get playerSprite => spec.asset;

  int get racePosition => (fieldSize - carsPassed).clamp(1, fieldSize);

  void start() {
    disposeController();
    isRunning = true;
    isPaused = false;
    isGameOver = false;
    isFinished = false;
    playerLane = 1;
    playerLaneAnim = 1;
    playerX = laneToX(1);
    steerInput = 0;
    visualYaw = 0;
    wheelSpin = 0;
    roadScroll = 0;
    speed = 2.4;
    peakSpeed = 2.4;
    final lo = route.raceAlongForWaypoint(fromIndex);
    final hi = route.raceAlongForWaypoint(toIndex);
    startAlong = min(lo, hi);
    endAlong = max(lo, hi);
    if (endAlong - startAlong < 400) {
      startAlong = 0;
      endAlong = route.raceMeters;
    }
    alongMeters = startAlong;
    score = 0;
    combo = 0;
    maxCombo = 0;
    coins = 0;
    carsPassed = 0;
    traffic.clear();
    walkers.clear();
    throttleHeld = false;
    brakeHeld = false;
    nitroActive = false;
    nitroFuel = 1;
    _nitroLeft = 0;
    _spawnCooldown = 0.5;
    _startedAt = DateTime.now();
    nearMissFlash = false;
    _snapToRoute();
    displayHeading = heading;
    navHint = route.hintAt(alongMeters, untilAlong: endAlong);

    _tick = Timer.periodic(const Duration(milliseconds: 16), (_) => _update(0.016));
    notifyListeners();
  }

  void pause() {
    if (!isRunning || isGameOver) return;
    isPaused = true;
    throttleHeld = false;
    brakeHeld = false;
    steerInput = 0;
    notifyListeners();
  }

  void resume() {
    if (!isPaused || isGameOver) return;
    isPaused = false;
    notifyListeners();
  }

  void moveLeft() {
    if (!isRunning || isPaused || isGameOver) return;
    if (playerLane > 0) {
      playerLane -= 1;
      notifyListeners();
    }
  }

  void moveRight() {
    if (!isRunning || isPaused || isGameOver) return;
    if (playerLane < laneCount - 1) {
      playerLane += 1;
      notifyListeners();
    }
  }

  double laneToX(double lane) => (lane - (laneCount - 1) / 2) * laneWidthM;

  String get timerText {
    final t = elapsed;
    final m = t.inMinutes;
    final s = t.inSeconds % 60;
    final cs = (t.inMilliseconds % 1000) ~/ 10;
    return '$m:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  void setSteer(double value) {
    if (!isRunning || isPaused || isGameOver) return;
    steerInput = value.clamp(-1.0, 1.0);
    notifyListeners();
  }

  CarConfig get carConfig => CarConfigs.byId(spec.id);

  void cycleCamera() {
    cameraPreset = (cameraPreset + 1) % CameraRig.presets.length;
    notifyListeners();
  }

  void setThrottle(bool held) {
    if (!isRunning || isPaused || isGameOver) return;
    throttleHeld = held;
    notifyListeners();
  }

  void setBrake(bool held) {
    if (!isRunning || isPaused || isGameOver) return;
    brakeHeld = held;
    if (held) nitroActive = false;
    notifyListeners();
  }

  void setSatelliteView(bool value) {
    satelliteView = value;
    notifyListeners();
  }

  bool activateNitro() {
    if (!isRunning || isPaused || isGameOver) return false;
    if (brakeHeld || nitroActive || nitroFuel < 0.28) return false;
    nitroActive = true;
    _nitroLeft = 1.35 + nitroLevel * 0.22;
    nitroFuel = (nitroFuel - 0.34).clamp(0.0, 1.0);
    notifyListeners();
    return true;
  }

  Offset worldPosition({required double along, required double laneAnim}) {
    final s = route.sampleAt(along);
    final rightX = cos(s.heading);
    final rightY = -sin(s.heading);
    final offset = (laneAnim - (laneCount - 1) / 2) * laneWidthM;
    return Offset(s.x + rightX * offset, s.y + rightY * offset);
  }

  void _snapToRoute() {
    final s = route.sampleAt(alongMeters);
    heading = s.heading;
    final p = worldPosition(along: alongMeters, laneAnim: playerLaneAnim);
    worldX = p.dx;
    worldY = p.dy;
  }

  void _update(double dt) {
    if (!isRunning || isPaused || isGameOver) return;

    final handling = spec.handling * (brakeHeld ? 1.15 : 1.0);
    playerLaneAnim += (playerLane - playerLaneAnim) * (12 * handling * dt);
    final targetX = laneToX(playerLaneAnim);
    playerX += (targetX - playerX) * (8 * handling * dt);
    playerX += steerInput * 10.8 * handling * dt;
    playerX = playerX.clamp(laneToX(0), laneToX((laneCount - 1).toDouble()));
    if (steerInput.abs() > 0.22) {
      playerLane = ((playerX / laneWidthM) + (laneCount - 1) / 2).round().clamp(0, laneCount - 1);
    }
    roadScroll += speed * 24 * dt;
    visualYaw += (steerInput * 0.42 - visualYaw) * (8 * dt);
    wheelSpin += speed * 4.8 * dt;

    final engineMul = 1 + engineLevel * 0.06;
    var cruise = throttleHeld ? spec.cruiseCap * 0.62 : 1.15;
    if (throttleHeld) cruise += spec.accel;
    if (nitroActive) cruise += spec.nitroBoost;
    cruise *= engineMul;
    if (brakeHeld) cruise *= (1 - spec.brakeForce).clamp(0.28, 0.55);
    if (!throttleHeld && !nitroActive) {
      cruise = brakeHeld ? 0.45 : 1.15;
    }

    speed += (cruise - speed) * (3.2 * dt);
    if (speed > peakSpeed) peakSpeed = speed;

    if (nitroActive) {
      _nitroLeft -= dt;
      if (_nitroLeft <= 0) {
        nitroActive = false;
        _nitroLeft = 0;
      }
    }
    if (!nitroActive) {
      nitroFuel = (nitroFuel + dt * 0.07).clamp(0.0, 1.0);
    }

    // Arcade time scale so 22 km plays in about 90 seconds.
    alongMeters += (speedKmh / 3.6) * 10.2 * dt;
    if (alongMeters >= endAlong) {
      alongMeters = endAlong;
      _snapToRoute();
      score = (distanceKm * 120).round() + coins * 15 + maxCombo * 5 + carsPassed * 8 + 2000;
      isFinished = true;
      _endGame();
      return;
    }

    _snapToRoute();
    displayHeading += _wrap(heading - displayHeading) * (5.5 * dt);
    navHint = route.hintAt(alongMeters, untilAlong: endAlong);
    score = (distanceKm * 120).round() + coins * 15 + maxCombo * 5 + carsPassed * 8;

    _spawnCooldown -= dt;
    if (traffic.length < 6) _spawnTraffic();
    if (walkers.length < 5 && _spawnCooldown <= 0) {
      _spawnWalker();
      _spawnCooldown = 0.8 + _random.nextDouble() * 0.5;
    }
    _updateTraffic(dt);
    _updateWalkers(dt);
    notifyListeners();
  }

  void _spawnTraffic() {
    const sprites = [
      CarCatalog.trafficBlue,
      CarCatalog.trafficSilver,
      CarCatalog.trafficTaxi,
      CarCatalog.trafficVan,
      CarCatalog.trafficHatch,
      CarCatalog.voltX,
    ];
    final lane = _random.nextInt(laneCount);
    traffic.add(
      TrafficCar(
        id: _nextId++,
        lane: lane,
        x: laneToX(lane.toDouble()),
        z: 16 + traffic.length * 11 + _random.nextDouble() * 10,
        color: const Color(0xFF6E747C),
        speedFactor: 0.32 + _random.nextDouble() * 0.4,
        sprite: sprites[traffic.length % sprites.length],
        modelPath: CarConfigs.trafficModels[traffic.length % CarConfigs.trafficModels.length],
      ),
    );
  }

  void _updateTraffic(double dt) {
    for (final car in traffic) {
      car.z -= speed * 13.5 * dt * (1.08 - car.speedFactor * 0.4);
      if (car.z < 4.4) {
        car.z = 48 + _random.nextDouble() * 55;
        car.lane = _random.nextInt(laneCount);
        car.x = laneToX(car.lane.toDouble());
      }
    }
  }

  void _spawnWalker() {
    final side = _random.nextBool() ? -1 : 1;
    final suitRoll = _random.nextInt(5);
    const suits = [
      Color(0xFFE63946),
      Color(0xFF14AABC),
      Color(0xFF1D3557),
      Color(0xFF7B2CBF),
      Color(0xFF2D6A4F),
    ];
    const hairs = [
      Color(0xFF1B1B1B),
      Color(0xFF3D2314),
      Color(0xFF111111),
      Color(0xFF2B1B12),
      Color(0xFF4A3728),
    ];
    final useDriver = _random.nextDouble() < 0.7;
    walkers.add(
      SidewalkWalker(
        id: _nextId++,
        side: side,
        x: side * 8.4,
        z: 28 + _random.nextDouble() * 48,
        suit: useDriver ? driverSuit : suits[suitRoll],
        hair: useDriver ? driverHair : hairs[suitRoll],
        skin: driverSkin,
      )..lateralDir = _random.nextBool() ? 1 : -1,
    );
  }

  void _updateWalkers(double dt) {
    for (final walker in List<SidewalkWalker>.from(walkers)) {
      walker.z -= speed * 16 * dt;
      walker.phase += dt * 7;
      walker.lateral += walker.lateralDir * 1.6 * dt;
      if (walker.lateral.abs() > 1.15) walker.lateralDir *= -1;
      walker.x = walker.side * 8.4 + walker.lateral;
      if (walker.z < -8 || walker.z > 120) {
        walkers.remove(walker);
      }
    }
  }

  double _wrap(double a) {
    while (a > pi) {
      a -= pi * 2;
    }
    while (a < -pi) {
      a += pi * 2;
    }
    return a;
  }

  void _endGame() {
    isGameOver = true;
    isRunning = false;
    combo = 0;
    throttleHeld = false;
    brakeHeld = false;
    steerInput = 0;
    nitroActive = false;
    _tick?.cancel();
    _tick = null;
    notifyListeners();
  }

  void disposeController() {
    _tick?.cancel();
    _tick = null;
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }
}
