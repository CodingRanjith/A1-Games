import 'package:flutter/foundation.dart';

import '../../../data/local/local_storage_service.dart';
import '../../setup/driver_catalog.dart';
import 'car_catalog.dart';
import 'chennai_route.dart';
import 'location_search.dart';

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
  int fromIndex = 0;
  int toIndex = ChennaiRoute.waypoints.length - 1;
  bool satelliteView = false;
  String driverId = 'ace';
  String cityId = 'chennai';
  RaceMap? customMap;

  RaceMap get route => cityId == 'custom' && customMap != null ? customMap! : RaceMaps.byId(cityId);

  DriverSpec get driver => DriverCatalog.byId(driverId);

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
    for (final car in CarCatalog.playerCars) {
      unlocked.add(car.id);
    }
    upgrades
      ..clear()
      ..addAll(_parseUpgrades(_storage.getRacerUpgrades()));
    if (!unlocked.contains(selectedCarId)) {
      selectedCarId = 'ember_gt';
    }
    focusedCarId = selectedCarId;
    cityId = _storage.getRacerCity();
    final lat = _storage.getRacerPlaceLat();
    final lng = _storage.getRacerPlaceLng();
    if (cityId == 'custom' && lat != null && lng != null) {
      customMap = mapAround(_storage.getRacerPlaceName(), lat, lng);
    }
    _clampRoute();
    satelliteView = _storage.getRacerSatellite();
    driverId = _storage.getRacerDriver();
  }

  Future<void> selectDriver(String id) async {
    driverId = DriverCatalog.byId(id).id;
    await _storage.setRacerDriver(driverId);
    notifyListeners();
  }

  Future<void> setCity(String id) async {
    cityId = RaceMaps.byId(id).id;
    customMap = null;
    _clampRoute(reset: true);
    await _storage.setRacerCity(cityId);
    await _storage.setRacerFromIndex(fromIndex);
    await _storage.setRacerToIndex(toIndex);
    notifyListeners();
  }

  Future<bool> searchLocation(String query) async {
    final hit = await LocationSearch.find(query);
    if (hit == null) return false;
    customMap = mapAround(hit.name, hit.lat, hit.lng);
    cityId = 'custom';
    _clampRoute(reset: true);
    await _storage.setRacerCity(cityId);
    await _storage.setRacerPlaceName(hit.name);
    await _storage.setRacerPlace(hit.lat, hit.lng);
    await _storage.setRacerFromIndex(fromIndex);
    await _storage.setRacerToIndex(toIndex);
    notifyListeners();
    return true;
  }

  void _clampRoute({bool reset = false}) {
    final last = route.waypoints.length - 1;
    if (reset) {
      fromIndex = 0;
      toIndex = last;
      return;
    }
    fromIndex = _storage.getRacerFromIndex().clamp(0, last - 1);
    toIndex = _storage.getRacerToIndex().clamp(fromIndex + 1, last);
  }

  Future<void> setRoute({int? from, int? to}) async {
    final last = route.waypoints.length - 1;
    if (from != null) fromIndex = from.clamp(0, last - 1);
    if (to != null) toIndex = to.clamp(fromIndex + 1, last);
    if (toIndex <= fromIndex) {
      toIndex = (fromIndex + 1).clamp(1, last);
    }
    await _storage.setRacerFromIndex(fromIndex);
    await _storage.setRacerToIndex(toIndex);
    notifyListeners();
  }

  Future<void> setSatellite(bool value) async {
    satelliteView = value;
    await _storage.setRacerSatellite(value);
    notifyListeners();
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
