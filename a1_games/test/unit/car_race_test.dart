import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:a1_games/data/local/local_storage_service.dart';
import 'package:a1_games/features/games/car_race/car_catalog.dart';
import 'package:a1_games/features/games/car_race/car_garage_service.dart';
import 'package:a1_games/features/games/car_race/car_race_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('car race starts in middle lane and can steer', () {
    final c = CarRaceController(spec: CarCatalog.playerCars.first)..start();
    expect(c.isRunning, true);
    expect(c.playerLane, 1);
    c.moveLeft();
    expect(c.playerLane, 0);
    c.moveLeft();
    expect(c.playerLane, 0);
    c.moveRight();
    expect(c.playerLane, 1);
    c.dispose();
  });

  test('nitro consumes fuel and brake cancels boost', () {
    final c = CarRaceController(spec: CarCatalog.playerCars.first)..start();
    expect(c.activateNitro(), true);
    expect(c.nitroActive, true);
    expect(c.nitroFuel, lessThan(1));
    c.setBrake(true);
    expect(c.nitroActive, false);
    c.dispose();
  });

  test('garage unlocks cars with coins', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final garage = CarGarageService(LocalStorageService(prefs));
    expect(garage.isUnlocked('ember_gt'), true);
    expect(garage.isUnlocked('volt_x'), false);
    await garage.addCoins(90);
    expect(await garage.unlockCar('volt_x'), true);
    expect(garage.selectedCarId, 'volt_x');
    expect(garage.coins, 0);
  });
}
