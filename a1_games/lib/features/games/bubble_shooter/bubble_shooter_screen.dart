import 'dart:math';

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

import 'bubble_shooter_controller.dart';

class BubbleShooterScreen extends StatefulWidget {
  const BubbleShooterScreen({super.key});

  @override
  State<BubbleShooterScreen> createState() => _BubbleShooterScreenState();
}

class _BubbleShooterScreenState extends State<BubbleShooterScreen>
    with GameFinishMixin {
  static const _accent = AppColors.gameBubbleShooter;

  late BubbleShooterController _controller;
  bool _showCountdown = true;
  ScoreResult? _result;
  bool _handlingGameOver = false;

  @override
  void initState() {
    super.initState();
    _controller = BubbleShooterController();
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
      type: GameType.bubbleShooter,
      score: _controller.score,
      maxCombo: _controller.maxCombo,
      elapsed: Duration(seconds: _controller.durationSeconds - _controller.timeLeft),
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
    _controller = BubbleShooterController();
    _controller.addListener(_onControllerChanged);
  }

  Future<void> _onShoot() async {
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    final beforeScore = _controller.score;
    _controller.shoot();
    await haptic.light();
    await sound.playSuccess();
    if (_controller.score > beforeScore && _controller.combo > 1) {
      await sound.playCombo();
      await haptic.medium();
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
    final best =
        context.watch<ScoreService>().getBestScore(GameType.bubbleShooter);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CharacterBackdrop(
                assetPath: 'assets/characters/bubble_shooter.png',
                opacity: 0.2,
                widthFactor: 0.5,
                alignment: Alignment.centerRight,
              ),
            ),
            Column(
              children: [
                GameHud(
                  title: 'Bubble Shooter',
                  score: _controller.score,
                  best: best,
                  combo: _controller.combo,
                  timerText: '${_controller.timeLeft}s',
                  accentColor: _accent,
                  extra: _NextBubbleBanner(colorIndex: _controller.nextColor),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      _controller.setPlaySize(size.width, size.height);

                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: AppRadius.large,
                          child: GestureDetector(
                            onPanUpdate: (d) {
                              if (d.localPosition.dy >
                                  size.height * 0.42) {
                                _controller.setAim(d.localPosition);
                              }
                            },
                            onPanEnd: (_) async {
                              await _onShoot();
                              _controller.clearAim();
                            },
                            onPanCancel: _controller.clearAim,
                            child: CustomPaint(
                              size: size,
                              painter: _BubbleShooterPainter(
                                controller: _controller,
                                accent: _accent,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Drag to aim · Release to shoot · Match 3+',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryDark,
                    ),
                  ),
                ),
              ],
            ),
            if (_showCountdown)
              CountdownOverlay(
                instruction: 'Clear bubbles before they reach the line!',
                onDone: _startGame,
              ),
            if (_result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'Bubble Shooter',
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

class _NextBubbleBanner extends StatelessWidget {
  const _NextBubbleBanner({required this.colorIndex});

  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final color = BubbleShooterController.bubbleColors[
        colorIndex % BubbleShooterController.bubbleColors.length];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.medium,
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Next: ', style: AppTextStyles.label),
          CustomPaint(
            size: const Size(24, 24),
            painter: _GlossyBubblePainter(color: color, radius: 11),
          ),
        ],
      ),
    );
  }
}

class _BubbleShooterPainter extends CustomPainter {
  _BubbleShooterPainter({
    required this.controller,
    required this.accent,
  });

  final BubbleShooterController controller;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawArcadeDecor(canvas, size);
    _drawDangerLine(canvas, size);

    for (final bubble in controller.grid) {
      final pos = controller.gridPosition(bubble.row, bubble.col);
      _drawGlossyBubble(
        canvas,
        pos,
        BubbleShooterController.bubbleRadius,
        BubbleShooterController.bubbleColors[bubble.colorIndex],
      );
    }

    for (final effect in controller.popEffects) {
      final age =
          DateTime.now().difference(effect.createdAt).inMilliseconds / 500;
      final alpha = (1 - age).clamp(0.0, 1.0);
      for (var i = 0; i < 6; i++) {
        final angle = i * pi / 3;
        final dist = 8 + age * 28;
        canvas.drawCircle(
          Offset(
            effect.x + cos(angle) * dist,
            effect.y + sin(angle) * dist,
          ),
          3 * (1 - age),
          Paint()..color = effect.color.withValues(alpha: alpha * 0.7),
        );
      }
    }

