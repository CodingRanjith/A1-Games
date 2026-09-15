import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../models/game_session.dart';
import 'word_hunt_data.dart';

enum WordHuntCellState { normal, selected, found, wrongFlash }

class WordHuntPlacedWord {
  WordHuntPlacedWord({
    required this.word,
    required this.cells,
    this.transliteration,
  });

  final String word;
  final List<int> cells;
  final String? transliteration;
  bool found = false;
}

class WordHuntController extends ChangeNotifier {
  WordHuntController();

  static const gameDuration = Duration(seconds: 90);

  final GameSession session = GameSession(lives: 99);
  final Random _random = Random();

  WordHuntLanguage language = WordHuntLanguage.english;
  List<List<String>> grid = [];
  List<WordHuntPlacedWord> words = [];
  List<int> selectedCells = [];
  Map<int, WordHuntCellState> cellStates = {};
  bool useTransliteration = false;

  Timer? _timer;
  int secondsLeft = gameDuration.inSeconds;
  Duration elapsed = Duration.zero;

  bool wrongFlashActive = false;

  int get score => session.score;
  bool get isGameOver => session.isGameOver;
  bool get isRunning => session.isRunning;
  int get gridSize => language.gridSize;
  int get wordsFound => words.where((w) => w.found).length;
  int get totalWords => words.length;

  void setLanguage(WordHuntLanguage lang, {bool transliteration = false}) {
    language = lang;
    useTransliteration = transliteration;
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
    secondsLeft = gameDuration.inSeconds;
    elapsed = Duration.zero;
    selectedCells = [];
    cellStates = {};
    wrongFlashActive = false;
    _generateGrid();
    _startTimer();
    notifyListeners();
  }

