import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    super.key,
    required this.title,
    required this.score,
    required this.best,
    this.combo,
    this.lives,
    this.timerText,
    this.onPause,
    this.accentColor,
    this.extra,
  });

  final String title;
  final int score;
  final int best;
  final int? combo;
  final int? lives;
  final String? timerText;
  final VoidCallback? onPause;
  final Color? accentColor;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
              ),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onPause != null)
                IconButton(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause_rounded),
                  tooltip: 'Pause',
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
              borderRadius: AppRadius.large,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                _HudItem(label: 'Score', value: '$score', color: accent),
                _divider(isDark),
                _HudItem(label: 'Best', value: '$best'),
                if (combo != null) ...[
                  _divider(isDark),
                  _HudItem(
                    label: 'Combo',
                    value: 'x$combo',
                    color: combo! > 1 ? AppColors.secondary : null,
                  ),
                ],
                if (lives != null) ...[
                  _divider(isDark),
                  _HudItem(
                    label: 'Lives',
                    value: '$lives',
                    color: AppColors.error,
                  ),
                ],
                if (timerText != null) ...[
                  _divider(isDark),
                  _HudItem(label: 'Time', value: timerText!),
                ],
              ],
            ),
          ),
          if (extra != null) ...[
            const SizedBox(height: 8),
            extra!,
          ],
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
        width: 1,
        height: 28,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
      );
}

class _HudItem extends StatelessWidget {
  const _HudItem({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
