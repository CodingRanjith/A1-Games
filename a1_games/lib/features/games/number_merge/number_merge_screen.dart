import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/services/game_launcher.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/score_service.dart';
import '../../../core/services/sound_service.dart';
import '../../../models/game_session.dart';
import '../../../models/game_type.dart';
import '../../../shared/dialogs/game_over_overlay.dart';
import '../../../shared/widgets/countdown_overlay.dart';
import '../../../shared/widgets/game_hud.dart';
import 'number_merge_controller.dart';

class NumberMergeScreen extends StatefulWidget {
  const NumberMergeScreen({super.key});

  @override
  State<NumberMergeScreen> createState() => _NumberMergeScreenState();
}

class _NumberMergeScreenState extends State<NumberMergeScreen>
    with GameFinishMixin {
  static const _accent = AppColors.gameNumberMerge;

  final NumberMergeController _controller = NumberMergeController();

  bool _showCountdown = true;
  bool _showGameOver = false;
  ScoreResult? _result;

  @override
  void dispose() {
    _controller.disposeController();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGameOver() async {
    if (_showGameOver) return;
    _controller.disposeController();

    final result = await finishGame(
      type: GameType.numberMerge,
      score: _controller.score,
      elapsed: _controller.elapsed,
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _showGameOver = true;
    });
  }

  void _replay() {
    setState(() {
      _showGameOver = false;
      _showCountdown = true;
      _result = null;
    });
  }

  Future<void> _handleSwipe(SwipeDirection dir) async {
    if (_showCountdown || _showGameOver) return;
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    final moved = _controller.swipe(dir);
    if (moved) {
      await haptic.selection();
      await sound.playTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final best =
        context.watch<ScoreService>().getBestScore(GameType.numberMerge);

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return GameHud(
                      title: 'Number Merge',
                      score: _controller.score,
                      best: best,
                      accentColor: _accent,
                    );
                  },
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      if (_controller.isGameOver && !_showGameOver) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _onGameOver();
                        });
                      }

                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: GestureDetector(
                          onVerticalDragEnd: (d) {
                            final v = d.primaryVelocity ?? 0;
                            if (v.abs() < 200) return;
                            _handleSwipe(
                              v < 0
                                  ? SwipeDirection.up
                                  : SwipeDirection.down,
                            );
                          },
                          onHorizontalDragEnd: (d) {
                            final v = d.primaryVelocity ?? 0;
                            if (v.abs() < 200) return;
                            _handleSwipe(
                              v < 0
                                  ? SwipeDirection.left
                                  : SwipeDirection.right,
                            );
                          },
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryDark
                                    .withValues(alpha: 0.85),
                                borderRadius: AppRadius.large,
                              ),
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      NumberMergeController.gridSize,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                ),
                                itemCount: NumberMergeController.gridSize *
                                    NumberMergeController.gridSize,
                                itemBuilder: (context, index) {
                                  final r = index ~/
                                      NumberMergeController.gridSize;
                                  final c = index %
                                      NumberMergeController.gridSize;
                                  final tile = _controller.grid[r][c];
                                  return _MergeTileWidget(tile: tile);
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    'Swipe to merge matching numbers',
                    style: AppTextStyles.caption,
                  ),
                ),
              ],
            ),
            if (_showCountdown)
              CountdownOverlay(
                instruction: 'Swipe to merge tiles\nReach the highest number!',
                onDone: () {
                  setState(() => _showCountdown = false);
                  _controller.startGame();
                },
              ),
            if (_showGameOver && _result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'Number Merge',
                accentColor: _accent,
                onReplay: _replay,
                onHome: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}

class _MergeTileWidget extends StatelessWidget {
  const _MergeTileWidget({this.tile});

  final MergeTile? tile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (tile == null) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.15),
          borderRadius: AppRadius.medium,
        ),
      );
    }

    final bg = NumberMergeController.tileColor(tile!.value);
    final textColor =
        tile!.value <= 4 ? AppColors.textPrimaryLight : Colors.white;

    return AnimatedScale(
      scale: tile!.isNew || tile!.merged ? 1.0 : 1.0,
      duration: AppDurations.fast,
      curve: Curves.easeOutBack,
      child: TweenAnimationBuilder<double>(
        key: ValueKey('${tile!.value}-${tile!.isNew}-${tile!.merged}'),
        tween: Tween(begin: tile!.isNew ? 0.6 : 1.0, end: 1.0),
        duration: AppDurations.normal,
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.medium,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${tile!.value}',
              style: AppTextStyles.title.copyWith(
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