    final shooter = controller.shooterPosition;
    _drawGlossyBubble(
      canvas,
      shooter,
      BubbleShooterController.bubbleRadius * 1.05,
      BubbleShooterController.bubbleColors[controller.currentColor],
      glow: true,
    );

    if (controller.projectile != null) {
      final p = controller.projectile!;
      _drawGlossyBubble(
        canvas,
        Offset(p.x, p.y),
        BubbleShooterController.bubbleRadius,
        BubbleShooterController.bubbleColors[p.colorIndex],
      );
    }

    if (controller.aimPoint != null && controller.projectile == null) {
      _drawAimLine(canvas, shooter, controller.aimPoint!);
    }

    _drawShooterBase(canvas, shooter, size);
  }

  void _drawSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0B1D3A),
            const Color(0xFF1A4A7A),
            const Color(0xFF2E86AB),
            const Color(0xFF7EC8E3),
          ],
          stops: const [0.0, 0.35, 0.7, 1.0],
        ).createShader(rect),
    );

    final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < 40; i++) {
      final x = (i * 73.0 + 17) % size.width;
      final y = (i * 41.0 + 11) % (size.height * 0.55);
      canvas.drawCircle(Offset(x, y), 1 + (i % 3) * 0.4, starPaint);
    }
  }

  void _drawArcadeDecor(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = accent.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      60,
      glow,
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      45,
      glow,
    );

    final beam = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.5));
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, size.height * 0.45),
      beam,
    );
  }

  void _drawDangerLine(Canvas canvas, Size size) {
    final y = controller.dangerLineY;
    final dashPaint = Paint()
      ..color = AppColors.error.withValues(alpha: 0.75)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 10.0;
    const gap = 8.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + dashWidth, y), dashPaint);
      x += dashWidth + gap;
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'DANGER',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.error.withValues(alpha: 0.85),
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, y - 16));
  }

  void _drawAimLine(Canvas canvas, Offset from, Offset to) {
    final dir = to - from;
    if (dir.distance < 8) return;
    final norm = dir / dir.distance;
    final end = from + norm * min(dir.distance, 280);

    canvas.drawLine(
      from,
      end,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    for (var i = 1; i <= 8; i++) {
      final t = i / 8;
      final p = Offset.lerp(from, end, t)!;
      canvas.drawCircle(
        p,
        2.5,
        Paint()..color = accent.withValues(alpha: 0.5 - t * 0.3),
      );
    }
  }

  void _drawShooterBase(Canvas canvas, Offset shooter, Size size) {
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(shooter.dx, size.height - 18),
        width: 72,
        height: 28,
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      baseRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF3A506B),
            const Color(0xFF1C2541),
          ],
        ).createShader(baseRect.outerRect),
    );
    canvas.drawRRect(
      baseRect,
      Paint()
        ..color = accent.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawGlossyBubble(
    Canvas canvas,
    Offset center,
    double radius,
    Color color, {
    bool glow = false,
  }) {
    if (glow) {
      canvas.drawCircle(
        center,
        radius + 6,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    canvas.drawCircle(
      center + const Offset(0, 2),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.45),
          radius: 1.0,
          colors: [
            Color.lerp(color, Colors.white, 0.55)!,
            color,
            Color.lerp(color, Colors.black, 0.35)!,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * 0.28, -radius * 0.32),
        width: radius * 0.55,
        height: radius * 0.35,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.65),
    );

    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(radius * 0.22, radius * 0.28),
        width: radius * 0.18,
        height: radius * 0.12,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleShooterPainter oldDelegate) => true;
}

class _GlossyBubblePainter extends CustomPainter {
  _GlossyBubblePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(color, Colors.white, 0.5)!,
            color,
            Color.lerp(color, Colors.black, 0.3)!,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-radius * 0.25, -radius * 0.3),
        width: radius * 0.5,
        height: radius * 0.3,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
  }

  @override
  bool shouldRepaint(covariant _GlossyBubblePainter oldDelegate) =>
      color != oldDelegate.color;
}
