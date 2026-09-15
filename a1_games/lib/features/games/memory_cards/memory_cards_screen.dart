import 'dart:math' show min, pi;

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
import 'memory_cards_controller.dart';

class MemoryCardsScreen extends StatefulWidget {
  const MemoryCardsScreen({super.key});

  @override
  State<MemoryCardsScreen> createState() => _MemoryCardsScreenState();
}

class _MemoryCardsScreenState extends State<MemoryCardsScreen>
    with GameFinishMixin {
  static const _accent = AppColors.gameMemory;

  late final MemoryCardsController _controller;
  bool _showCountdown = false;
  bool _showGameOver = false;
  bool _showDifficulty = true;
  ScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = MemoryCardsController();
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

    final result = await finishGame(
      type: GameType.memoryCards,
      score: _controller.score,
      moves: _controller.moves,
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
      _showCountdown = false;
      _showDifficulty = true;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final best =
        context.watch<ScoreService>().getBestScore(GameType.memoryCards);

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
                      title: 'Memory Cards',
                      score: _controller.score,
                      best: best,
                      accentColor: _accent,
                      timerText: _controller.isRunning
                          ? _controller.timerText
                          : null,
                      extra: _controller.isRunning
                          ? Text(
                              'Moves: ${_controller.moves}',
                              style: AppTextStyles.label,
                            )
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

                      final cols = _controller.difficulty.columns;
                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: _controller.cards.length,
                          itemBuilder: (context, index) {
                            final card = _controller.cards[index];
                            return _FlipCard(
                              card: card,
                              onTap: () async {
                                if (_showCountdown ||
                                    _showGameOver ||
                                    _showDifficulty) {
                                  return;
                                }
                                final haptic = context.read<HapticService>();
                                final sound = context.read<SoundService>();
                                await _controller.flipCard(card.id);
                                if (!context.mounted) return;
                                final c = cardById(card.id);
                                if (c?.isMatched ?? false) {
                                  await haptic.light();
                                  await sound.playSuccess();
                                } else if (_controller.isChecking) {
                                  await haptic.selection();
                                }
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_showDifficulty && !_showGameOver)
              _DifficultyPicker(
                onSelected: (d) {
                  _controller.setDifficulty(d);
                  setState(() {
                    _showDifficulty = false;
                    _showCountdown = true;
                  });
                },
              ),
            if (_showCountdown && !_showDifficulty && !_showGameOver)
              CountdownOverlay(
                instruction: 'Find all matching pairs',
                onDone: () {
                  setState(() => _showCountdown = false);
                  _controller.startGame();
                },
              ),
            if (_showGameOver && _result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'Memory Cards',
                accentColor: _accent,
                onReplay: _replay,
                onHome: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }

  MemoryCard? cardById(int id) => _controller.cardById(id);
}

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({required this.onSelected});

  final ValueChanged<MemoryDifficulty> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: AppRadius.extraLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Difficulty', style: AppTextStyles.headline),
              const SizedBox(height: 20),
              _DiffButton(
                label: 'Easy · 4 pairs',
                color: AppColors.difficultyEasy,
                onTap: () => onSelected(MemoryDifficulty.easy),
              ),
              const SizedBox(height: 10),
              _DiffButton(
                label: 'Medium · 6 pairs',
                color: AppColors.difficultyMedium,
                onTap: () => onSelected(MemoryDifficulty.medium),
              ),
              const SizedBox(height: 10),
              _DiffButton(
                label: 'Hard · 8 pairs',
                color: AppColors.difficultyHard,
                onTap: () => onSelected(MemoryDifficulty.hard),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiffButton extends StatelessWidget {
  const _DiffButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        ),
        onPressed: onTap,
        child: Text(label, style: AppTextStyles.button),
      ),
    );
  }
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.card, required this.onTap});

  final MemoryCard card;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showFront = card.isFlipped || card.isMatched;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: AppDurations.normal,
        transitionBuilder: (child, anim) {
          final rotate = Tween(begin: pi, end: 0.0).animate(anim);
          return AnimatedBuilder(
            animation: rotate,
            builder: (context, child) {
              final isUnder = (ValueKey(showFront) != child!.key);
              final tilt = isUnder ? min(rotate.value, pi / 2) : rotate.value;
              return Transform(
                transform: Matrix4.rotationY(tilt),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: child,
          );
        },
        layoutBuilder: (current, previous) => Stack(
          fit: StackFit.expand,
          children: [
            ...previous,
            ?current,
          ],
        ),
        child: showFront
            ? _CardFace(
                key: const ValueKey(true),
                color: card.color,
                icon: card.icon,
                matched: card.isMatched,
              )
            : _CardBack(
                key: const ValueKey(false),
                isDark: isDark,
              ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gameMemory,
            AppColors.gameMemory.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.medium,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.question_mark_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    super.key,
    required this.color,
    required this.icon,
    required this.matched,
  });

  final Color color;
  final IconData icon;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: matched ? 0.5 : 1),
        borderRadius: AppRadius.medium,
        border: matched
            ? Border.all(color: AppColors.success, width: 2)
            : null,
      ),
      child: Center(
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
