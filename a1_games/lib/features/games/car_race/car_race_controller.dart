import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'car_catalog.dart';

enum CityTheme {
  neonTokyo,
  dubaiGlow,
  nycNight,
  mumbaiRain,
  parisDusk,
}

extension CityThemeX on CityTheme {
  String get label {
    switch (this) {
      case CityTheme.neonTokyo:
        return 'Tokyo Neon';
      case CityTheme.dubaiGlow:
        return 'Dubai Glow';
      case CityTheme.nycNight:
        return 'NYC Night';
      case CityTheme.mumbaiRain:
        return 'Mumbai Rain';
      case CityTheme.parisDusk:
        return 'Paris Dusk';
    }
  }

  String get skylineAsset {
    switch (this) {
      case CityTheme.neonTokyo:
        return CarCatalog.skylineTokyo;
      case CityTheme.dubaiGlow:
        return CarCatalog.skylineDubai;
      case CityTheme.nycNight:
        return CarCatalog.skylineNyc;
      case CityTheme.mumbaiRain:
        return CarCatalog.skylineMumbai;
      case CityTheme.parisDusk:
        return CarCatalog.skylineParis;
    }
  }

  bool get usePalms => this == CityTheme.dubaiGlow || this == CityTheme.mumbaiRain;

  List<Color> get skyColors {
    switch (this) {
      case CityTheme.neonTokyo:
        return const [Color(0xFF0B0220), Color(0xFF1A0A3C), Color(0xFF2D1054)];
      case CityTheme.dubaiGlow:
        return const [Color(0xFF0A1628), Color(0xFF132A44), Color(0xFF1C3A52)];
      case CityTheme.nycNight:
        return const [Color(0xFF05070F), Color(0xFF10182A), Color(0xFF1A2438)];
      case CityTheme.mumbaiRain:
        return const [Color(0xFF0C1418), Color(0xFF152228), Color(0xFF1E3038)];
      case CityTheme.parisDusk:
        return const [Color(0xFF1A0F20), Color(0xFF2A1830), Color(0xFF3D2440)];
    }
  }

  Color get neonA {
    switch (this) {
      case CityTheme.neonTokyo:
        return const Color(0xFFFF2D95);
      case CityTheme.dubaiGlow:
        return const Color(0xFFFFC857);
      case CityTheme.nycNight:
        return const Color(0xFF4CC9F0);
      case CityTheme.mumbaiRain:
        return const Color(0xFF52B788);
      case CityTheme.parisDusk:
        return const Color(0xFFE76F51);
    }
  }

  Color get neonB {
    switch (this) {
      case CityTheme.neonTokyo:
        return const Color(0xFF7B2CBF);
      case CityTheme.dubaiGlow:
        return const Color(0xFF00BBF9);
      case CityTheme.nycNight:
        return const Color(0xFFFF6B35);
      case CityTheme.mumbaiRain:
        return const Color(0xFFF4A261);
      case CityTheme.parisDusk:
        return const Color(0xFF9B5DE5);
    }
  }
}

enum RoadsideKind { tree, palm, light, barrier, sign, cone }

class TrafficCar {
  TrafficCar({
    required this.id,
    required this.lane,
    required this.y,
    required this.color,
    required this.speedFactor,
    required this.sprite,
  });

  final int id;
  int lane;
  double y;
  final Color color;
  final double speedFactor;
  final String sprite;
}

class RoadsideProp {
  RoadsideProp({
    required this.id,
    required this.kind,
    required this.y,
    required this.left,
  });

  final int id;
  final RoadsideKind kind;
  double y;
  final bool left;
}

class CarRaceController extends ChangeNotifier {
  CarRaceController({
    required this.spec,
    this.engineLevel = 0,
    this.nitroLevel = 0,
  });

  static const int laneCount = 3;
  static const int fieldSize = 8;
  static const double lapLengthKm = 2.0;

  final RaceCarSpec spec;
  final int engineLevel;
  final int nitroLevel;

  final Random _random = Random();
  final List<TrafficCar> traffic = [];
  final List<RoadsideProp> props = [];

