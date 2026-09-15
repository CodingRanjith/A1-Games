import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:a1_games/data/local/local_storage_service.dart';
import 'package:a1_games/models/game_type.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorageService', () {
    late LocalStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      storage = LocalStorageService(prefs);
    });

    test('saves best score only when higher', () async {
      await storage.saveBestScore(GameType.carRace.id, 50);
      expect(storage.getBestScore(GameType.carRace.id), 50);
      await storage.saveBestScore(GameType.carRace.id, 40);
      expect(storage.getBestScore(GameType.carRace.id), 50);
      await storage.saveBestScore(GameType.carRace.id, 80);
      expect(storage.getBestScore(GameType.carRace.id), 80);
    });

    test('isNewRecord compares correctly', () async {
      await storage.saveBestScore(GameType.colorMatch.id, 100);
      expect(storage.isNewRecord(GameType.colorMatch.id, 100), false);
      expect(storage.isNewRecord(GameType.colorMatch.id, 101), true);
    });

    test('increments games played', () async {
      await storage.incrementGamesPlayed(GameType.fastMath.id);
      await storage.incrementGamesPlayed(GameType.fastMath.id);
      expect(storage.getGamesPlayed(GameType.fastMath.id), 2);
      expect(storage.getTotalGamesPlayed(), 2);
    });

    test('settings persist', () async {
      await storage.setSoundEnabled(false);
      await storage.setVibrationEnabled(false);
      await storage.setThemeMode(2);
      expect(storage.getSoundEnabled(), false);
      expect(storage.getVibrationEnabled(), false);
      expect(storage.getThemeMode(), 2);
    });

    test('city racer garage persists coins and selected car', () async {
      await storage.setRacerCoins(120);
      await storage.setSelectedRacerCar('volt_x');
      await storage.setUnlockedRacerCars({'ember_gt', 'volt_x'});
      await storage.setRacerUpgrades('volt_x:2,1');
      expect(storage.getRacerCoins(), 120);
      expect(storage.getSelectedRacerCar(), 'volt_x');
      expect(storage.getUnlockedRacerCars(), {'ember_gt', 'volt_x'});
      expect(storage.getRacerUpgrades(), 'volt_x:2,1');
    });
  });

  group('GameType', () {
    test('ids are unique and round-trip', () {
      final ids = GameType.values.map((e) => e.id).toSet();
      expect(ids.length, GameType.values.length);
      for (final type in GameType.values) {
        expect(GameTypeX.fromId(type.id), type);
      }
    });
  });
}
