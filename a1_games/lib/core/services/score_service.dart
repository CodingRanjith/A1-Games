import '../../data/local/local_storage_service.dart';
import '../../models/game_model.dart';
import '../../models/game_stats_model.dart';
import '../../models/game_type.dart';

class ScoreService {
  ScoreService(this._storage);

  final LocalStorageService _storage;

  int getBestScore(GameType type) => _storage.getBestScore(type.id);

  Future<bool> saveBestScore(GameType type, int score) async {
    final isNew = _storage.isNewRecord(type.id, score);
    await _storage.saveBestScore(type.id, score);
    return isNew;
  }

  bool isNewRecord(GameType type, int score) =>
      _storage.isNewRecord(type.id, score);

  int getTotalScore() => _storage.getTotalScore();

  int getGamesPlayed([GameType? type]) {
    if (type == null) return _storage.getTotalGamesPlayed();
    return _storage.getGamesPlayed(type.id);
  }

  Future<void> recordGameResult(GameType type, int score) async {
    await _storage.saveBestScore(type.id, score);
    await _storage.incrementGamesPlayed(type.id);
    await _storage.addToTotalScore(score);
    await _storage.setLastPlayedGame(type.id);
    await _storage.updateStreak();
  }

  GameStatsModel loadStats() {
    final ids = GameCatalog.games.map((g) => g.id).toList();
    return GameStatsModel(
      bestScores: _storage.getAllBestScores(ids),
      gamesPlayed: _storage.getAllGamesPlayed(ids),
      totalScore: _storage.getTotalScore(),
      totalGamesPlayed: _storage.getTotalGamesPlayed(),
      lastPlayedGameId: _storage.getLastPlayedGame(),
      currentStreak: _storage.getCurrentStreak(),
      lastPlayDate: _storage.getLastPlayDate(),
    );
  }

  List<GameModel> gamesWithScores() {
    return GameCatalog.games
        .map(
          (g) => g.copyWith(
            bestScore: getBestScore(g.type),
            gamesPlayed: getGamesPlayed(g.type),
          ),
        )
        .toList();
  }
}
