import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/app_settings_controller.dart';
import '../../../core/services/game_launcher.dart';
import '../../../core/services/score_service.dart';
import '../../../models/game_model.dart';
import '../../../models/game_type.dart';
import '../../../shared/widgets/game_card.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  GameCategory _category = GameCategory.all;

  @override
  Widget build(BuildContext context) {
    context.watch<AppSettingsController>();
    final scores = context.read<ScoreService>();
    final all = scores.gamesWithScores();
    final games = _category == GameCategory.all
        ? all
        : all.where((GameModel g) => g.category == _category).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose Your Game', style: AppTextStyles.displayMedium),
                const SizedBox(height: 4),
                Text(
                  'All · Quick · Puzzle · Arcade · Word',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: GameCategory.values.map((c) {
                final selected = c == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = c),
                    selectedColor: AppColors.primary.withValues(alpha: 0.18),
                    labelStyle: AppTextStyles.label.copyWith(
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.pill,
                      side: BorderSide(
                        color: selected
                            ? AppColors.primary
                            : (isDark
                                ? AppColors.dividerDark
                                : AppColors.dividerLight),
                      ),
                    ),
                    showCheckmark: false,
                    backgroundColor: Colors.transparent,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: games.length,
                  itemBuilder: (context, index) {
                    final game = games[index];
                    return GameCard(
                      game: game,
                      compact: true,
                      onPlay: () => GameLauncher.open(context, game.type),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
