import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/services/ads_service.dart';
import 'core/services/app_settings_controller.dart';
import 'core/services/daily_challenge_service.dart';
import 'core/services/haptic_service.dart';
import 'core/services/score_service.dart';
import 'core/services/sound_service.dart';
import 'data/local/local_storage_service.dart';
import 'features/games/car_race/car_garage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final storage = LocalStorageService(prefs);
  final scoreService = ScoreService(storage);
  final haptic = HapticService(storage);
  final sound = SoundService(storage);
  final settings = AppSettingsController(
    storage: storage,
    scoreService: scoreService,
    hapticService: haptic,
    soundService: sound,
  );
  final daily = DailyChallengeService(storage);
  final garage = CarGarageService(storage);
  final ads = MockAdsService();
  await ads.initialize();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: storage),
        Provider.value(value: scoreService),
        Provider.value(value: haptic),
        Provider.value(value: sound),
        Provider.value(value: daily),
        Provider<AdsService>.value(value: ads),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: garage),
      ],
      child: const GameRushApp(),
    ),
  );
}
