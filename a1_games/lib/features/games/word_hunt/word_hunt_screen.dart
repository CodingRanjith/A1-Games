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

import 'word_hunt_controller.dart';
import 'word_hunt_data.dart';

class WordHuntScreen extends StatefulWidget {
  const WordHuntScreen({super.key});

  @override
  State<WordHuntScreen> createState() => _WordHuntScreenState();
}

class _WordHuntScreenState extends State<WordHuntScreen> with GameFinishMixin {
  static const _accent = AppColors.gameWordHunt;

  late final WordHuntController _controller;
  bool _showLanguagePicker = true;
  bool _showCountdown = false;
  bool _showGameOver = false;
  ScoreResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = WordHuntController();
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
      type: GameType.wordHunt,
      score: _controller.score,
      maxCombo: _controller.session.maxCombo,
      elapsed: _controller.elapsed,
      extraStats: {
        'Words': '${_controller.wordsFound}/${_controller.totalWords}',
        'Language': _controller.language.label,
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
      _showCountdown = false;
      _showLanguagePicker = true;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final best = context.watch<ScoreService>().getBestScore(GameType.wordHunt);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    return GameHud(
                      title: 'Word Hunt',
                      score: _controller.score,
                      best: best,
                      accentColor: _accent,
                      combo: _controller.isRunning ? _controller.session.combo : null,
                      timerText:
                          _controller.isRunning ? _controller.timerText : null,
                      extra: _controller.isRunning
                          ? _WordListBar(controller: _controller)
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

                      if (!_controller.isRunning && !_showLanguagePicker) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: _WordGrid(
                          controller: _controller,
                          accent: _accent,
                          isDark: isDark,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_showLanguagePicker && !_showGameOver)
              _LanguagePicker(
                onSelected: (lang, transliteration) {
                  _controller.setLanguage(
                    lang,
                    transliteration: transliteration,
                  );
                  setState(() {
                    _showLanguagePicker = false;
                    _showCountdown = true;
                  });
                },
              ),
            if (_showCountdown && !_showLanguagePicker && !_showGameOver)
              CountdownOverlay(
                instruction: 'Drag across letters to find hidden words',
                onDone: () {
                  setState(() => _showCountdown = false);
                  _controller.startGame();
                },
              ),
            if (_showGameOver && _result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'Word Hunt',
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

class _LanguagePicker extends StatefulWidget {
  const _LanguagePicker({required this.onSelected});

  final void Function(WordHuntLanguage lang, bool transliteration) onSelected;

  @override
  State<_LanguagePicker> createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<_LanguagePicker> {
  bool _transliteration = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
            borderRadius: AppRadius.extraLarge,
            boxShadow: [
              BoxShadow(
                color: AppColors.gameWordHunt.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.abc_rounded, size: 48, color: AppColors.gameWordHunt),
              const SizedBox(height: 12),
              Text('Choose Language', style: AppTextStyles.headline),
              const SizedBox(height: 8),
              Text(
                'Find words hidden in the letter grid',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),
              _LangChip(
                label: 'English',
                subtitle: '8×8 grid · 6 words · 90 sec',
                color: AppColors.gameWordHunt,
                onTap: () => widget.onSelected(WordHuntLanguage.english, false),
              ),
              const SizedBox(height: 12),
              _LangChip(
                label: 'தமிழ்',
                subtitle: '7×7 grid · 5 words · 90 sec',
                color: AppColors.primary,
                onTap: () =>
                    widget.onSelected(WordHuntLanguage.tamil, _transliteration),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Tamil transliteration mode', style: AppTextStyles.label),
                subtitle: Text(
                  'Accept romanized spellings (e.g. MEEN)',
                  style: AppTextStyles.caption,
                ),
                value: _transliteration,
                activeTrackColor: AppColors.gameWordHunt.withValues(alpha: 0.5),
                activeThumbColor: AppColors.gameWordHunt,
                onChanged: (v) => setState(() => _transliteration = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: AppRadius.large,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.large,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: AppRadius.large,
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppRadius.medium,
                ),
                child: const Icon(Icons.translate_rounded, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTextStyles.titleSmall.copyWith(color: color)),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _WordListBar extends StatelessWidget {
  const _WordListBar({required this.controller});

  final WordHuntController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: controller.words.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final w = controller.words[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: w.found
                  ? AppColors.success.withValues(alpha: 0.18)
                  : AppColors.gameWordHunt.withValues(alpha: 0.1),
              borderRadius: AppRadius.pill,
              border: Border.all(
                color: w.found ? AppColors.success : AppColors.gameWordHunt.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              controller.displayWord(w),
              style: AppTextStyles.label.copyWith(
                decoration: w.found ? TextDecoration.lineThrough : null,
                color: w.found ? AppColors.success : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WordGrid extends StatelessWidget {
  const _WordGrid({
    required this.controller,
    required this.accent,
    required this.isDark,
  });

  final WordHuntController controller;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final size = controller.gridSize;
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth / size).clamp(32.0, 52.0);

        return Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.08),
                  accent.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: AppRadius.extraLarge,
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: GestureDetector(
              onPanStart: (d) {
                final idx = _indexFromLocal(d.localPosition, cellSize, size);
                if (idx != null) controller.beginSelection(idx);
              },
              onPanUpdate: (d) {
                final idx = _indexFromLocal(d.localPosition, cellSize, size);
                if (idx != null) controller.extendSelection(idx);
              },
              onPanEnd: (_) async {
                final before = controller.wordsFound;
                controller.endSelection();
                if (controller.wordsFound > before) {
                  await haptic.light();
                  await sound.playSuccess();
                } else if (controller.wrongFlashActive) {
                  await haptic.selection();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(size, (row) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(size, (col) {
                      final idx = row * size + col;
                      final letter = controller.grid[row][col];
                      final state = controller.cellStates[idx] ??
                          WordHuntCellState.normal;
                      return _GridCell(
                        letter: letter,
                        state: state,
                        size: cellSize,
                        isDark: isDark,
                        accent: accent,
                      );
                    }),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  int? _indexFromLocal(Offset pos, double cellSize, int gridSize) {
    const padding = 10.0;
    const gap = 4.0;
    final x = pos.dx - padding;
    final y = pos.dy - padding;
    if (x < 0 || y < 0) return null;
    final col = (x / (cellSize + gap)).floor();
    final row = (y / (cellSize + gap)).floor();
    if (row < 0 || row >= gridSize || col < 0 || col >= gridSize) return null;
    return row * gridSize + col;
  }
}

class _GridCell extends StatelessWidget {
  const _GridCell({
    required this.letter,
    required this.state,
    required this.size,
    required this.isDark,
    required this.accent,
  });

  final String letter;
  final WordHuntCellState state;
  final double size;
  final bool isDark;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (state) {
      case WordHuntCellState.found:
        bg = AppColors.success.withValues(alpha: 0.85);
        fg = Colors.white;
        border = Border.all(color: AppColors.success, width: 1.5);
      case WordHuntCellState.selected:
        bg = accent;
        fg = Colors.white;
        border = Border.all(color: accent.withValues(alpha: 0.8), width: 1.5);
      case WordHuntCellState.wrongFlash:
        bg = AppColors.error.withValues(alpha: 0.85);
        fg = Colors.white;
        border = null;
      case WordHuntCellState.normal:
        bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
        fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        border = Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        );
    }

    return AnimatedContainer(
      duration: AppDurations.fast,
      width: size,
      height: size,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.small,
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: AppTextStyles.titleSmall.copyWith(
          color: fg,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
