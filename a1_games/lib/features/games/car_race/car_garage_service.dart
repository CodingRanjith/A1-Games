import 'package:flutter/foundation.dart';

import '../../../data/local/local_storage_service.dart';
import 'car_catalog.dart';

class CarUpgrades {
  const CarUpgrades({this.engine = 0, this.nitro = 0});

  final int engine;
  final int nitro;

  static const int maxLevel = 5;

  CarUpgrades copyWith({int? engine, int? nitro}) => CarUpgrades(
        engine: engine ?? this.engine,
        nitro: nitro ?? this.nitro,
      );
}

/// Offline garage: coins, selected car, unlocks, upgrades.
class CarGarageService extends ChangeNotifier {
  CarGarageService(this._storage) {
    _load();
  }

  final LocalStorageService _storage;

  int coins = 0;
  String selectedCarId = 'ember_gt';
  String focusedCarId = 'ember_gt';
  Set<String> unlocked = {'ember_gt'};
  final Map<String, CarUpgrades> upgrades = {};

  RaceCarSpec get selectedCar => CarCatalog.byId(selectedCarId);

  RaceCarSpec get focusedCar => CarCatalog.byId(focusedCarId);

  CarUpgrades upgradesFor(String id) => upgrades[id] ?? const CarUpgrades();

  bool isUnlocked(String id) => unlocked.contains(id);

  int engineCost(String id) {
    final level = upgradesFor(id).engine;
    return 25 * (level + 1);
  }

  int nitroCost(String id) {
    final level = upgradesFor(id).nitro;
    return 20 * (level + 1);
  }

  void _load() {
    coins = _storage.getRacerCoins();
    selectedCarId = _storage.getSelectedRacerCar();
    unlocked = _storage.getUnlockedRacerCars();
    if (!unlocked.contains('ember_gt')) {
      unlocked.add('ember_gt');
    }
    upgrades
      ..clear()
      ..addAll(_parseUpgrades(_storage.getRacerUpgrades()));
    if (!unlocked.contains(selectedCarId)) {
      selectedCarId = 'ember_gt';
    }
    focusedCarId = selectedCarId;
  }

  Future<void> focusCar(String id) async {
    focusedCarId = id;
    if (isUnlocked(id)) {
      selectedCarId = id;
      await _storage.setSelectedRacerCar(id);
    }
    notifyListeners();
  }

  Future<void> selectCar(String id) => focusCar(id);

  Future<bool> unlockCar(String id) async {
    final spec = CarCatalog.byId(id);
    if (isUnlocked(id)) return true;
    if (coins < spec.cost) return false;
    coins -= spec.cost;
    unlocked.add(id);
    selectedCarId = id;
    focusedCarId = id;
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> addCoins(int amount) async {
    if (amount <= 0) return;
    coins += amount;
    await _storage.setRacerCoins(coins);
    notifyListeners();
  }

  Future<bool> upgradeEngine(String id) async {
    final current = upgradesFor(id);
    if (current.engine >= CarUpgrades.maxLevel) return false;
    final cost = engineCost(id);
    if (coins < cost) return false;
    coins -= cost;
    upgrades[id] = current.copyWith(engine: current.engine + 1);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<bool> upgradeNitro(String id) async {
    final current = upgradesFor(id);
    if (current.nitro >= CarUpgrades.maxLevel) return false;
    final cost = nitroCost(id);
    if (coins < cost) return false;
    coins -= cost;
    upgrades[id] = current.copyWith(nitro: current.nitro + 1);
    await _persist();
    notifyListeners();
    return true;
  }

  Future<void> _persist() async {
    await _storage.setRacerCoins(coins);
    await _storage.setSelectedRacerCar(selectedCarId);
    await _storage.setUnlockedRacerCars(unlocked);
    await _storage.setRacerUpgrades(_serializeUpgrades());
  }

  Map<String, CarUpgrades> _parseUpgrades(String raw) {
    final out = <String, CarUpgrades>{};
    if (raw.isEmpty) return out;
    for (final part in raw.split(';')) {
      if (part.isEmpty) continue;
      final kv = part.split(':');
      if (kv.length != 2) continue;
      final nums = kv[1].split(',');
      if (nums.length != 2) continue;
      out[kv[0]] = CarUpgrades(
        engine: int.tryParse(nums[0]) ?? 0,
        nitro: int.tryParse(nums[1]) ?? 0,
      );
    }
    return out;
  }

  String _serializeUpgrades() {
    return upgrades.entries
        .map((e) => '${e.key}:${e.value.engine},${e.value.nitro}')
        .join(';');
  }
}
