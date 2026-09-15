import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:a1_games/app/theme/app_colors.dart';
import 'package:a1_games/app/theme/app_spacing.dart';
import 'package:a1_games/app/theme/app_text_styles.dart';
import 'package:a1_games/core/services/game_launcher.dart';
import 'package:a1_games/core/services/haptic_service.dart';
import 'package:a1_games/core/services/score_service.dart';
import 'package:a1_games/core/services/sound_service.dart';
import 'package:a1_games/models/game_session.dart';
import 'package:a1_games/models/game_type.dart';
import 'package:a1_games/shared/dialogs/game_over_overlay.dart';
import 'package:a1_games/shared/widgets/countdown_overlay.dart';
import 'package:a1_games/shared/widgets/game_hud.dart';

import 'fast_math_controller.dart';

class FastMathScreen extends StatefulWidget {
  const FastMathScreen({super.key});

  @override
  State<FastMathScreen> createState() => _FastMathScreenState();
}

class _FastMathScreenState extends State<FastMathScreen> with GameFinishMixin {
  static const _accent = AppColors.gameFastMath;

  late FastMathController _controller;
  bool _showCountdown = true;
  ScoreResult? _result;
  bool _handlingGameOver = false;

  @override
  void initState() {
    super.initState();
    _controller = FastMathController();
    _controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (_controller.isGameOver && !_handlingGameOver && _result == null) {
      _handleGameOver();
    }
    if (mounted) setState(() {});
  }

  Future<void> _handleGameOver() async {
    _handlingGameOver = true;
    final result = await finishGame(
      type: GameType.fastMath,
      score: _controller.score,
      accuracy: _controller.accuracy,
      moves: _controller.questionsAnswered,
      extraStats: {
        'Level': _controller.level.label,
        'Correct': '${_controller.correctCount}',
      },
    );

    if (!mounted) return;
    setState(() {
      _result = result;
      _handlingGameOver = false;
    });
  }

  void _startGame() {
    setState(() => _showCountdown = false);
    _controller.start();
  }

  void _replay() {
    setState(() {
      _result = null;
      _showCountdown = true;
      _handlingGameOver = false;
    });
    _controller.removeListener(_onControllerChanged);
    _controller.disposeController();
    _controller = FastMathController();
    _controller.addListener(_onControllerChanged);
  }

  Future<void> _onAnswer(int value) async {
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    final correct = _controller.answer(value);
    if (correct) {
      await haptic.light();
      await sound.playSuccess();
    } else {
      await haptic.medium();
      await sound.playFail();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final best = context.watch<ScoreService>().getBestScore(GameType.fastMath);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = _controller.currentQuestion;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                GameHud(
                  title: 'Fast Math',
                  score: _controller.score,
                  best: best,
                  lives: _controller.lives,
                  timerText: _controller.timerText,
                  accentColor: _accent,
                  extra: Text(
                    'Level: ${_controller.level.label}',
                    style: AppTextStyles.caption,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      children: [
                        if (question != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xl,
                            ),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                              borderRadius: AppRadius.large,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              question.text,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.displayMedium.copyWith(
                                color: _accent,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          LinearProgressIndicator(
                            value: _controller.timeLeftMs / 10000,
                            minHeight: 8,
                            borderRadius: AppRadius.small,
                            backgroundColor: _accent.withValues(alpha: 0.15),
                            color: _controller.timeLeftMs < 3000
                                ? AppColors.error
                                : _accent,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Expanded(
                            child: GridView.count(
                              crossAxisCount: 2,
                              mainAxisSpacing: AppSpacing.md,
                              crossAxisSpacing: AppSpacing.md,
                              childAspectRatio: 1.6,
                              children: question.options.map((option) {
                                return Material(
                                  color: isDark
                                      ? AppColors.surfaceDark
                                      : AppColors.surfaceLight,
                                  borderRadius: AppRadius.large,
                                  child: InkWell(
                                    borderRadius: AppRadius.large,
                                    onTap: _controller.isRunning
                                        ? () => _onAnswer(option)
                                        : null,
                                    child: Center(
                                      child: Text(
                                        '$option',
                                        style: AppTextStyles.headline,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showCountdown)
              CountdownOverlay(
                instruction: 'Solve fast — wrong answers cost a life!',
                onDone: _startGame,
              ),
            if (_result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'Fast Math',
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