  int playerLane = 1;
  double playerLaneAnim = 1;
  double roadScroll = 0;
  double cityScroll = 0;
  double speed = 2.4;
  double peakSpeed = 2.4;
  double distanceKm = 0;
  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int coins = 0;
  int carsPassed = 0;
  bool isRunning = false;
  bool isPaused = false;
  bool isGameOver = false;
  bool nearMissFlash = false;
  bool throttleHeld = false;
  bool brakeHeld = false;
  bool nitroActive = false;
  double nitroFuel = 1;
  double _nitroLeft = 0;

  CityTheme city = CityTheme.neonTokyo;
  int _cityIndex = 0;
  double _cityTimer = 0;

  Timer? _tick;
  int _nextId = 0;
  double _spawnCooldown = 0;
  double _propCooldown = 0;
  DateTime? _startedAt;

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  double get speedKmh => (speed * 42).clamp(40, 320);

  double get peakKmh => (peakSpeed * 42).clamp(40, 320);

  int get racePosition => (fieldSize - carsPassed).clamp(1, fieldSize);

  int get lap => (distanceKm / lapLengthKm).floor() + 1;

  double get lapProgress => (distanceKm % lapLengthKm) / lapLengthKm;

  bool get showStartGantry => distanceKm < 0.18;

  bool get showFinishGantry {
    final p = lapProgress;
    return p > 0.92 || p < 0.045;
  }

  bool get showBridge {
    final phase = (distanceKm / 1.6) % 1.0;
    return phase > 0.78 && phase < 0.92;
  }

  String get playerSprite => spec.asset;

  void start() {
    disposeController();
    isRunning = true;
    isPaused = false;
    isGameOver = false;
    playerLane = 1;
    playerLaneAnim = 1;
    roadScroll = 0;
    cityScroll = 0;
    speed = 2.4;
    peakSpeed = 2.4;
    distanceKm = 0;
    score = 0;
    combo = 0;
    maxCombo = 0;
    coins = 0;
    carsPassed = 0;
    traffic.clear();
    props.clear();
    throttleHeld = false;
    brakeHeld = false;
    nitroActive = false;
    nitroFuel = 1;
    _nitroLeft = 0;
    _cityIndex = _random.nextInt(CityTheme.values.length);
    city = CityTheme.values[_cityIndex];
    _cityTimer = 0;
    _spawnCooldown = 0.4;
    _propCooldown = 0.05;
    _startedAt = DateTime.now();
    nearMissFlash = false;

    _tick = Timer.periodic(const Duration(milliseconds: 16), (_) => _update(0.016));
    notifyListeners();
  }