  void _generateGrid() {
    final size = gridSize;
    grid = List.generate(size, (_) => List.filled(size, ''));
    words = [];

    final pool = List<WordHuntEntry>.from(WordHuntData.entriesFor(language))
      ..shuffle(_random);
    final count = language.wordCount;
    final candidates = pool.where((e) => e.word.length <= size).take(count * 3).toList();

    var placed = 0;
    for (final entry in candidates) {
      if (placed >= count) break;
      final cells = _tryPlaceWord(entry.word);
      if (cells != null) {
        words.add(
          WordHuntPlacedWord(
            word: entry.word,
            cells: cells,
            transliteration: entry.transliteration,
          ),
        );
        placed++;
      }
    }

    if (words.length < 4) {
      _generateGrid();
      return;
    }

    final letters = WordHuntData.lettersFor(language);
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c].isEmpty) {
          grid[r][c] = letters[_random.nextInt(letters.length)];
        }
      }
    }
  }

  List<int>? _tryPlaceWord(String word) {
    final size = gridSize;
    final directions = [
      (0, 1),
      (1, 0),
      (1, 1),
      (-1, 1),
    ];

    final attempts = 80;
    for (var i = 0; i < attempts; i++) {
      final dir = directions[_random.nextInt(directions.length)];
      final row = _random.nextInt(size);
      final col = _random.nextInt(size);
      final cells = <int>[];
      var ok = true;

      for (var k = 0; k < word.length; k++) {
        final r = row + dir.$1 * k;
        final c = col + dir.$2 * k;
        if (r < 0 || r >= size || c < 0 || c >= size) {
          ok = false;
          break;
        }
        final existing = grid[r][c];
        if (existing.isNotEmpty && existing != word[k]) {
          ok = false;
          break;
        }
        cells.add(r * size + c);
      }

      if (!ok) continue;

      for (var k = 0; k < word.length; k++) {
        final idx = cells[k];
        final r = idx ~/ size;
        final c = idx % size;
        grid[r][c] = word[k];
      }
      return cells;
    }
    return null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!session.isRunning || session.isGameOver) return;
      secondsLeft--;
      elapsed = gameDuration - Duration(seconds: secondsLeft);
      if (secondsLeft <= 0) {
        _endWithTimeBonus();
      }
      notifyListeners();
    });
  }

  void _endWithTimeBonus() {
    final bonus = secondsLeft.clamp(0, 90) == 0
        ? 0
        : (wordsFound * 5).clamp(0, 50);
    if (bonus > 0) session.addScore(bonus);
    session.endGame();
    _timer?.cancel();
    notifyListeners();
  }

  int cellIndex(int row, int col) => row * gridSize + col;

  (int, int) cellRowCol(int index) => (index ~/ gridSize, index % gridSize);

  bool isAdjacent(int a, int b) {
    final (ar, ac) = cellRowCol(a);
    final (br, bc) = cellRowCol(b);
    final dr = (ar - br).abs();
    final dc = (ac - bc).abs();
    return dr <= 1 && dc <= 1 && (dr + dc) > 0;
  }

  bool isInLine(List<int> cells) {
    if (cells.length < 2) return true;
    final points = cells.map(cellRowCol).toList();
    final dr = points[1].$1 - points[0].$1;
    final dc = points[1].$2 - points[0].$2;
    if (dr == 0 && dc == 0) return false;

    for (var i = 2; i < points.length; i++) {
      final stepR = points[i].$1 - points[i - 1].$1;
      final stepC = points[i].$2 - points[i - 1].$2;
      if (stepR != dr || stepC != dc) return false;
    }
    return true;
  }

  String selectedWord() {
    final buffer = StringBuffer();
    for (final idx in selectedCells) {
      final (r, c) = cellRowCol(idx);
      buffer.write(grid[r][c]);
    }
    return buffer.toString();
  }

  void beginSelection(int index) {
    if (!session.isRunning || session.isGameOver) return;
    if (cellStates[index] == WordHuntCellState.found) return;
    selectedCells = [index];
    _refreshSelectionStates();
    notifyListeners();
  }

  void extendSelection(int index) {
    if (!session.isRunning || session.isGameOver || selectedCells.isEmpty) {
      return;
    }
    if (cellStates[index] == WordHuntCellState.found) return;
    if (selectedCells.contains(index)) {
      if (selectedCells.length > 1 && selectedCells.last == index) {
        selectedCells.removeLast();
        _refreshSelectionStates();
        notifyListeners();
      }
      return;
    }

    final last = selectedCells.last;
    if (!isAdjacent(last, index)) return;

    final trial = [...selectedCells, index];
    if (!isInLine(trial)) return;

    selectedCells = trial;
    _refreshSelectionStates();
    notifyListeners();
  }

  void endSelection() {
    if (selectedCells.isEmpty) return;
    _validateSelection();
  }

  void _refreshSelectionStates() {
    cellStates.removeWhere((_, s) => s == WordHuntCellState.selected);
    for (final idx in selectedCells) {
      if (cellStates[idx] != WordHuntCellState.found) {
        cellStates[idx] = WordHuntCellState.selected;
      }
    }
  }

  void _validateSelection() {
    final raw = selectedWord();
    final normalized = language == WordHuntLanguage.english
        ? raw.toUpperCase()
        : raw;
    final reversed = normalized.split('').reversed.join();

    WordHuntPlacedWord? match;
    for (final w in words) {
      if (w.found) continue;
      if (_matchesWord(w, normalized) || _matchesWord(w, reversed)) {
        match = w;
        break;
      }
    }

    if (match != null) {
      match.found = true;
      for (final idx in match.cells) {
        cellStates[idx] = WordHuntCellState.found;
      }
      final base = 100 + match.word.length * 10;
      session.addScore(base);
      selectedCells = [];
      if (wordsFound >= totalWords) {
        final timeBonus = (secondsLeft * 2).clamp(0, 120);
        session.addScore(timeBonus);
        session.endGame();
        _timer?.cancel();
      }
    } else {
      wrongFlashActive = true;
      for (final idx in selectedCells) {
        if (cellStates[idx] != WordHuntCellState.found) {
          cellStates[idx] = WordHuntCellState.wrongFlash;
        }
      }
      session.resetCombo();
      notifyListeners();
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        wrongFlashActive = false;
        selectedCells = [];
        cellStates.removeWhere((_, s) =>
            s == WordHuntCellState.wrongFlash ||
            s == WordHuntCellState.selected);
        notifyListeners();
      });
      selectedCells = [];
      notifyListeners();
      return;
    }

    selectedCells = [];
    notifyListeners();
  }

  bool _matchesWord(WordHuntPlacedWord w, String attempt) {
    if (w.word == attempt) return true;
    if (useTransliteration &&
        w.transliteration != null &&
        w.transliteration!.toUpperCase() == attempt.toUpperCase()) {
      return true;
    }
    return false;
  }

  String get timerText {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String displayWord(WordHuntPlacedWord w) {
    if (useTransliteration && w.transliteration != null) {
      return '${w.word} (${w.transliteration})';
    }
    return w.word;
  }

  void disposeController() {
    _timer?.cancel();
    session.isRunning = false;
  }
}
