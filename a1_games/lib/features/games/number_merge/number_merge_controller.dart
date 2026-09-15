import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/game_session.dart';

enum SwipeDirection { up, down, left, right }

class MergeTile {
  MergeTile({required this.value, this.isNew = false, this.merged = false});

  int value;
  bool isNew;
  bool merged;
}

class NumberMergeController extends ChangeNotifier {
  NumberMergeController();

  static const gridSize = 4;
  final GameSession session = GameSession(lives: 99);
  final Random _random = Random();

  List<List<MergeTile?>> grid = List.generate(
    gridSize,
    (_) => List.filled(gridSize, null),
  );

  int get score => session.score;
  bool get isGameOver => session.isGameOver;
  bool get isRunning => session.isRunning;

  void startGame() {
    session
      ..score = 0
      ..combo = 0
      ..maxCombo = 0
      ..isGameOver = false
      ..isRunning = true
      ..startTime = DateTime.now();
    grid = List.generate(gridSize, (_) => List.filled(gridSize, null));
    _spawnTile();
    _spawnTile();
    notifyListeners();
  }

  void _spawnTile() {
    final empty = <Point<int>>[];
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        if (grid[r][c] == null) empty.add(Point(c, r));
      }
    }
    if (empty.isEmpty) return;

    final cell = empty[_random.nextInt(empty.length)];
    grid[cell.y][cell.x] = MergeTile(
      value: _random.nextDouble() < 0.9 ? 2 : 4,
      isNew: true,
    );
  }

  bool swipe(SwipeDirection direction) {
    if (!session.isRunning || session.isGameOver) return false;

    final before = _gridSnapshot();
    _clearFlags();

    switch (direction) {
      case SwipeDirection.left:
        for (var r = 0; r < gridSize; r++) {
          grid[r] = _mergeLine(grid[r], reverse: false);
        }
      case SwipeDirection.right:
        for (var r = 0; r < gridSize; r++) {
          grid[r] = _mergeLine(grid[r], reverse: true);
        }
      case SwipeDirection.up:
        for (var c = 0; c < gridSize; c++) {
          final col = List<MergeTile?>.generate(
            gridSize,
            (r) => grid[r][c],
          );
          final merged = _mergeLine(col, reverse: false);
          for (var r = 0; r < gridSize; r++) {
            grid[r][c] = merged[r];
          }
        }
      case SwipeDirection.down:
        for (var c = 0; c < gridSize; c++) {
          final col = List<MergeTile?>.generate(
            gridSize,
            (r) => grid[r][c],
          );
          final merged = _mergeLine(col, reverse: true);
          for (var r = 0; r < gridSize; r++) {
            grid[r][c] = merged[r];
          }
        }
    }

    if (!_gridsEqual(before, _gridSnapshot())) {
      _spawnTile();
      if (!_canMove()) session.endGame();
      notifyListeners();
      return true;
    }
    return false;
  }

  List<List<int?>> _gridSnapshot() {
    return List.generate(
      gridSize,
      (r) => List.generate(gridSize, (c) => grid[r][c]?.value),
    );
  }

  bool _gridsEqual(List<List<int?>> a, List<List<int?>> b) {
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }

  void _clearFlags() {
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final t = grid[r][c];
        if (t != null) {
          t.isNew = false;
          t.merged = false;
        }
      }
    }
  }

  List<MergeTile?> _mergeLine(List<MergeTile?> line, {required bool reverse}) {
    var tiles = line.whereType<MergeTile>().toList();
    if (reverse) tiles = tiles.reversed.toList();

    final merged = <MergeTile>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i + 1 < tiles.length && tiles[i].value == tiles[i + 1].value) {
        final v = tiles[i].value * 2;
        merged.add(MergeTile(value: v, merged: true));
        session.addScore(v);
        i++;
      } else {
        merged.add(MergeTile(value: tiles[i].value));
      }
    }

    final oriented = reverse ? merged.reversed.toList() : merged;

    final out = List<MergeTile?>.filled(gridSize, null);
    if (reverse) {
      for (var i = 0; i < oriented.length; i++) {
        out[gridSize - oriented.length + i] = oriented[i];
      }
    } else {
      for (var i = 0; i < oriented.length; i++) {
        out[i] = oriented[i];
      }
    }
    return out;
  }

  bool _canMove() {
    for (var r = 0; r < gridSize; r++) {
      for (var c = 0; c < gridSize; c++) {
        final t = grid[r][c];
        if (t == null) return true;
        if (c + 1 < gridSize && grid[r][c + 1]?.value == t.value) return true;
        if (r + 1 < gridSize && grid[r + 1][c]?.value == t.value) return true;
      }
    }
    return false;
  }

  void disposeController() {
    session.isRunning = false;
  }

  Duration get elapsed => DateTime.now().difference(session.startTime);

  static Color tileColor(int value) {
    const colors = {
      2: Color(0xFFEEE4DA),
      4: Color(0xFFEDE0C8),
      8: Color(0xFFF2B179),
      16: Color(0xFFF59563),
      32: Color(0xFFF67C5F),
      64: Color(0xFFF65E3B),
      128: Color(0xFFEDCF72),
      256: Color(0xFFEDCC61),
      512: Color(0xFFEDC850),
      1024: Color(0xFFEDC53F),
      2048: Color(0xFFEDC22E),
    };
    return colors[value] ?? const Color(0xFF3C3A32);
  }
}
