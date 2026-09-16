import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/app_settings_controller.dart';
import '../../../core/services/game_launcher.dart';
import '../../../core/services/score_service.dart';
import '../../../models/game_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<AppSettingsController>();
    final scores = context.read<ScoreService>();
    final stats = scores.loadStats();
    final games = scores.gamesWithScores();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final favoriteId = stats.favoriteGameId;
    final matches = GameCatalog.games.where((g) => g.id == favoriteId);
    final favorite = matches.isEmpty ? null : matches.first;

    final maxBest = games.fold<int>(
      1,
      (m, g) => g.bestScore > m ? g.bestScore : m,
    );

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Your Stats', style: AppTextStyles.displayMedium),
          const SizedBox(height: 4),
          Text(
            'Personal records stored on this device.',
            style: AppTextStyles.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatTile(
                label: 'Games Played',
                value: '${stats.totalGamesPlayed}',
                icon: Icons.play_circle_outline_rounded,
                color: AppColors.primary,
              ),
              _StatTile(
                label: 'Total Score',
                value: '${stats.totalScore}',
                icon: Icons.stars_rounded,
                color: AppColors.accentDark,
              ),
              _StatTile(
                label: 'Best Sum',
                value: '${stats.sumOfBestScores}',
                icon: Icons.emoji_events_rounded,
                color: AppColors.secondary,
              ),
              _StatTile(
                label: 'Streak',
                value: '${stats.currentStreak}d',
                icon: Icons.local_fire_department_rounded,
                color: AppColors.error,
              ),
            ],
          ),
          if (favorite != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                borderRadius: AppRadius.large,
              ),
              child: Row(
                children: [
                  Icon(favorite.icon, color: favorite.color, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Most Played', style: AppTextStyles.caption),
                        Text(favorite.name, style: AppTextStyles.titleSmall),
                      ],
                    ),
                  ),
                  Text(
                    '${stats.playedFor(favorite.id)} plays',
                    style: AppTextStyles.label.copyWith(color: favorite.color),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Game Records', style: AppTextStyles.headline),
          const SizedBox(height: 12),
          for (final game in games)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                borderRadius: AppRadius.large,
                onTap: () => GameLauncher.open(context, game.type),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                    borderRadius: AppRadius.large,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(game.icon, color: game.color, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              game.name,
                              style: AppTextStyles.titleSmall,
                            ),
                          ),
                          Text(
                            '${game.bestScore}',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: game.color,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: AppRadius.pill,
                        child: LinearProgressIndicator(
                          value: game.bestScore == 0 ? 0 : ratioFor(game, maxBest),
                          minHeight: 6,
                          backgroundColor: game.color.withValues(alpha: 0.12),
                          color: game.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${game.gamesPlayed} plays',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  double ratioFor(GameModel game, int maxBest) =>
      (game.bestScore / maxBest).clamp(0.05, 1);
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = (MediaQuery.sizeOf(context).width - 50) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: AppRadius.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.headline),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
