import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:a1_games/data/local/local_storage_service.dart';
import 'package:a1_games/features/games/car_race/car_catalog.dart';
import 'package:a1_games/features/games/car_race/car_garage_service.dart';
import 'package:a1_games/features/games/car_race/car_race_controller.dart';
import 'package:a1_games/features/games/car_race/chennai_route.dart';
import 'package:a1_games/features/games/car_race/render/glb_loader.dart';
import 'package:a1_games/features/games/car_race/vehicle/car_config.dart';
import 'package:a1_games/features/games/car_race/vehicle/vehicle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('route lists roads and upcoming turns', () {
    final roads = ChennaiRoute.roadsBetween(0, 4);
    expect(roads, isNotEmpty);
    expect(ChennaiRoute.sidesForPlace('Anna Salai').left, SideKind.city);
    expect(ChennaiRoute.sidesForPlace('Thiruvanmiyur').left, SideKind.sand);
    expect(ChennaiRoute.sidesForPlace('Moolakadai').right, SideKind.sand);
    final turns = ChennaiRoute.upcoming(0, max: 3);
    expect(turns, isNotEmpty);
    expect(turns.first.metersAhead, greaterThan(0));
    final split = ChennaiRoute.splitRoute(0, ChennaiRoute.waypoints.length - 1, 2000);
    expect(split.done, isNotEmpty);
    expect(split.left, isNotEmpty);
  });

  test('chennai route is a 22 km moolakadai to thiruvanmiyur race', () {
    expect(ChennaiRoute.startName, 'Moolakadai');
    expect(ChennaiRoute.endName, 'Thiruvanmiyur');
    expect(ChennaiRoute.raceKm, 22);
    expect(ChennaiRoute.samples.length, greaterThan(20));
    final start = ChennaiRoute.hintAt(0);
    expect(start.metersAhead, greaterThan(0));
    final end = ChennaiRoute.hintAt(ChennaiRoute.raceMeters);
    expect(end.turn, NavTurn.arrive);
  });

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

  test('car configs map to kenney glb files', () {
    expect(CarConfigs.byId('ember_gt').modelPath, contains('sedan-sports.glb'));
    expect(CarConfigs.all.length, 7);
    expect(CarConfigs.byId('truck').modelPath, contains('truck.glb'));
    expect(CarConfigs.byId('bus').modelPath, contains('van.glb'));
    expect(CarConfigs.trafficModels, isNotEmpty);
    final v = Vehicle(config: CarConfigs.emberGt);
    v.applyControls(dt: 0.016, steerInput: 1, throttle: true, brake: false, cruise: 3);
    expect(v.wheelSpin, greaterThan(0));
    expect(v.steerAngle, greaterThan(0));
  });

  test('analog steer is clamped while racing', () {
    final c = CarRaceController(spec: CarCatalog.playerCars.first)..start();
    c.setSteer(-2);
    expect(c.steerInput, -1);
    c.setSteer(0.4);
    expect(c.steerInput, 0.4);
    c.dispose();
  });

  test('loads kenney sedan glb with named wheels', () async {
    final model = await GlbLoader.load('assets/models/cars/sedan-sports.glb');
    expect(model.parts, isNotEmpty);
    expect(model.parts.any((p) => p.isWheel), isTrue);
    expect(model.parts.any((p) => p.name.contains('body')), isTrue);
    expect(model.triangleCount, greaterThan(100));
    expect(model.triangleCount, lessThan(8000));
    final human = await GlbLoader.load('assets/models/characters/human.glb');
    expect(human.parts, isNotEmpty);
    expect(human.triangleCount, greaterThan(40));
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

  test('all vehicles are free to drive', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final garage = CarGarageService(LocalStorageService(prefs));
    expect(garage.isUnlocked('ember_gt'), true);
    expect(garage.isUnlocked('volt_x'), true);
    expect(garage.isUnlocked('cycle'), true);
    expect(garage.isUnlocked('bus'), true);
    await garage.addCoins(90);
    expect(await garage.unlockCar('volt_x'), true);
    expect(garage.coins, 90);
  });
}
