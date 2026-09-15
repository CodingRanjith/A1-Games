import 'package:flutter/services.dart';

import '../../data/local/local_storage_service.dart';

class HapticService {
  HapticService(this._storage);

  final LocalStorageService _storage;

  bool get enabled => _storage.getVibrationEnabled();

  Future<void> light() async {
    if (!enabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (!enabled) return;
    await HapticFeedback.heavyImpact();
  }

  Future<void> selection() async {
    if (!enabled) return;
    await HapticFeedback.selectionClick();
  }
}