  void pause() {
    if (!isRunning || isGameOver) return;
    isPaused = true;
    throttleHeld = false;
    brakeHeld = false;
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

  void setThrottle(bool held) {
    if (!isRunning || isPaused || isGameOver) return;
    throttleHeld = held;
  }

  void setBrake(bool held) {
    if (!isRunning || isPaused || isGameOver) return;
    brakeHeld = held;
    if (held) nitroActive = false;
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

  void _update(double dt) {
    if (!isRunning || isPaused || isGameOver) return;

    final handling = spec.handling * (brakeHeld ? 1.15 : 1.0);
    playerLaneAnim += (playerLane - playerLaneAnim) * (12 * handling * dt);

    final engineMul = 1 + engineLevel * 0.06;
    var cruise = (2.4 + elapsed.inMilliseconds / 1000 * 0.085).clamp(2.4, spec.cruiseCap);
    if (throttleHeld) cruise += spec.accel;
    if (nitroActive) cruise += spec.nitroBoost;
    cruise *= engineMul;
    if (brakeHeld) cruise *= (1 - spec.brakeForce).clamp(0.38, 0.7);

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

    roadScroll = (roadScroll + speed * dt * 2.8) % 1.0;
    cityScroll = (cityScroll + speed * dt * 0.55) % 1.0;
    distanceKm += speed * dt * 0.018;
    score = (distanceKm * 120).round() + coins * 15 + maxCombo * 5 + carsPassed * 8;

    _cityTimer += dt;
    if (_cityTimer > 28) {
      _cityTimer = 0;
      _cityIndex = (_cityIndex + 1) % CityTheme.values.length;
      city = CityTheme.values[_cityIndex];
    }

    _spawnCooldown -= dt;
    if (_spawnCooldown <= 0) {
      _spawnTraffic();
      final gap = (1.05 - (speed - 2.4) * 0.08).clamp(0.42, 1.05);
      _spawnCooldown = gap + _random.nextDouble() * 0.25;
    }

    _propCooldown -= dt;
    if (_propCooldown <= 0 && props.length < 22) {
      _spawnProps();
      _propCooldown = 0.18 + _random.nextDouble() * 0.16;
    }

    for (final car in List<TrafficCar>.from(traffic)) {
      car.y += (speed * car.speedFactor) * dt * 0.22;
      if (car.y > 1.25) {
        traffic.remove(car);
        combo += 1;
        carsPassed += 1;
        if (combo > maxCombo) maxCombo = combo;
        if (_random.nextDouble() < 0.22) coins += 1;
      }
    }

    for (final prop in List<RoadsideProp>.from(props)) {
      prop.y += speed * dt * 0.20;
      if (prop.y > 1.2) props.remove(prop);
    }

    _checkCollisions();
    notifyListeners();
  }

  void _spawnTraffic() {
    final lanes = List<int>.generate(laneCount, (i) => i)..shuffle(_random);
    final count = speed > 5.2 && _random.nextDouble() < 0.35 ? 2 : 1;
    for (var i = 0; i < count; i++) {
      final lane = lanes[i % lanes.length];
      final blocked = traffic.any((t) => t.lane == lane && t.y < 0.28);
      if (blocked) continue;
      traffic.add(
        TrafficCar(
          id: _nextId++,
          lane: lane,
          y: -0.12 - i * 0.18,
          color: _trafficColor(),
          speedFactor: 0.55 + _random.nextDouble() * 0.35,
          sprite: CarCatalog.trafficSprites[_random.nextInt(CarCatalog.trafficSprites.length)],
        ),
      );
    }
  }

  void _spawnProps() {
    final left = _random.nextBool();
    final kinds = <RoadsideKind>[
      city.usePalms ? RoadsideKind.palm : RoadsideKind.tree,
      RoadsideKind.light,
      RoadsideKind.barrier,
      RoadsideKind.sign,
      RoadsideKind.cone,
    ];
    final kind = kinds[_random.nextInt(kinds.length)];
    // Avoid stacking same shoulder too close
    if (props.any((p) => p.left == left && p.y < 0.12)) return;
    props.add(
      RoadsideProp(
        id: _nextId++,
        kind: kind,
        y: -0.08,
        left: left,
      ),
    );
    if (_random.nextDouble() < 0.35) {
      props.add(
        RoadsideProp(
          id: _nextId++,
          kind: RoadsideKind.light,
          y: -0.02,
          left: !left,
        ),
      );
    }
  }

  Color _trafficColor() {
    const palette = [
      Color(0xFF457B9D),
      Color(0xFF2A9D8F),
      Color(0xFFE9C46A),
      Color(0xFFF4A261),
      Color(0xFF9B5DE5),
      Color(0xFF00BBF9),
      Color(0xFFE76F51),
    ];
    return palette[_random.nextInt(palette.length)];
  }

  void _checkCollisions() {
    const playerY = 0.78;
    final hitBox = 0.085 * spec.widthFactor;
    for (final car in traffic) {
      final sameLane = (car.lane - playerLaneAnim).abs() < 0.35;
      if (!sameLane) {
        if ((car.y - playerY).abs() < 0.07 &&
            (car.lane - playerLane).abs() == 1) {
          if (!nearMissFlash) {
            nearMissFlash = true;
            combo += 2;
            coins += 1;
            Future.delayed(const Duration(milliseconds: 180), () {
              nearMissFlash = false;
            });
          }
        }
        continue;
      }
      if ((car.y - playerY).abs() < hitBox) {
        _endGame();
        return;
      }
    }
  }

  void _endGame() {
    isGameOver = true;
    isRunning = false;
    combo = 0;
    throttleHeld = false;
    brakeHeld = false;
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
