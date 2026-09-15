import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

enum MathLevel { addSub, multiply, divide, mixed }

extension MathLevelX on MathLevel {
  String get label {
    switch (this) {
      case MathLevel.addSub:
        return 'Add/Sub';
      case MathLevel.multiply:
        return 'Multiply';
      case MathLevel.divide:
        return 'Divide';
      case MathLevel.mixed:
        return 'Mixed';
    }
  }
}

class MathQuestion {
  MathQuestion({
    required this.text,
    required this.correctAnswer,
    required this.options,
  });

  final String text;
  final int correctAnswer;
  final List<int> options;
}

class FastMathController extends ChangeNotifier {
  FastMathController();

  final Random _random = Random();

  int score = 0;
  int lives = 3;
  int questionsAnswered = 0;
  int correctCount = 0;
  int timeLeftMs = 10000;
  MathLevel level = MathLevel.addSub;
  MathQuestion? currentQuestion;
  bool isRunning = false;
  bool isGameOver = false;

  Timer? _questionTimer;
  DateTime? _questionStartedAt;

  void start() {
    if (isRunning) return;
    isRunning = true;
    isGameOver = false;
    score = 0;
    lives = 3;
    questionsAnswered = 0;
    correctCount = 0;
    level = MathLevel.addSub;

    _nextQuestion();
    notifyListeners();
  }

  void _nextQuestion() {
    _questionTimer?.cancel();
    _updateLevel();
    currentQuestion = _generateQuestion();
    timeLeftMs = 10000;
    _questionStartedAt = DateTime.now();

    _questionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!isRunning || isGameOver) return;
      timeLeftMs -= 100;
      if (timeLeftMs <= 0) {
        questionsAnswered++;
        _handleWrong();
        return;
      }
      notifyListeners();
    });

    notifyListeners();
  }

  void _updateLevel() {
    if (questionsAnswered >= 18) {
      level = MathLevel.mixed;
    } else if (questionsAnswered >= 12) {
      level = MathLevel.divide;
    } else if (questionsAnswered >= 6) {
      level = MathLevel.multiply;
    } else {
      level = MathLevel.addSub;
    }
  }

  MathQuestion _generateQuestion() {
    switch (level) {
      case MathLevel.addSub:
        return _genAddSub();
      case MathLevel.multiply:
        return _genMultiply();
      case MathLevel.divide:
        return _genDivide();
      case MathLevel.mixed:
        final pick = _random.nextInt(3);
        if (pick == 0) return _genAddSub();
        if (pick == 1) return _genMultiply();
        return _genDivide();
    }
  }

  MathQuestion _genAddSub() {
    final a = _random.nextInt(20) + 1;
    final b = _random.nextInt(20) + 1;
    final subtract = _random.nextBool();
    if (subtract && a >= b) {
      return _wrap('$a - $b', a - b);
    }
    return _wrap('$a + $b', a + b);
  }

  MathQuestion _genMultiply() {
    final a = _random.nextInt(11) + 2;
    final b = _random.nextInt(9) + 2;
    return _wrap('$a × $b', a * b);
  }

  MathQuestion _genDivide() {
    final b = _random.nextInt(8) + 2;
    final quotient = _random.nextInt(9) + 2;
    final a = b * quotient;
    return _wrap('$a ÷ $b', quotient);
  }

  MathQuestion _wrap(String text, int answer) {
    final options = <int>{answer};
    while (options.length < 4) {
      final delta = _random.nextInt(7) - 3;
      options.add((answer + delta).clamp(0, 999));
    }
    final list = options.toList()..shuffle(_random);
    return MathQuestion(text: text, correctAnswer: answer, options: list);
  }

  bool answer(int value) {
    if (!isRunning || isGameOver || currentQuestion == null) return false;

    questionsAnswered++;
    final correct = value == currentQuestion!.correctAnswer;

    if (correct) {
      correctCount++;
      final elapsed = DateTime.now().difference(_questionStartedAt!).inMilliseconds;
      final remaining = (10000 - elapsed).clamp(0, 10000);
      final speedBonus = (remaining / 1000).round();
      score += 10 + speedBonus;
      _nextQuestion();
      return true;
    }

    _handleWrong();
    return false;
  }

  void _handleWrong() {
    lives--;
    if (lives <= 0) {
      _endGame();
      return;
    }
    timeLeftMs = (timeLeftMs - 2000).clamp(1000, 10000);
    _nextQuestion();
  }

  void _endGame() {
    isGameOver = true;
    isRunning = false;
    currentQuestion = null;
    _questionTimer?.cancel();
    _questionTimer = null;
    notifyListeners();
  }

  double? get accuracy =>
      questionsAnswered > 0 ? (correctCount / questionsAnswered) * 100 : null;

  String get timerText => '${(timeLeftMs / 1000).ceil()}s';

  void disposeController() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  @override
  void dispose() {
    disposeController();
    super.dispose();
  }
}
