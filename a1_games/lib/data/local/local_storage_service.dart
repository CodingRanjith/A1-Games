import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight offline persistence. No backend.
class LocalStorageService {
  LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  static const _prefixBest = 'best_score_';
  static const _prefixPlayed = 'games_played_';
  static const _keyTotalScore = 'total_score';
  static const _keyTotalPlayed = 'total_games_played';
  static const _keySound = 'setting_sound';
  static const _keyVibration = 'setting_vibration';
  static const _keyTheme = 'setting_theme';
  static const _keyOnboarding = 'onboarding_done';
  static const _keyLastPlayed = 'last_played_game';
  static const _keyStreak = 'current_streak';
  static const _keyLastPlayDate = 'last_play_date';
  static const _keyDailyChallenge = 'daily_challenge_';
  static const _keyDailyCompleted = 'daily_completed_';
  static const _keyRacerCoins = 'racer_bank_coins';
  static const _keyRacerCar = 'racer_selected_car';
  static const _keyRacerUnlocked = 'racer_unlocked_cars';
  static const _keyRacerUpgrades = 'racer_upgrades';

  // ── Scores ──────────────────────────────────────────

  Future<void> saveBestScore(String gameId, int score) async {
    final current = getBestScore(gameId);
    if (score > current) {
      await _prefs.setInt('$_prefixBest$gameId', score);
    }
  }

  int getBestScore(String gameId) =>
      _prefs.getInt('$_prefixBest$gameId') ?? 0;

  bool isNewRecord(String gameId, int score) =>
      score > getBestScore(gameId);

  Future<void> incrementGamesPlayed(String gameId) async {
    final count = getGamesPlayed(gameId) + 1;
    await _prefs.setInt('$_prefixPlayed$gameId', count);
    await _prefs.setInt(
      _keyTotalPlayed,
      getTotalGamesPlayed() + 1,
    );
  }

  int getGamesPlayed(String gameId) =>
      _prefs.getInt('$_prefixPlayed$gameId') ?? 0;

  int getTotalGamesPlayed() => _prefs.getInt(_keyTotalPlayed) ?? 0;

  Future<void> addToTotalScore(int score) async {
    await _prefs.setInt(_keyTotalScore, getTotalScore() + score);
  }

  int getTotalScore() => _prefs.getInt(_keyTotalScore) ?? 0;

  Map<String, int> getAllBestScores(List<String> gameIds) {
    return {for (final id in gameIds) id: getBestScore(id)};
  }

  Map<String, int> getAllGamesPlayed(List<String> gameIds) {
    return {for (final id in gameIds) id: getGamesPlayed(id)};
  }

  // ── Settings ────────────────────────────────────────

  Future<void> setSoundEnabled(bool value) =>
      _prefs.setBool(_keySound, value);

  bool getSoundEnabled() => _prefs.getBool(_keySound) ?? true;

  Future<void> setVibrationEnabled(bool value) =>
      _prefs.setBool(_keyVibration, value);

  bool getVibrationEnabled() => _prefs.getBool(_keyVibration) ?? true;

  /// 0 = system, 1 = light, 2 = dark
  Future<void> setThemeMode(int mode) => _prefs.setInt(_keyTheme, mode);

  int getThemeMode() => _prefs.getInt(_keyTheme) ?? 0;

  Future<void> setOnboardingDone(bool value) =>
      _prefs.setBool(_keyOnboarding, value);

  bool isOnboardingDone() => _prefs.getBool(_keyOnboarding) ?? false;

  Future<void> setLastPlayedGame(String gameId) =>
      _prefs.setString(_keyLastPlayed, gameId);

  String? getLastPlayedGame() => _prefs.getString(_keyLastPlayed);

  // ── Streak ──────────────────────────────────────────

  Future<void> updateStreak() async {
    final today = _dateKey(DateTime.now());
    final last = _prefs.getString(_keyLastPlayDate);
    if (last == today) return;

    final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
    final streak = last == yesterday ? getCurrentStreak() + 1 : 1;
    await _prefs.setInt(_keyStreak, streak);
    await _prefs.setString(_keyLastPlayDate, today);
  }

  int getCurrentStreak() => _prefs.getInt(_keyStreak) ?? 0;

  String? getLastPlayDate() => _prefs.getString(_keyLastPlayDate);

  // ── Daily challenge ─────────────────────────────────

  Future<void> setDailyChallengeGame(String dateKey, String gameId) =>
      _prefs.setString('$_keyDailyChallenge$dateKey', gameId);

  String? getDailyChallengeGame(String dateKey) =>
      _prefs.getString('$_keyDailyChallenge$dateKey');

  Future<void> setDailyCompleted(String dateKey, bool value) =>
      _prefs.setBool('$_keyDailyCompleted$dateKey', value);

  bool isDailyCompleted(String dateKey) =>
      _prefs.getBool('$_keyDailyCompleted$dateKey') ?? false;

  // ── City Racer garage (offline) ─────────────────────

  int getRacerCoins() => _prefs.getInt(_keyRacerCoins) ?? 0;

  Future<void> setRacerCoins(int value) =>
      _prefs.setInt(_keyRacerCoins, value);

  String getSelectedRacerCar() =>
      _prefs.getString(_keyRacerCar) ?? 'ember_gt';

  Future<void> setSelectedRacerCar(String id) =>
      _prefs.setString(_keyRacerCar, id);

  Set<String> getUnlockedRacerCars() {
    final raw = _prefs.getString(_keyRacerUnlocked) ?? 'ember_gt';
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  Future<void> setUnlockedRacerCars(Set<String> ids) =>
      _prefs.setString(_keyRacerUnlocked, ids.join(','));

  String getRacerUpgrades() => _prefs.getString(_keyRacerUpgrades) ?? '';

  Future<void> setRacerUpgrades(String raw) =>
      _prefs.setString(_keyRacerUpgrades, raw);

  // ── Reset ───────────────────────────────────────────

  Future<void> resetAllData() async {
    final sound = getSoundEnabled();
    final vibration = getVibrationEnabled();
    final theme = getThemeMode();
    await _prefs.clear();
    await setSoundEnabled(sound);
    await setVibrationEnabled(vibration);
    await setThemeMode(theme);
    await setOnboardingDone(true);
  }

  Future<void> saveSetting(String key, Object value) async {
    if (value is bool) {
      await _prefs.setBool(key, value);
    } else if (value is int) {
      await _prefs.setInt(key, value);
    } else if (value is String) {
      await _prefs.setString(key, value);
    } else if (value is double) {
      await _prefs.setDouble(key, value);
    }
  }

  T? getSetting<T>(String key) {
    final value = _prefs.get(key);
    if (value is T) return value;
    return null;
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String todayKey() => _dateKey(DateTime.now());
}
