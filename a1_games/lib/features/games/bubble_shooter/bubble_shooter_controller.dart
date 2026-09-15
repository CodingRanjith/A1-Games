import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class GridBubble {
  GridBubble({
    required this.row,
    required this.col,
    required this.colorIndex,
  });

  int row;
  int col;
  int colorIndex;
}

class FlyingBubble {
  FlyingBubble({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.colorIndex,
  });

  double x;
  double y;
  double vx;
  double vy;
  final int colorIndex;
}

class PopEffect {
  PopEffect({
    required this.x,
    required this.y,
    required this.color,
    required this.createdAt,
  });

  final double x;
  final double y;
  final Color color;
  final DateTime createdAt;
}

class BubbleShooterController extends ChangeNotifier {
  BubbleShooterController({this.durationSeconds = 90});

  static const int cols = 11;
  static const double bubbleRadius = 17;
  static const double topMargin = 28;
  static const double dangerLineNorm = 0.72;

  static const List<Color> bubbleColors = [
    Color(0xFFE63946),
    Color(0xFF4361EE),
    Color(0xFF2D9F6F),
    Color(0xFFFFB703),
    Color(0xFF9B5DE5),
    Color(0xFFFF6B6B),
  ];

  final int durationSeconds;
  final Random _random = Random();

  final List<GridBubble> grid = [];
  final List<PopEffect> popEffects = [];

  FlyingBubble? projectile;
  Offset? aimPoint;

  int score = 0;
  int combo = 0;
  int maxCombo = 0;
  int timeLeft = 90;
  int currentColor = 0;
  int nextColor = 0;
  int activeColorCount = 5;
  bool isRunning = false;
  bool isGameOver = false;
  bool canShoot = true;

  double _playWidth = 1;
  double _playHeight = 1;
  double _rowSpawnInterval = 14;

  Timer? _gameTimer;
  Timer? _tickTimer;
  Timer? _rowTimer;

  void setPlaySize(double width, double height) {
    _playWidth = width;
    _playHeight = height;
  }

  Offset gridPosition(int row, int col) {
    final dx = bubbleRadius * 2;
    final dy = bubbleRadius * sqrt(3);
    final gridWidth = (cols - 1) * dx + bubbleRadius;
    final x0 = (_playWidth - gridWidth) / 2 + bubbleRadius;
    final x = x0 + col * dx + (row.isOdd ? bubbleRadius : 0);
    final y = topMargin + row * dy;
    return Offset(x, y);
  }

  double get dangerLineY => topMargin + (dangerLineNorm * _playHeight);

  Offset get shooterPosition =>
      Offset(_playWidth / 2, _playHeight - bubbleRadius * 2.6);

