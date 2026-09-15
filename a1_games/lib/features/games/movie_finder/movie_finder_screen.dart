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
import 'package:a1_games/shared/graphics/character_backdrop.dart';
import 'package:a1_games/shared/widgets/countdown_overlay.dart';
import 'package:a1_games/shared/widgets/game_hud.dart';

import 'movie_finder_controller.dart';
import 'movie_finder_data.dart';

class MovieFinderScreen extends StatefulWidget {
  const MovieFinderScreen({super.key});

  @override
  State<MovieFinderScreen> createState() => _MovieFinderScreenState();
}

class _MovieFinderScreenState extends State<MovieFinderScreen>
    with GameFinishMixin {
  static const _accent = AppColors.gameMovieFinder;
  static const _gold = Color(0xFFD4AF37);
  static const _cinemaRed = Color(0xFF8B0000);

  late final MovieFinderController _controller;
  bool _showCountdown = true;
  bool _showGameOver = false;
  ScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = MovieFinderController();
  }

  @override
  void dispose() {
    _controller.disposeController();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onGameOver() async {
    if (_showGameOver) return;
    _controller.disposeController();

    final correct = _controller.rounds
        .where((r) => r.state == MovieAnswerState.correct)
        .length;

    final result = await finishGame(
      type: GameType.movieFinder,
      score: _controller.score,
      accuracy: _controller.accuracy,
      maxCombo: _controller.session.maxCombo,
      extraStats: {
        'Correct': '$correct/${MovieFinderData.totalRounds}',
        'Lives left': '${_controller.lives}',
      },
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

  Future<void> _onOptionTap(String option) async {
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();

    _controller.selectOption(option);

    if (_controller.currentRound?.state == MovieAnswerState.correct) {
      await haptic.light();
      await sound.playSuccess();
    } else {
      await haptic.medium();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final best =
        context.watch<ScoreService>().getBestScore(GameType.movieFinder);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A0A0A), Color(0xFF2D1212), Color(0xFF1A0A0A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned.fill(
                child: CharacterBackdrop(
                  assetPath: 'assets/characters/movie_host.png',
                  opacity: 0.22,
                  widthFactor: 0.52,
                  alignment: Alignment.bottomRight,
                ),
              ),
              Column(
                children: [
                  ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return GameHud(
                        title: 'Movie Finder',
                        score: _controller.score,
                        best: best,
                        accentColor: _accent,
                        combo: _controller.isRunning && _controller.combo > 0
                            ? _controller.combo
                            : null,
                        lives: _controller.isRunning ? _controller.lives : null,
                        timerText: _controller.isRunning &&
                                !_controller.revealNext
                            ? _controller.timerText
                            : null,
                        extra: _controller.isRunning
                            ? _RoundProgress(controller: _controller)
                            : null,
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

                        final round = _controller.currentRound;
                        if (round == null || !_controller.isRunning) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Column(
                            children: [
                              Expanded(
                                child: _ClueCard(
                                  round: round,
                                  reveal: _controller.revealNext,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...round.options.map(
                                (opt) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _OptionButton(
                                    label: opt,
                                    round: round,
                                    reveal: _controller.revealNext,
                                    onTap: () => _onOptionTap(opt),
                                  ),
                                ),
                              ),
                              if (_controller.revealNext) ...[
                                const SizedBox(height: 8),
                                _NextButton(
                                  isLast: _controller.currentRoundIndex >=
                                      MovieFinderData.totalRounds - 1,
                                  onTap: () {
                                    _controller.nextRound();
                                    if (!_controller.isGameOver) {
                                      setState(() {});
                                    }
                                  },
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              if (_showCountdown && !_showGameOver)
                CountdownOverlay(
                  instruction: 'Guess the movie from emoji clues!',
                  onDone: () {
                    setState(() => _showCountdown = false);
                    _controller.startGame();
                  },
                ),
              if (_showGameOver && _result != null)
                GameOverOverlay(
                  result: _result!,
                  gameName: 'Movie Finder',
                  accentColor: _accent,
                  onReplay: _replay,
                  onHome: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundProgress extends StatelessWidget {
  const _RoundProgress({required this.controller});

  final MovieFinderController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(MovieFinderData.totalRounds, (i) {
        final done = i < controller.currentRoundIndex;
        final current = i == controller.currentRoundIndex;
        return Container(
          width: current ? 22 : 10,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: done
                ? AppColors.success
                : current
                    ? _MovieFinderScreenState._gold
                    : Colors.white.withValues(alpha: 0.2),
            borderRadius: AppRadius.pill,
          ),
        );
      }),
    );
  }
}

class _ClueCard extends StatelessWidget {
  const _ClueCard({required this.round, required this.reveal});

  final MovieRound round;
  final bool reveal;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _MovieFinderScreenState._cinemaRed.withValues(alpha: 0.9),
            const Color(0xFF4A1515),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: _MovieFinderScreenState._gold.withValues(alpha: 0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.local_movies_rounded, color: _MovieFinderScreenState._gold, size: 20),
              const SizedBox(width: 8),
              Text(
                'MOVIE CLUE',
                style: AppTextStyles.label.copyWith(
                  color: _MovieFinderScreenState._gold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            round.clue.emojis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 64, height: 1.2),
          ),
          if (round.clue.hint != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.25),
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                round.clue.hint!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (reveal) ...[
            const SizedBox(height: 20),
            Text(
              round.state == MovieAnswerState.correct
                  ? '+${round.pointsEarned} pts'
                  : round.clue.displayTitle,
              style: AppTextStyles.title.copyWith(
                color: round.state == MovieAnswerState.correct
                    ? AppColors.success
                    : _MovieFinderScreenState._gold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.label,
    required this.round,
    required this.reveal,
    required this.onTap,
  });

  final String label;
  final MovieRound round;
  final bool reveal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = round.clue.displayTitle == label;
    final isSelected = round.selectedOption == label;

    Color bg = const Color(0xFF2A1818);
    Color border = Colors.white.withValues(alpha: 0.15);
    Color text = Colors.white;

    if (reveal) {
      if (isCorrect) {
        bg = AppColors.success.withValues(alpha: 0.35);
        border = AppColors.success;
      } else if (isSelected) {
        bg = AppColors.error.withValues(alpha: 0.35);
        border = AppColors.error;
      }
    } else if (isSelected) {
      border = _MovieFinderScreenState._gold;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: reveal ? null : onTap,
        borderRadius: AppRadius.large,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.large,
            border: Border.all(color: border, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.confirmation_number_rounded,
                color: _MovieFinderScreenState._gold.withValues(alpha: 0.8),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.titleSmall.copyWith(color: text),
                ),
              ),
              if (reveal && isCorrect)
                const Icon(Icons.check_circle_rounded, color: AppColors.success),
              if (reveal && isSelected && !isCorrect)
                const Icon(Icons.cancel_rounded, color: AppColors.error),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.isLast, required this.onTap});

  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _MovieFinderScreenState._gold,
          foregroundColor: const Color(0xFF1A0A0A),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        ),
        onPressed: onTap,
        icon: Icon(isLast ? Icons.flag_rounded : Icons.arrow_forward_rounded),
        label: Text(
          isLast ? 'See Results' : 'Next Movie',
          style: AppTextStyles.button.copyWith(color: const Color(0xFF1A0A0A)),
        ),
      ),
    );
  }
}
