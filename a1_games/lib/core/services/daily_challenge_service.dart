import '../../data/local/local_storage_service.dart';
import '../../models/game_model.dart';
import '../../models/game_type.dart';

class DailyChallengeService {
  DailyChallengeService(this._storage);

  final LocalStorageService _storage;

  static const int targetScore = 100;

  GameModel get todaysChallenge {
    final key = LocalStorageService.todayKey();
    var stored = _storage.getDailyChallengeGame(key);
    if (stored == null) {
      final dayOfYear = DateTime.now()
          .difference(DateTime(DateTime.now().year))
          .inDays;
      final game = GameCatalog.games[dayOfYear % GameCatalog.games.length];
      stored = game.id;
      _storage.setDailyChallengeGame(key, stored);
    }
    return GameCatalog.games.firstWhere(
      (g) => g.id == stored,
      orElse: () => GameCatalog.games.first,
    );
  }

  bool get isCompleted =>
      _storage.isDailyCompleted(LocalStorageService.todayKey());

  Future<void> markCompletedIfEligible(GameType type, int score) async {
    if (type != todaysChallenge.type) return;
    if (score < targetScore) return;
    await _storage.setDailyCompleted(LocalStorageService.todayKey(), true);
  }
}
