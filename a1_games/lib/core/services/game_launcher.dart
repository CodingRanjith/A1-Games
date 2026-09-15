import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/app_settings_controller.dart';
import '../../core/services/daily_challenge_service.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/score_service.dart';
import '../../core/services/sound_service.dart';
import '../../models/game_model.dart';
import '../../models/game_session.dart';
import '../../models/game_type.dart';
import '../../features/games/bird_hit/bird_hit_screen.dart';
import '../../features/games/bubble_shooter/bubble_shooter_screen.dart';
import '../../features/games/car_race/car_race_screen.dart';
import '../../features/games/city_survival/city_survival_screen.dart';
import '../../features/games/color_match/color_match_screen.dart';
import '../../features/games/fast_math/fast_math_screen.dart';
import '../../features/games/memory_cards/memory_cards_screen.dart';
import '../../features/games/movie_finder/movie_finder_screen.dart';
import '../../features/games/number_merge/number_merge_screen.dart';
import '../../features/games/word_hunt/word_hunt_screen.dart';

class GameLauncher {
  GameLauncher._();

  static Future<void> open(BuildContext context, GameType type) {
    final game = GameCatalog.byType(type);
    final Widget screen = switch (type) {
      GameType.carRace => const CarRaceScreen(),
      GameType.colorMatch => const ColorMatchScreen(),
      GameType.numberMerge => const NumberMergeScreen(),
      GameType.memoryCards => const MemoryCardsScreen(),
      GameType.wordHunt => const WordHuntScreen(),
      GameType.movieFinder => const MovieFinderScreen(),
      GameType.bubbleShooter => const BubbleShooterScreen(),
      GameType.birdHit => const BirdHitScreen(),
      GameType.fastMath => const FastMathScreen(),
      GameType.citySurvival => const CitySurvivalScreen(),
    };

    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
        settings: RouteSettings(name: '/game/${game.id}'),
      ),
    );
  }
}

mixin GameFinishMixin<T extends StatefulWidget> on State<T> {
  Future<ScoreResult> finishGame({
    required GameType type,
    required int score,
    double? accuracy,
    int? maxCombo,
    int? moves,
    Duration? elapsed,
    Map<String, String> extraStats = const {},
  }) async {
    final settings = context.read<AppSettingsController>();
    final scores = context.read<ScoreService>();
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    final daily = context.read<DailyChallengeService>();

    final isNew = scores.isNewRecord(type, score);
    final bestBefore = scores.getBestScore(type);
    await scores.recordGameResult(type, score);
    await daily.markCompletedIfEligible(type, score);
    settings.refresh();

    final best = score > bestBefore ? score : bestBefore;

    if (isNew) {
      await haptic.heavy();
    } else {
      await haptic.medium();
    }
    await sound.playGameOver();

    return ScoreResult(
      score: score,
      bestScore: best,
      isNewRecord: isNew && score > 0,
      accuracy: accuracy,
      maxCombo: maxCombo,
      moves: moves,
      elapsed: elapsed,
      extraStats: extraStats,
    );
  }
}
