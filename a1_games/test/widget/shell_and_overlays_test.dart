import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:a1_games/app/theme/app_theme.dart';
import 'package:a1_games/core/constants/app_config.dart';
import 'package:a1_games/core/services/ads_service.dart';
import 'package:a1_games/core/services/app_settings_controller.dart';
import 'package:a1_games/core/services/daily_challenge_service.dart';
import 'package:a1_games/core/services/haptic_service.dart';
import 'package:a1_games/core/services/score_service.dart';
import 'package:a1_games/core/services/sound_service.dart';
import 'package:a1_games/data/local/local_storage_service.dart';
import 'package:a1_games/features/games/car_race/car_garage_service.dart';
import 'package:a1_games/features/shell/main_shell.dart';
import 'package:a1_games/models/game_session.dart';
import 'package:a1_games/shared/dialogs/game_over_overlay.dart';
import 'package:a1_games/shared/widgets/game_card.dart';
import 'package:a1_games/models/game_model.dart';

Widget _wrap(Widget child, LocalStorageService storage) {
  final scoreService = ScoreService(storage);
  final haptic = HapticService(storage);
  final sound = SoundService(storage);
  final settings = AppSettingsController(
    storage: storage,
    scoreService: scoreService,
    hapticService: haptic,
    soundService: sound,
  );
  return MultiProvider(
    providers: [
      Provider.value(value: storage),
      Provider.value(value: scoreService),
      Provider.value(value: haptic),
      Provider.value(value: sound),
      Provider.value(value: DailyChallengeService(storage)),
      Provider<AdsService>.value(value: MockAdsService()),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: CarGarageService(storage)),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true});
    final prefs = await SharedPreferences.getInstance();
    storage = LocalStorageService(prefs);
  });

  testWidgets('MainShell shows Home tab with app name', (tester) async {
    await tester.pumpWidget(_wrap(const MainShell(), storage));
    await tester.pumpAndSettle();
    expect(find.text(AppConfig.appName), findsWidgets);
    expect(find.text('Ready for a quick challenge?'), findsOneWidget);
    expect(find.text("Today's Challenge"), findsOneWidget);
  });

  testWidgets('GameCard shows play affordance', (tester) async {
    final game = GameCatalog.games.first.copyWith(bestScore: 42);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: SizedBox(
            height: 220,
            child: GameCard(game: game, onPlay: () {}),
          ),
        ),
      ),
    );
    expect(find.text(game.name), findsOneWidget);
    expect(find.text('Best 42'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
  });

  testWidgets('GameOverOverlay shows score and new best', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: GameOverOverlay(
            gameName: 'City Racer',
            result: const ScoreResult(
              score: 150,
              bestScore: 150,
              isNewRecord: true,
            ),
            onReplay: () {},
            onHome: () {},
          ),
        ),
      ),
    );
    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('NEW BEST!'), findsOneWidget);
    expect(find.text('150'), findsWidgets);
    expect(find.text('REPLAY'), findsOneWidget);
  });
}
