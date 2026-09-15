import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_config.dart';
import '../../models/game_session.dart';
import '../buttons/primary_button.dart';
import '../buttons/scale_tap.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    super.key,
    required this.result,
    required this.gameName,
    required this.onReplay,
    required this.onHome,
    this.accentColor,
  });

  final ScoreResult result;
  final String gameName;
  final VoidCallback onReplay;
  final VoidCallback onHome;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.black.withValues(alpha: 0.55),
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1),
              duration: AppDurations.normal,
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                  borderRadius: AppRadius.extraLarge,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'GAME OVER',
                      style: AppTextStyles.headline.copyWith(
                        color: accent,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (result.isNewRecord) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          borderRadius: AppRadius.pill,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events_rounded,
                              color: AppColors.accentDark,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NEW BEST!',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.accentDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      'Your Score',
                      style: AppTextStyles.caption.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '${result.score}',
                      style: AppTextStyles.score.copyWith(color: accent),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Best: ${result.bestScore}',
                      style: AppTextStyles.titleSmall,
                    ),
                    if (_hasStats) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          if (result.accuracy != null)
                            _StatChip(
                              label: 'Accuracy',
                              value:
                                  '${result.accuracy!.toStringAsFixed(0)}%',
                            ),
                          if (result.maxCombo != null)
                            _StatChip(
                              label: 'Combo',
                              value: '${result.maxCombo}',
                            ),
                          if (result.moves != null)
                            _StatChip(
                              label: 'Moves',
                              value: '${result.moves}',
                            ),
                          if (result.elapsed != null)
                            _StatChip(
                              label: 'Time',
                              value: _formatDuration(result.elapsed!),
                            ),
                          ...result.extraStats.entries.map(
                            (e) => _StatChip(label: e.key, value: e.value),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'REPLAY',
                      icon: Icons.replay_rounded,
                      color: accent,
                      onPressed: onReplay,
                    ),
                    const SizedBox(height: 10),
                    SecondaryButton(
                      label: 'HOME',
                      icon: Icons.home_rounded,
                      onPressed: onHome,
                    ),
                    const SizedBox(height: 8),
                    ScaleTap(
                      onTap: () {
                        SharePlus.instance.share(
                          ShareParams(
                            text:
                                'I scored ${result.score} in $gameName on ${AppConfig.appFullName}! Can you beat me?',
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share_rounded,
                              size: 18,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Share Score',
                              style: AppTextStyles.label.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasStats =>
      result.accuracy != null ||
      result.maxCombo != null ||
      result.moves != null ||
      result.elapsed != null ||
      result.extraStats.isNotEmpty;

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.primary.withValues(alpha: 0.06),
        borderRadius: AppRadius.medium,
      ),
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleSmall,
          ),
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
