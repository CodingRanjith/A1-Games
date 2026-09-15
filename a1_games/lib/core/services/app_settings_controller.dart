import 'package:flutter/material.dart';

import '../../data/local/local_storage_service.dart';
import 'haptic_service.dart';
import 'score_service.dart';
import 'sound_service.dart';

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({
    required LocalStorageService storage,
    required this.scoreService,
    required HapticService hapticService,
    required SoundService soundService,
  })  : _storage = storage,
        haptic = hapticService,
        sound = soundService {
    _soundEnabled = storage.getSoundEnabled();
    _vibrationEnabled = storage.getVibrationEnabled();
    _themeModeIndex = storage.getThemeMode();
  }

  final LocalStorageService _storage;
  final ScoreService scoreService;
  final HapticService haptic;
  final SoundService sound;

  late bool _soundEnabled;
  late bool _vibrationEnabled;
  late int _themeModeIndex;

  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  ThemeMode get themeMode {
    switch (_themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  int get themeModeIndex => _themeModeIndex;

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _storage.setSoundEnabled(value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    _vibrationEnabled = value;
    await _storage.setVibrationEnabled(value);
    notifyListeners();
  }

  Future<void> setThemeModeIndex(int index) async {
    _themeModeIndex = index;
    await _storage.setThemeMode(index);
    notifyListeners();
  }

  Future<void> resetProgress() async {
    await _storage.resetAllData();
    notifyListeners();
  }

  void refresh() => notifyListeners();
}
