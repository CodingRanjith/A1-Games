import 'dart:math' show cos, pi, sin;

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
import 'color_match_controller.dart';

class ColorMatchScreen extends StatefulWidget {
  const ColorMatchScreen({super.key});

  @override
  State<ColorMatchScreen> createState() => _ColorMatchScreenState();
}

class _ColorMatchScreenState extends State<ColorMatchScreen>
    with GameFinishMixin {
  static const _accent = AppColors.gameColorMatch;

  final ColorMatchController _controller = ColorMatchController();

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
      type: GameType.colorMatch,
      score: _controller.score.clamp(0, 999999),
      accuracy: _controller.accuracy,
      maxCombo: _controller.maxCombo,
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

  @override
  Widget build(BuildContext context) {
    final best =
        context.watch<ScoreService>().getBestScore(GameType.colorMatch);

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
                      title: 'Color Match',
                      score: _controller.score.clamp(0, 999999),
                      best: best,
                      combo: _controller.combo,
                      lives: _controller.lives,
                      timerText: _controller.isRunning
                          ? _controller.timerText
                          : null,
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

                      final target = _controller.target;
                      if (target == null) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            Text(
                              'Match this',
                              style: AppTextStyles.titleSmall,
                            ),
                            const SizedBox(height: 12),
                            _ShapeTile(
                              option: target,
                              size: 88,
                              showBorder: true,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _shapeLabel(target.shape),
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 24),
                            Expanded(
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount:
                                      _controller.options.length <= 4 ? 2 : 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1,
                                ),
                                itemCount: _controller.options.length,
                                itemBuilder: (context, index) {
                                  final opt = _controller.options[index];
                                  return GestureDetector(
                                    onTap: () async {
                                      if (_showCountdown || _showGameOver) {
                                        return;
                                      }
                                      final haptic =
                                          context.read<HapticService>();
                                      final sound =
                                          context.read<SoundService>();
                                      final ok =
                                          _controller.selectOption(opt);
                                      if (ok) {
                                        await haptic.light();
                                        await sound.playSuccess();
                                      } else {
                                        await haptic.medium();
                                        await sound.playFail();
                                      }
                                    },
                                    child: _ShapeTile(option: opt, size: 64),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            if (_showCountdown)
              CountdownOverlay(
                instruction:
                    'Tap the matching color AND shape\n+10 correct · -5 wrong',
                onDone: () {
                  setState(() => _showCountdown = false);
                  _controller.startGame();
                },
              ),
            if (_showGameOver && _result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'Color Match',
                accentColor: _accent,
                onReplay: _replay,
                onHome: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }

  String _shapeLabel(MatchShape shape) {
    switch (shape) {
      case MatchShape.circle:
        return 'Circle';
      case MatchShape.square:
        return 'Square';
      case MatchShape.triangle:
        return 'Triangle';
      case MatchShape.diamond:
        return 'Diamond';
      case MatchShape.star:
        return 'Star';
      case MatchShape.hexagon:
        return 'Hexagon';
    }
  }
}

class _ShapeTile extends StatelessWidget {
  const _ShapeTile({
    required this.option,
    required this.size,
    this.showBorder = false,
  });

  final ColorOption option;
  final double size;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: AppRadius.large,
        border: showBorder
            ? Border.all(color: AppColors.gameColorMatch, width: 3)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size, size),
          painter: _ShapePainter(
            shape: option.shape,
            color: option.color,
          ),
        ),
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter({required this.shape, required this.color});

  final MatchShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.shortestSide * 0.38;

    switch (shape) {
      case MatchShape.circle:
        canvas.drawCircle(Offset(cx, cy), r, paint);
      case MatchShape.square:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
            const Radius.circular(6),
          ),
          paint,
        );
      case MatchShape.triangle:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy + r * 0.85)
          ..lineTo(cx - r, cy + r * 0.85)
          ..close();
        canvas.drawPath(path, paint);
      case MatchShape.diamond:
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(path, paint);
      case MatchShape.star:
        _drawStar(canvas, Offset(cx, cy), r, paint);
      case MatchShape.hexagon:
        _drawPolygon(canvas, Offset(cx, cy), r, 6, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    const points = 5;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? radius : radius * 0.45;
      final angle = (i * pi / points) - pi / 2;
      final x = center.dx + cos(angle) * r;
      final y = center.dy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    int sides,
    Paint paint,
  ) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = (i * 2 * pi / sides) - pi / 2;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) =>
      shape != old.shape || color != old.color;
}
