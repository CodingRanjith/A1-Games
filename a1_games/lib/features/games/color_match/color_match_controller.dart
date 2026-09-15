import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/game_session.dart';

enum MatchShape { circle, square, triangle, diamond, star, hexagon }

class ColorOption {
  ColorOption({
    required this.color,
    required this.shape,
    required this.id,
  });

  final Color color;
  final MatchShape shape;
  final int id;
}

class ColorMatchController extends ChangeNotifier {
  ColorMatchController({this.roundDurationSeconds = 60});

  final int roundDurationSeconds;
  final GameSession session = GameSession(lives: 3);
  final Random _random = Random();

  static const _palette = [
    Color(0xFFE63946),
    Color(0xFF4361EE),
    Color(0xFF2D9F6F),
    Color(0xFFFFB703),
    Color(0xFF9B5DE5),
    Color(0xFF00BBF9),
  ];

  ColorOption? target;
  List<ColorOption> options = [];
  int secondsLeft = 60;
  int correctCount = 0;
  int wrongCount = 0;

  Timer? _timer;

  int get score => session.score;
  int get combo => session.combo;
  int get maxCombo => session.maxCombo;
  int get lives => session.lives;
  bool get isGameOver => session.isGameOver;
  bool get isRunning => session.isRunning;

  double? get accuracy {
    final total = correctCount + wrongCount;
    if (total == 0) return null;
    return correctCount / total * 100;
  }

  void startGame() {
    session
      ..score = 0
      ..combo = 0
      ..maxCombo = 0
      ..lives = 3
      ..isGameOver = false
      ..isRunning = true
      ..startTime = DateTime.now();
    correctCount = 0;
    wrongCount = 0;
    secondsLeft = roundDurationSeconds;
    _nextRound();
    _startTimer();
    notifyListeners();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!session.isRunning || session.isGameOver) {
        t.cancel();
        return;
      }
      secondsLeft--;
      if (secondsLeft <= 0) {
        session.endGame();
        t.cancel();
      }
      notifyListeners();
    });
  }

  void _nextRound() {
    final shape = MatchShape.values[_random.nextInt(MatchShape.values.length)];
    final color = _palette[_random.nextInt(_palette.length)];
    target = ColorOption(color: color, shape: shape, id: 0);

    final optionCount = 4 + _random.nextInt(3);
    final set = <ColorOption>{target!};
    var id = 1;
    while (set.length < optionCount) {
      final s = MatchShape.values[_random.nextInt(MatchShape.values.length)];
      final c = _palette[_random.nextInt(_palette.length)];
      final opt = ColorOption(color: c, shape: s, id: id++);
      if (opt.color == target!.color && opt.shape == target!.shape) continue;
      set.add(opt);
    }
    options = set.toList()..shuffle(_random);
    notifyListeners();
  }

  bool selectOption(ColorOption option) {
    if (!session.isRunning || session.isGameOver || target == null) {
      return false;
    }

    final match =
        option.color == target!.color && option.shape == target!.shape;

    if (match) {
      correctCount++;
      session.addScore(10 + session.combo);
      _nextRound();
      notifyListeners();
      return true;
    }

    wrongCount++;
    session.addScore(-5);
    session.loseLife();
    if (!session.isGameOver) _nextRound();
    notifyListeners();
    return false;
  }

  void disposeController() {
    _timer?.cancel();
    session.isRunning = false;
  }

  Duration get elapsed => DateTime.now().difference(session.startTime);

  String get timerText {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
