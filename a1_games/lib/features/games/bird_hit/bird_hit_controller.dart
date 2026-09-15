import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

enum BirdSize { large, medium, small }

extension BirdSizeX on BirdSize {
  double get scale {
    switch (this) {
      case BirdSize.large:
        return 1.35;
      case BirdSize.medium:
        return 1.0;
      case BirdSize.small:
        return 0.72;
    }
  }

  int get points {
    switch (this) {
      case BirdSize.large:
        return 10;
      case BirdSize.medium:
        return 15;
      case BirdSize.small:
        return 20;
    }
  }

  double get hitRadius {
    switch (this) {
      case BirdSize.large:
        return 38;
      case BirdSize.medium:
        return 28;
      case BirdSize.small:
        return 20;
    }
  }
}

class Bird {
  Bird({
    required this.id,
    required this.size,
    required this.x,
    required this.y,
    required this.speed,
    required this.facingRight,
    this.isGolden = false,
    this.wingOffset = 0,
  });

  final String id;
  final BirdSize size;
  double x;
  final double y;
  final double speed;
  bool facingRight;
  final bool isGolden;
  double wingOffset;
}

class HitEffect {
  HitEffect({
    required this.x,
    required this.y,
    required this.isGolden,
    required this.createdAt,
  });

  final double x;
  final double y;
  final bool isGolden;
  final DateTime createdAt;
}

class BirdHitController extends ChangeNotifier {
  BirdHitController({this.durationSeconds = 45});

  final int durationSeconds;
  final Random _random = Random();

  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int hits = 0;
  int misses = 0;
  int escapes = 0;
  int timeLeft = 45;
  double wingPhase = 0;
  bool isRunning = false;
  bool isGameOver = false;

  final List<Bird> birds = [];
  final List<HitEffect> hitEffects = [];

  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _moveTimer;

  int _birdId = 0;
  double _spawnInterval = 1.4;

  void start() {
    if (isRunning) return;
    isRunning = true;
    isGameOver = false;
    score = 0;
    combo = 0;
    maxCombo = 0;
    hits = 0;
    misses = 0;
    escapes = 0;
    timeLeft = durationSeconds;
    wingPhase = 0;
    birds.clear();
    hitEffects.clear();
    _birdId = 0;
    _spawnInterval = 1.4;

    _cancelTimers();

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isRunning || isGameOver) return;
      timeLeft--;
      if (timeLeft <= 0) {
        _endGame();
        return;
      }
      notifyListeners();
    });

    _spawnTimer = Timer.periodic(
      Duration(milliseconds: (_spawnInterval * 1000).round()),
      (_) => _spawnBird(),
    );

    _moveTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updateBirds();
      wingPhase += 0.18;
      _pruneEffects();
    });

    _spawnBird();
    notifyListeners();
  }

  void _spawnBird() {
    if (!isRunning || isGameOver) return;
    if (birds.length >= 8) return;

    final roll = _random.nextDouble();
    final size = roll < 0.3
        ? BirdSize.large
        : roll < 0.65
            ? BirdSize.medium
            : BirdSize.small;
    final facingRight = _random.nextBool();
    final isGolden = _random.nextDouble() < 0.08;

    birds.add(
      Bird(
        id: 'bird_${_birdId++}',
        size: size,
        x: facingRight ? -0.08 : 1.08,
        y: 0.12 + _random.nextDouble() * 0.58,
        speed: 0.0009 + _random.nextDouble() * 0.0012 + (size == BirdSize.small ? 0.0004 : 0),
        facingRight: facingRight,
        isGolden: isGolden,
        wingOffset: _random.nextDouble() * pi * 2,
      ),
    );

    if (score > 80) {
      _spawnInterval = (_spawnInterval - 0.04).clamp(0.75, 1.4);
      _restartSpawnTimer();
    }

    notifyListeners();
  }

  void _restartSpawnTimer() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(
      Duration(milliseconds: (_spawnInterval * 1000).round()),
      (_) => _spawnBird(),
    );
  }

  void _updateBirds() {
    if (!isRunning || isGameOver) return;

    final escaped = <Bird>[];
    for (final bird in birds) {
      bird.x += bird.facingRight ? bird.speed : -bird.speed;
      bird.wingOffset += bird.isGolden ? 0.22 : 0.16;

      if (bird.facingRight && bird.x > 1.12) escaped.add(bird);
      if (!bird.facingRight && bird.x < -0.12) escaped.add(bird);
    }

    for (final bird in escaped) {
      birds.remove(bird);
      escapes++;
      combo = 0;
      score = (score - 1).clamp(0, 999999);
    }

    notifyListeners();
  }

  bool tryHitBird(Offset localPosition, Size areaSize) {
    if (!isRunning || isGameOver) return false;

    for (var i = birds.length - 1; i >= 0; i--) {
      final bird = birds[i];
      final cx = bird.x * areaSize.width;
      final cy = bird.y * areaSize.height;
      final dist = (localPosition - Offset(cx, cy)).distance;

      if (dist <= bird.size.hitRadius * bird.size.scale) {
        birds.removeAt(i);
        hits++;
        combo++;
        if (combo > maxCombo) maxCombo = combo;

        final base = bird.isGolden ? 50 : bird.size.points;
        final comboBonus = combo > 1 ? (combo - 1) * 3 : 0;
        score += base + comboBonus;

        hitEffects.add(
          HitEffect(
            x: cx,
            y: cy,
            isGolden: bird.isGolden,
            createdAt: DateTime.now(),
          ),
        );
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void registerMiss() {
    if (!isRunning || isGameOver) return;
    misses++;
    combo = 0;
    score = (score - 2).clamp(0, 999999);
    notifyListeners();
  }

  void _pruneEffects() {
    final now = DateTime.now();
    hitEffects.removeWhere(
      (e) => now.difference(e.createdAt).inMilliseconds > 600,
    );
  }

  double? get accuracy {
    final total = hits + misses;
    if (total == 0) return null;
    return (hits / total) * 100;
  }

  void _endGame() {
    isGameOver = true;
    isRunning = false;
    birds.clear();
    _cancelTimers();
    notifyListeners();
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _moveTimer?.cancel();
    _gameTimer = null;
    _spawnTimer = null;
    _moveTimer = null;
  }

  void disposeController() {
    _cancelTimers();
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }
}
