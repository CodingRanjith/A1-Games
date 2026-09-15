import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/game_session.dart';
import 'movie_finder_data.dart';

enum MovieAnswerState { idle, correct, wrong }

class MovieRound {
  MovieRound({
    required this.clue,
    required this.options,
  });

  final MovieClue clue;
  final List<String> options;
  MovieAnswerState state = MovieAnswerState.idle;
  String? selectedOption;
  int pointsEarned = 0;
}

class MovieFinderController extends ChangeNotifier {
  MovieFinderController();

  final GameSession session = GameSession(lives: 3);
  final Random _random = Random();

  List<MovieRound> rounds = [];
  int currentRoundIndex = 0;
  DateTime? _roundStart;
  Timer? _roundTimer;
  int roundSecondsLeft = 15;

  bool revealNext = false;

  int get score => session.score;
  bool get isGameOver => session.isGameOver;
  bool get isRunning => session.isRunning;
  int get lives => session.lives;
  int get combo => session.combo;
  int get roundsCompleted => currentRoundIndex;

  MovieRound? get currentRound =>
      currentRoundIndex < rounds.length ? rounds[currentRoundIndex] : null;

  double get accuracy {
    if (rounds.isEmpty) return 0;
    final answered = rounds.where((r) => r.state != MovieAnswerState.idle).length;
    if (answered == 0) return 0;
    final correct =
        rounds.where((r) => r.state == MovieAnswerState.correct).length;
    return (correct / answered) * 100;
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

    final pool = List<MovieClue>.from(MovieFinderData.clues)..shuffle(_random);
    final selected = pool.take(MovieFinderData.totalRounds).toList();
    rounds = selected
        .map(
          (c) => MovieRound(
            clue: c,
            options: MovieFinderData.buildOptions(c, _random),
          ),
        )
        .toList();
    currentRoundIndex = 0;
    revealNext = false;
    _beginRoundTimer();
    notifyListeners();
  }

  void _beginRoundTimer() {
    _roundTimer?.cancel();
    roundSecondsLeft = 15;
    _roundStart = DateTime.now();
    _roundTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!session.isRunning || session.isGameOver || revealNext) return;
      roundSecondsLeft--;
      if (roundSecondsLeft <= 0) {
        _handleTimeout();
      }
      notifyListeners();
    });
  }

  void _handleTimeout() {
    if (revealNext || currentRound == null) return;
    final round = currentRound!;
    if (round.state != MovieAnswerState.idle) return;

    round
      ..state = MovieAnswerState.wrong
      ..selectedOption = null
      ..pointsEarned = 0;
    session.loseLife();
    revealNext = true;
    _roundTimer?.cancel();
    notifyListeners();
  }

  void selectOption(String option) {
    if (!session.isRunning ||
        session.isGameOver ||
        revealNext ||
        currentRound == null) {
      return;
    }

    final round = currentRound!;
    if (round.state != MovieAnswerState.idle) return;

    final elapsed = DateTime.now().difference(_roundStart ?? DateTime.now());
    final speedBonus = ((15 - elapsed.inSeconds).clamp(0, 10)) * 2;
    final isCorrect = round.clue.matches(option);

    round.selectedOption = option;
    _roundTimer?.cancel();

    if (isCorrect) {
      round.state = MovieAnswerState.correct;
      final comboBonus = session.combo * 3;
      round.pointsEarned = 15 + speedBonus + comboBonus;
      session.addScore(round.pointsEarned);
    } else {
      round.state = MovieAnswerState.wrong;
      round.pointsEarned = 0;
      session.loseLife();
    }

    revealNext = true;
    notifyListeners();
  }

  void nextRound() {
    if (!revealNext) return;

    currentRoundIndex++;
    revealNext = false;

    if (currentRoundIndex >= rounds.length || session.isGameOver) {
      session.endGame();
      _roundTimer?.cancel();
    } else {
      _beginRoundTimer();
    }
    notifyListeners();
  }

  String get timerText {
    final s = roundSecondsLeft.clamp(0, 99);
    return '0:${s.toString().padLeft(2, '0')}';
  }

  void disposeController() {
    _roundTimer?.cancel();
    session.isRunning = false;
  }
}