  void start() {
    if (isRunning) return;
    isRunning = true;
    isGameOver = false;
    canShoot = true;
    score = 0;
    combo = 0;
    maxCombo = 0;
    timeLeft = durationSeconds;
    activeColorCount = 5;
    _rowSpawnInterval = 14;
    grid.clear();
    popEffects.clear();
    projectile = null;
    aimPoint = null;

    _pickNextColors();
    _buildInitialGrid();

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

    _tickTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _updateProjectile();
      _prunePopEffects();
    });

    _scheduleRowSpawn();
    notifyListeners();
  }

  void _buildInitialGrid() {
    grid.clear();
    for (var row = 0; row < 6; row++) {
      for (var col = 0; col < cols; col++) {
        grid.add(
          GridBubble(
            row: row,
            col: col,
            colorIndex: _random.nextInt(activeColorCount),
          ),
        );
      }
    }
  }

  void _pickNextColors() {
    currentColor = nextColor;
    nextColor = _random.nextInt(activeColorCount);
  }

  void _scheduleRowSpawn() {
    _rowTimer?.cancel();
    _rowTimer = Timer(
      Duration(milliseconds: (_rowSpawnInterval * 1000).round()),
      () {
        if (isRunning && !isGameOver) {
          _pushNewRow();
          _scheduleRowSpawn();
        }
      },
    );
  }

  void _pushNewRow() {
    for (final bubble in grid) {
      bubble.row++;
    }
    grid.removeWhere((b) => b.row >= 13);

    for (var col = 0; col < cols; col++) {
      grid.add(
        GridBubble(
          row: 0,
          col: col,
          colorIndex: _random.nextInt(activeColorCount),
        ),
      );
    }

    _checkDangerLine();
    notifyListeners();
  }

  void setAim(Offset localPosition) {
    if (!isRunning || isGameOver || projectile != null) return;
    aimPoint = localPosition;
    notifyListeners();
  }

  void clearAim() {
    aimPoint = null;
    notifyListeners();
  }

  void shoot() {
    if (!isRunning || isGameOver || projectile != null || !canShoot) return;
    if (aimPoint == null) return;

    final shooter = shooterPosition;
    final dir = aimPoint! - shooter;
    if (dir.distance < 12) return;

    final normalized = dir / dir.distance;
    const speed = 520.0;
    projectile = FlyingBubble(
      x: shooter.dx,
      y: shooter.dy,
      vx: normalized.dx * speed,
      vy: normalized.dy * speed,
      colorIndex: currentColor,
    );
    canShoot = false;
    notifyListeners();
  }

  void _updateProjectile() {
    if (projectile == null || !isRunning || isGameOver) return;

    final p = projectile!;
    final dt = 0.016;
    p.x += p.vx * dt;
    p.y += p.vy * dt;

    if (p.x <= bubbleRadius) {
      p.x = bubbleRadius;
      p.vx = p.vx.abs();
    } else if (p.x >= _playWidth - bubbleRadius) {
      p.x = _playWidth - bubbleRadius;
      p.vx = -p.vx.abs();
    }

    if (p.y <= bubbleRadius) {
      _attachAtTop(p);
      return;
    }

    GridBubble? hit;
    var hitDist = double.infinity;
    for (final bubble in grid) {
      final pos = gridPosition(bubble.row, bubble.col);
      final dist = (Offset(p.x, p.y) - pos).distance;
      if (dist < bubbleRadius * 1.92 && dist < hitDist) {
        hit = bubble;
        hitDist = dist;
      }
    }

    if (hit != null) {
      _attachNear(p, hit);
      return;
    }

    if (p.y > _playHeight + bubbleRadius) {
      projectile = null;
      canShoot = true;
      _pickNextColors();
      combo = 0;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void _attachAtTop(FlyingBubble p) {
    var bestCol = 0;
    var bestDist = double.infinity;
    for (var col = 0; col < cols; col++) {
      if (_isOccupied(0, col)) continue;
      final pos = gridPosition(0, col);
      final dist = (Offset(p.x, p.y) - pos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestCol = col;
      }
    }
    _placeBubble(0, bestCol, p.colorIndex);
    _afterShot();
  }

  void _attachNear(FlyingBubble p, GridBubble hit) {
    final neighbors = _neighborCoords(hit.row, hit.col);
    var bestRow = hit.row;
    var bestCol = hit.col;
    var bestDist = double.infinity;

    for (final n in neighbors) {
      if (n.$1 < 0 || n.$1 > 12 || n.$2 < 0 || n.$2 >= cols) continue;
      if (_isOccupied(n.$1, n.$2)) continue;
      final pos = gridPosition(n.$1, n.$2);
      final dist = (Offset(p.x, p.y) - pos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestRow = n.$1;
        bestCol = n.$2;
      }
    }

    if (bestDist == double.infinity) {
      for (var r = 0; r <= 12; r++) {
        for (var c = 0; c < cols; c++) {
          if (_isOccupied(r, c)) continue;
          final pos = gridPosition(r, c);
          final dist = (Offset(p.x, p.y) - pos).distance;
          if (dist < bestDist) {
            bestDist = dist;
            bestRow = r;
            bestCol = c;
          }
        }
      }
    }

    if (bestDist == double.infinity) {
      projectile = null;
      canShoot = true;
      notifyListeners();
      return;
    }

    _placeBubble(bestRow, bestCol, p.colorIndex);
    _afterShot();
  }

  void _placeBubble(int row, int col, int colorIndex) {
    projectile = null;
    grid.add(GridBubble(row: row, col: col, colorIndex: colorIndex));
    notifyListeners();
  }

  void _afterShot() {
    projectile = null;
    final attached = grid.last;
    final matched = _findCluster(attached.row, attached.col, attached.colorIndex);

    var popped = 0;
    if (matched.length >= 3) {
      combo++;
      if (combo > maxCombo) maxCombo = combo;
      popped = matched.length;
      for (final key in matched) {
        grid.removeWhere((b) => b.row == key.$1 && b.col == key.$2);
        final pos = gridPosition(key.$1, key.$2);
        popEffects.add(
          PopEffect(
            x: pos.dx,
            y: pos.dy,
            color: bubbleColors[attached.colorIndex],
            createdAt: DateTime.now(),
          ),
        );
      }
      score += popped * 10 + (combo > 1 ? combo * 5 : 0);
    } else {
      combo = 0;
    }

    final floaters = _findFloaters();
    if (floaters.isNotEmpty) {
      for (final key in floaters) {
        final bubble = _bubbleAt(key.$1, key.$2);
        if (bubble == null) continue;
        final pos = gridPosition(key.$1, key.$2);
        popEffects.add(
          PopEffect(
            x: pos.dx,
            y: pos.dy,
            color: bubbleColors[bubble.colorIndex],
            createdAt: DateTime.now(),
          ),
        );
        grid.removeWhere((b) => b.row == key.$1 && b.col == key.$2);
      }
      score += floaters.length * 5;
    }

    _scaleDifficulty();
    _checkDangerLine();
    _pickNextColors();
    canShoot = true;
    notifyListeners();
  }

  Set<(int, int)> _findCluster(int row, int col, int color) {
    final visited = <(int, int)>{};
    final queue = <(int, int)>[(row, col)];

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (visited.contains(current)) continue;
      final bubble = _bubbleAt(current.$1, current.$2);
      if (bubble == null || bubble.colorIndex != color) continue;
      visited.add(current);
      for (final n in _neighborCoords(current.$1, current.$2)) {
        if (!visited.contains(n)) queue.add(n);
      }
    }
    return visited;
  }

  Set<(int, int)> _findFloaters() {
    final anchored = <(int, int)>{};
    final queue = <(int, int)>[];

    for (final bubble in grid) {
      if (bubble.row == 0) {
        queue.add((bubble.row, bubble.col));
      }
    }

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      if (anchored.contains(current)) continue;
      if (_bubbleAt(current.$1, current.$2) == null) continue;
      anchored.add(current);
      for (final n in _neighborCoords(current.$1, current.$2)) {
        if (!anchored.contains(n)) queue.add(n);
      }
    }

    final floaters = <(int, int)>{};
    for (final bubble in grid) {
      final key = (bubble.row, bubble.col);
      if (!anchored.contains(key)) floaters.add(key);
    }
    return floaters;
  }

  void _scaleDifficulty() {
    if (score >= 400 && activeColorCount < 6) {
      activeColorCount = 6;
    } else if (score >= 150 && activeColorCount < 5) {
      activeColorCount = 5;
    }
    _rowSpawnInterval = (14 - score / 120).clamp(7.0, 14.0);
  }

  void _checkDangerLine() {
    for (final bubble in grid) {
      final y = gridPosition(bubble.row, bubble.col).dy;
      if (y >= dangerLineY) {
        _endGame();
        return;
      }
    }
  }

  void _prunePopEffects() {
    final now = DateTime.now();
    popEffects.removeWhere(
      (e) => now.difference(e.createdAt).inMilliseconds > 500,
    );
  }

  bool _isOccupied(int row, int col) =>
      grid.any((b) => b.row == row && b.col == col);

  GridBubble? _bubbleAt(int row, int col) {
    for (final b in grid) {
      if (b.row == row && b.col == col) return b;
    }
    return null;
  }

  List<(int, int)> _neighborCoords(int row, int col) {
    if (row.isEven) {
      return [
        (row - 1, col - 1),
        (row - 1, col),
        (row, col - 1),
        (row, col + 1),
        (row + 1, col - 1),
        (row + 1, col),
      ];
    }
    return [
      (row - 1, col),
      (row - 1, col + 1),
      (row, col - 1),
      (row, col + 1),
      (row + 1, col),
      (row + 1, col + 1),
    ];
  }

  void _endGame() {
    isGameOver = true;
    isRunning = false;
    projectile = null;
    _cancelTimers();
    notifyListeners();
  }

  void _cancelTimers() {
    _gameTimer?.cancel();
    _tickTimer?.cancel();
    _rowTimer?.cancel();
    _gameTimer = null;
    _tickTimer = null;
    _rowTimer = null;
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
