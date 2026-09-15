class GameSession {
  GameSession({
    this.score = 0,
    this.combo = 0,
    this.maxCombo = 0,
    this.lives = 3,
    this.isRunning = false,
    this.isPaused = false,
    this.isGameOver = false,
    this.isCountingDown = false,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  int score;
  int combo;
  int maxCombo;
  int lives;
  bool isRunning;
  bool isPaused;
  bool isGameOver;
  bool isCountingDown;
  DateTime startTime;
  Duration elapsedTime = Duration.zero;

  void addScore(int points) {
    score += points;
    if (points > 0) {
      combo += 1;
      if (combo > maxCombo) maxCombo = combo;
    } else {
      combo = 0;
    }
  }

  void resetCombo() => combo = 0;

  void loseLife() {
    lives = (lives - 1).clamp(0, 99);
    combo = 0;
    if (lives <= 0) {
      isGameOver = true;
      isRunning = false;
    }
  }

  void pause() {
    if (isRunning && !isGameOver) isPaused = true;
  }

  void resume() {
    if (isPaused && !isGameOver) isPaused = false;
  }

  void endGame() {
    isGameOver = true;
    isRunning = false;
    isPaused = false;
  }

  Duration get elapsed {
    if (!isRunning && elapsedTime == Duration.zero) {
      return DateTime.now().difference(startTime);
    }
    return elapsedTime;
  }
}

class ScoreResult {
  const ScoreResult({
    required this.score,
    required this.bestScore,
    required this.isNewRecord,
    this.accuracy,
    this.maxCombo,
    this.moves,
    this.elapsed,
    this.extraStats = const {},
  });

  final int score;
  final int bestScore;
  final bool isNewRecord;
  final double? accuracy;
  final int? maxCombo;
  final int? moves;
  final Duration? elapsed;
  final Map<String, String> extraStats;
}
