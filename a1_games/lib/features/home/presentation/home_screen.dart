import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/app_settings_controller.dart';
import '../../../core/services/daily_challenge_service.dart';
import '../../../core/services/game_launcher.dart';
import '../../../core/services/score_service.dart';
import '../../../models/game_model.dart';
import '../../../models/game_type.dart';
import '../../../shared/buttons/scale_tap.dart';
import '../../../shared/graphics/character_backdrop.dart';
import '../../../shared/widgets/game_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final scores = context.read<ScoreService>();
    final daily = context.read<DailyChallengeService>();
    final games = scores.gamesWithScores();
    final stats = scores.loadStats();
    final challenge = daily.todaysChallenge;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // silence unused warning if settings only for rebuild
    settings.soundEnabled;

    final featured = games.isNotEmpty
        ? games[DateTime.now().day % games.length]
        : GameCatalog.games.first;

    return CharacterHeroPlate(
      child: SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}!',
                    style: AppTextStyles.body.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  Text(AppConfig.appName, style: AppTextStyles.displayMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Drive the highway. Finish the route to win.',
                    style: AppTextStyles.body.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _StatsRow(
                    totalGames: AppConfig.totalGames,
                    totalBest: stats.sumOfBestScores,
                    played: stats.totalGamesPlayed,
                    streak: stats.currentStreak,
                  ),
                  const SizedBox(height: 20),
                  _FeaturedCard(
                    game: featured.copyWith(
                      bestScore: scores.getBestScore(featured.type),
                    ),
                    onPlay: () => GameLauncher.open(context, featured.type),
                  ),
                  const SizedBox(height: 16),
                  _DailyChallengeCard(
                    game: challenge,
                    completed: daily.isCompleted,
                    onPlay: () => GameLauncher.open(context, challenge.type),
                  ),
                  const SizedBox(height: 24),
                  Text('Race', style: AppTextStyles.headline),
                  const SizedBox(height: 4),
                  Text(
                    AppConfig.shortTagline,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                final crossAxisCount = width > 900 ? 3 : 2;
                return SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final game = games[index];
                      return GameCard(
                        game: game,
                        compact: true,
                        onPlay: () => GameLauncher.open(context, game.type),
                      );
                    },
                    childCount: games.length,
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your Records', style: AppTextStyles.headline),
                  const SizedBox(height: 12),
                  if (stats.topScores.isEmpty)
                    Text(
                      'Play a game to set your first record!',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    )
                    else
                    ...stats.topScores.where((e) => GameCatalog.games.any((g) => g.id == e.key)).map((e) {
                      final game = GameCatalog.byType(GameType.carRace);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ScaleTap(
                          onTap: () => GameLauncher.open(context, game.type),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.cardDark
                                  : AppColors.surfaceLight,
                              borderRadius: AppRadius.large,
                            ),
                            child: Row(
                              children: [
                                Icon(game.icon, color: game.color),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    game.name,
                                    style: AppTextStyles.titleSmall,
                                  ),
                                ),
                                Text(
                                  '${e.value}',
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: game.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.totalGames,
    required this.totalBest,
    required this.played,
    required this.streak,
  });

  final int totalGames;
  final int totalBest;
  final int played;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: AppRadius.large,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _mini('Games', '$totalGames'),
          _mini('Best Sum', '$totalBest'),
          _mini('Played', '$played'),
          _mini('Streak', '$streak'),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.title),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.game, required this.onPlay});

  final GameModel game;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onPlay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              game.color,
              game.color.withValues(alpha: 0.75),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppRadius.extraLarge,
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'START RACE',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.name,
                    style: AppTextStyles.headline.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    game.description,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      'Play Now →',
                      style: AppTextStyles.label.copyWith(color: game.color),
                    ),
                  ),
                ],
              ),
            ),
            Icon(game.icon, size: 64, color: Colors.white.withValues(alpha: 0.9)),
          ],
        ),
      ),
    );
  }
}

class _DailyChallengeCard extends StatelessWidget {
  const _DailyChallengeCard({
    required this.game,
    required this.completed,
    required this.onPlay,
  });

  final GameModel game;
  final bool completed;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleTap(
      onTap: onPlay,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
          borderRadius: AppRadius.large,
          border: Border.all(
            color: completed
                ? AppColors.success.withValues(alpha: 0.5)
                : AppColors.accent.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle_rounded : Icons.flag_rounded,
              color: completed ? AppColors.success : AppColors.accentDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's Challenge", style: AppTextStyles.titleSmall),
                  Text(
                    completed
                        ? 'Completed! Great job.'
                        : '${game.name}: Score ${DailyChallengeService.targetScore}+',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: game.color),
          ],
        ),
      ),
    );
  }
}
