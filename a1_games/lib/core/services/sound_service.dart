import '../../data/local/local_storage_service.dart';

/// Sound abstraction. Place audio files under assets/sounds/ when ready.
/// Filenames expected: tap.mp3, success.mp3, fail.mp3, combo.mp3, game_over.mp3
class SoundService {
  SoundService(this._storage);

  final LocalStorageService _storage;

  bool get enabled => _storage.getSoundEnabled();

  /// No-op until real assets are wired via audioplayers.
  Future<void> playTap() async {
    if (!enabled) return;
  }

  Future<void> playSuccess() async {
    if (!enabled) return;
  }

  Future<void> playFail() async {
    if (!enabled) return;
  }

  Future<void> playCombo() async {
    if (!enabled) return;
  }

  Future<void> playGameOver() async {
    if (!enabled) return;
  }

  Future<void> playCountdown() async {
    if (!enabled) return;
  }

  void dispose() {}
}
