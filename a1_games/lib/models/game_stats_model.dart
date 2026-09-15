class GameStatsModel {
  const GameStatsModel({
    this.bestScores = const {},
    this.gamesPlayed = const {},
    this.totalScore = 0,
    this.totalGamesPlayed = 0,
    this.lastPlayedGameId,
    this.currentStreak = 0,
    this.lastPlayDate,
  });

  final Map<String, int> bestScores;
  final Map<String, int> gamesPlayed;
  final int totalScore;
  final int totalGamesPlayed;
  final String? lastPlayedGameId;
  final int currentStreak;
  final String? lastPlayDate;

  int bestFor(String gameId) => bestScores[gameId] ?? 0;
  int playedFor(String gameId) => gamesPlayed[gameId] ?? 0;

  int get sumOfBestScores =>
      bestScores.values.fold(0, (a, b) => a + b);

  String? get favoriteGameId {
    if (gamesPlayed.isEmpty) return null;
    final sorted = gamesPlayed.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String? get topScoreGameId {
    if (bestScores.isEmpty) return null;
    final sorted = bestScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  List<MapEntry<String, int>> get topScores {
    final sorted = bestScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).toList();
  }

  GameStatsModel copyWith({
    Map<String, int>? bestScores,
    Map<String, int>? gamesPlayed,
    int? totalScore,
    int? totalGamesPlayed,
    String? lastPlayedGameId,
    int? currentStreak,
    String? lastPlayDate,
  }) {
    return GameStatsModel(
      bestScores: bestScores ?? this.bestScores,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      totalScore: totalScore ?? this.totalScore,
      totalGamesPlayed: totalGamesPlayed ?? this.totalGamesPlayed,
      lastPlayedGameId: lastPlayedGameId ?? this.lastPlayedGameId,
      currentStreak: currentStreak ?? this.currentStreak,
      lastPlayDate: lastPlayDate ?? this.lastPlayDate,
    );
  }
}
