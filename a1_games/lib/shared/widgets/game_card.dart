import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../models/game_model.dart';
import '../../models/game_type.dart';
import '../buttons/scale_tap.dart';

class GameCard extends StatelessWidget {
  const GameCard({
    super.key,
    required this.game,
    required this.onPlay,
    this.compact = false,
  });

  final GameModel game;
  final VoidCallback onPlay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleTap(
      onTap: onPlay,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: AppRadius.large,
          border: Border.all(color: game.color.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: game.color.withValues(alpha: isDark ? 0.22 : 0.14),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top color box header
            Container(
              height: compact ? 72 : 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    game.color,
                    Color.lerp(game.color, Colors.black, 0.18)!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(compact ? 10 : 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: AppRadius.medium,
                    ),
                    child: Icon(
                      game.icon,
                      color: game.color,
                      size: compact ? 22 : 26,
                    ),
                  ),
                  const Spacer(),
                  _DifficultyBadge(difficulty: game.difficulty),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  compact ? 10 : 14,
                  compact ? 10 : 12,
                  compact ? 10 : 14,
                  compact ? 10 : 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.name,
                      style: (compact
                              ? AppTextStyles.label
                              : AppTextStyles.titleSmall)
                          .copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (game.tagline.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        game.tagline,
                        style: AppTextStyles.caption.copyWith(
                          color: game.color,
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 10 : 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      game.description,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: compact ? 11 : 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      maxLines: compact ? 2 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Best ${game.bestScore}',
                            style: AppTextStyles.caption.copyWith(
                              color: game.color,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: compact ? 10 : 14,
                            vertical: compact ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: game.color,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            'PLAY',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: compact ? 10 : 12,
                            ),
                          ),
                        ),
                      ],
                    ),
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

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final GameDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final color = switch (difficulty) {
      GameDifficulty.easy => AppColors.difficultyEasy,
      GameDifficulty.medium => AppColors.difficultyMedium,
      GameDifficulty.hard => AppColors.difficultyHard,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        difficulty.label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}
