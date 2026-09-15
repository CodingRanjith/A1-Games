import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/game_session.dart';

enum MemoryDifficulty { easy, medium, hard }

extension MemoryDifficultyX on MemoryDifficulty {
  int get pairCount {
    switch (this) {
      case MemoryDifficulty.easy:
        return 4;
      case MemoryDifficulty.medium:
        return 6;
      case MemoryDifficulty.hard:
        return 8;
    }
  }

  int get columns {
    switch (this) {
      case MemoryDifficulty.easy:
        return 4;
      case MemoryDifficulty.medium:
        return 4;
      case MemoryDifficulty.hard:
        return 4;
    }
  }
}

class MemoryCard {
  MemoryCard({
    required this.id,
    required this.pairId,
    required this.icon,
    required this.color,
  });

  final int id;
  final int pairId;
  final IconData icon;
  final Color color;

  bool isFlipped = false;
  bool isMatched = false;
}

class MemoryCardsController extends ChangeNotifier {
  MemoryCardsController({this.difficulty = MemoryDifficulty.easy});

  MemoryDifficulty difficulty;
  final GameSession session = GameSession(lives: 99);
  final Random _random = Random();

  List<MemoryCard> cards = [];
  int? firstSelectedId;
  int? secondSelectedId;
  int moves = 0;
  bool isChecking = false;
  int matchedPairs = 0;

  Timer? _elapsedTimer;
  Duration elapsed = Duration.zero;

  static const _icons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.bolt_rounded,
    Icons.eco_rounded,
    Icons.pets_rounded,
    Icons.music_note_rounded,
    Icons.wb_sunny_rounded,
    Icons.rocket_launch_rounded,
  ];

  static const _colors = [
    Color(0xFFE63946),
    Color(0xFF4361EE),
    Color(0xFF2D9F6F),
    Color(0xFFFFB703),
    Color(0xFF9B5DE5),
    Color(0xFF00BBF9),
    Color(0xFFF15BB5),
    Color(0xFF00F5D4),
  ];

  int get score => session.score;
  bool get isGameOver => session.isGameOver;
  bool get isRunning => session.isRunning;
  int get pairCount => difficulty.pairCount;

  void setDifficulty(MemoryDifficulty d) {
    difficulty = d;
    notifyListeners();
  }

  void startGame() {
    session
      ..score = 0
      ..combo = 0
      ..maxCombo = 0
      ..isGameOver = false
      ..isRunning = true
      ..startTime = DateTime.now();
    moves = 0;
    matchedPairs = 0;
    firstSelectedId = null;
    secondSelectedId = null;
    isChecking = false;
    elapsed = Duration.zero;
    _buildDeck();
    _startElapsedTimer();
    notifyListeners();
  }

  void _buildDeck() {
    final pairs = difficulty.pairCount;
    final deck = <MemoryCard>[];
    var id = 0;
    for (var p = 0; p < pairs; p++) {
      deck.add(
        MemoryCard(
          id: id++,
          pairId: p,
          icon: _icons[p % _icons.length],
          color: _colors[p % _colors.length],
        ),
      );
      deck.add(
        MemoryCard(
          id: id++,
          pairId: p,
          icon: _icons[p % _icons.length],
          color: _colors[p % _colors.length],
        ),
      );
    }
    deck.shuffle(_random);
    cards = deck;
  }

  void _startElapsedTimer() {
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!session.isRunning || session.isGameOver) return;
      elapsed = DateTime.now().difference(session.startTime);
      notifyListeners();
    });
  }

  MemoryCard? cardById(int id) {
    try {
      return cards.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> flipCard(int id) async {
    if (!session.isRunning ||
        session.isGameOver ||
        isChecking ||
        firstSelectedId == id) {
      return;
    }

    final card = cardById(id);
    if (card == null || card.isMatched || card.isFlipped) return;

    card.isFlipped = true;
    notifyListeners();

    if (firstSelectedId == null) {
      firstSelectedId = id;
      return;
    }

    secondSelectedId = id;
    moves++;
    isChecking = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final first = cardById(firstSelectedId!);
    final second = cardById(secondSelectedId!);

    if (first != null && second != null && first.pairId == second.pairId) {
      first.isMatched = true;
      second.isMatched = true;
      matchedPairs++;
      session.addScore(50);
      if (matchedPairs >= pairCount) {
        session.endGame();
      }
    } else {
      first?.isFlipped = false;
      second?.isFlipped = false;
      session.resetCombo();
    }

    firstSelectedId = null;
    secondSelectedId = null;
    isChecking = false;
    notifyListeners();
  }

  void disposeController() {
    _elapsedTimer?.cancel();
    session.isRunning = false;
  }

  String get timerText {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
