import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';

enum SurvivalStage { city, forest }

enum ZombieKind { walker, runner, brute }

class Zombie {
  Zombie({
    required this.id,
    required this.lane,
    required this.y,
    required this.kind,
    required this.hp,
    required this.maxHp,
  });

  final int id;
  int lane;
  double y; // 0 = far / top, 1 = at player
  final ZombieKind kind;
  int hp;
  final int maxHp;

  double get speed {
    switch (kind) {
      case ZombieKind.walker:
        return 0.12;
      case ZombieKind.runner:
        return 0.22;
      case ZombieKind.brute:
        return 0.08;
    }
  }

  int get scoreValue {
    switch (kind) {
      case ZombieKind.walker:
        return 10;
      case ZombieKind.runner:
        return 18;
      case ZombieKind.brute:
        return 30;
    }
  }

  Color get tint {
    switch (kind) {
      case ZombieKind.walker:
        return const Color(0xFF6A994E);
      case ZombieKind.runner:
        return const Color(0xFFBC4749);
      case ZombieKind.brute:
        return const Color(0xFF386641);
    }
  }
}

class HitFx {
  HitFx({required this.lane, required this.y, required this.born});

  final int lane;
  final double y;
  final DateTime born;
}

/// Original survival game — characters: Niko (hero) + Blue Bot (gadget buddy).
/// Not affiliated with any existing cartoon franchise.
class CitySurvivalController extends ChangeNotifier {
  CitySurvivalController();

  static const int laneCount = 3;

  final Random _random = Random();
  final List<Zombie> zombies = [];
  final List<HitFx> hits = [];

  int playerLane = 1;
  double playerLaneAnim = 1;
  int lives = 3;
  int score = 0;
  int kills = 0;
  int combo = 0;
  int maxCombo = 0;
  bool isRunning = false;
  bool isPaused = false;
  bool isGameOver = false;
  bool attackFlash = false;
  SurvivalStage stage = SurvivalStage.city;
  double stageProgress = 0; // 0..1 within stage timer
  double scroll = 0;

  Timer? _tick;
  double _spawnCd = 0.8;
  int _nextId = 0;
  DateTime? _startedAt;
  DateTime? _lastAttack;

  Duration get elapsed =>
      _startedAt == null ? Duration.zero : DateTime.now().difference(_startedAt!);

  bool get canAttack {
    if (_lastAttack == null) return true;
    return DateTime.now().difference(_lastAttack!) >
        const Duration(milliseconds: 280);
  }

  void start() {
    disposeController();
    isRunning = true;
    isPaused = false;
    isGameOver = false;
    playerLane = 1;
    playerLaneAnim = 1;
    lives = 3;
    score = 0;
    kills = 0;
    combo = 0;
    maxCombo = 0;
    stage = SurvivalStage.city;
    stageProgress = 0;
    scroll = 0;
    zombies.clear();
    hits.clear();
    _spawnCd = 0.7;
    _startedAt = DateTime.now();
    _lastAttack = null;
    attackFlash = false;
    _tick = Timer.periodic(const Duration(milliseconds: 16), (_) => _update(0.016));
    notifyListeners();
  }

  void pause() {
    if (!isRunning || isGameOver) return;
    isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!isPaused) return;
    isPaused = false;
    notifyListeners();
  }

  void moveLeft() {
    if (!_alive) return;
    if (playerLane > 0) {
      playerLane--;
      notifyListeners();
    }
  }

  void moveRight() {
    if (!_alive) return;
    if (playerLane < laneCount - 1) {
      playerLane++;
      notifyListeners();
    }
  }

  /// Fight / gadget blast in current lane (closest zombie in range).
  bool attack() {
    if (!_alive || !canAttack) return false;
    _lastAttack = DateTime.now();
    attackFlash = true;
    Future.delayed(const Duration(milliseconds: 120), () {
      attackFlash = false;
    });

    Zombie? target;
    double bestY = -1;
    for (final z in zombies) {
      if (z.lane == playerLane && z.y >= 0.45 && z.y <= 0.92) {
        if (z.y > bestY) {
          bestY = z.y;
          target = z;
        }
      }
    }

    if (target == null) {
      notifyListeners();
      return false;
    }

    final dmg = stage == SurvivalStage.forest ? 1 : 1;
    target.hp -= dmg;
    hits.add(HitFx(lane: target.lane, y: target.y, born: DateTime.now()));

    if (target.hp <= 0) {
      score += target.scoreValue + combo * 2;
      kills++;
      combo++;
      if (combo > maxCombo) maxCombo = combo;
      zombies.remove(target);
    }
    notifyListeners();
    return true;
  }

  bool get _alive => isRunning && !isPaused && !isGameOver;

  void _update(double dt) {
    if (!_alive) return;

    playerLaneAnim += (playerLane - playerLaneAnim) * 14 * dt;
    scroll = (scroll + dt * (stage == SurvivalStage.city ? 0.35 : 0.28)) % 1.0;
    stageProgress += dt / 45; // ~45s city then forest
    if (stage == SurvivalStage.city && stageProgress >= 1) {
      stage = SurvivalStage.forest;
      stageProgress = 0;
    }

    final difficulty = 1.0 + kills * 0.04 + (stage == SurvivalStage.forest ? 0.35 : 0);
    _spawnCd -= dt;
    if (_spawnCd <= 0) {
      _spawnZombie();
      _spawnCd = (1.1 / difficulty).clamp(0.35, 1.1) + _random.nextDouble() * 0.25;
    }

    for (final z in List<Zombie>.from(zombies)) {
      z.y += z.speed * difficulty * dt;
      if (z.y >= 0.96) {
        // Reached player
        if (z.lane == playerLane || (z.lane - playerLaneAnim).abs() < 0.4) {
          lives--;
          combo = 0;
          zombies.remove(z);
          if (lives <= 0) {
            _end();
            return;
          }
        } else {
          zombies.remove(z);
        }
      }
    }

    hits.removeWhere(
      (h) => DateTime.now().difference(h.born) > const Duration(milliseconds: 350),
    );
    notifyListeners();
  }

  void _spawnZombie() {
    final lane = _random.nextInt(laneCount);
    final roll = _random.nextDouble();
    final ZombieKind kind;
    if (stage == SurvivalStage.forest) {
      kind = roll < 0.45
          ? ZombieKind.walker
          : roll < 0.8
              ? ZombieKind.runner
              : ZombieKind.brute;
    } else {
      kind = roll < 0.65
          ? ZombieKind.walker
          : roll < 0.9
              ? ZombieKind.runner
              : ZombieKind.brute;
    }
    final hp = switch (kind) {
      ZombieKind.walker => 1,
      ZombieKind.runner => 1,
      ZombieKind.brute => 3,
    };
    // Avoid stacking same lane near spawn
    if (zombies.any((z) => z.lane == lane && z.y < 0.2)) return;
    zombies.add(
      Zombie(
        id: _nextId++,
        lane: lane,
        y: -0.05,
        kind: kind,
        hp: hp,
        maxHp: hp,
      ),
    );
  }

  void _end() {
    isGameOver = true;
    isRunning = false;
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
