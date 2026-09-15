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

import 'bird_hit_controller.dart';

class BirdHitScreen extends StatefulWidget {
  const BirdHitScreen({super.key});

  @override
  State<BirdHitScreen> createState() => _BirdHitScreenState();
}

class _BirdHitScreenState extends State<BirdHitScreen> with GameFinishMixin {
  static const _accent = AppColors.gameBirdHit;

  late BirdHitController _controller;
  bool _showCountdown = true;
  ScoreResult? _result;
  bool _handlingGameOver = false;

  @override
  void initState() {
    super.initState();
    _controller = BirdHitController();
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
      type: GameType.birdHit,
      score: _controller.score,
      accuracy: _controller.accuracy,
      maxCombo: _controller.maxCombo,
      elapsed: Duration(seconds: _controller.durationSeconds - _controller.timeLeft),
      extraStats: {
        'Hits': '${_controller.hits}',
        'Escapes': '${_controller.escapes}',
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
    _controller = BirdHitController();
    _controller.addListener(_onControllerChanged);
  }

  Future<void> _onTapDown(TapDownDetails details, Size areaSize) async {
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    final hit = _controller.tryHitBird(details.localPosition, areaSize);

    if (hit) {
      await haptic.light();
      await sound.playSuccess();
      if (_controller.combo > 2) {
        await sound.playCombo();
        await haptic.medium();
      }
    } else {
      _controller.registerMiss();
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
    final best = context.watch<ScoreService>().getBestScore(GameType.birdHit);
    final accuracy = _controller.accuracy;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(
              child: CharacterBackdrop(
                assetPath: 'assets/characters/bird_hunter.png',
                opacity: 0.22,
                widthFactor: 0.55,
                alignment: Alignment.bottomLeft,
                fadeLeft: false,
              ),
            ),
            Column(
              children: [
                GameHud(
                  title: 'Bird Hit',
                  score: _controller.score,
                  best: best,
                  combo: _controller.combo,
                  timerText: '${_controller.timeLeft}s',
                  accentColor: _accent,
                  extra: accuracy != null
                      ? Text(
                          'Accuracy: ${accuracy.toStringAsFixed(0)}%',
                          style: AppTextStyles.caption,
                        )
                      : null,
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );

                      return Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: ClipRRect(
                          borderRadius: AppRadius.large,
                          child: GestureDetector(
                            onTapDown: (d) => _onTapDown(d, size),
                            behavior: HitTestBehavior.opaque,
                            child: CustomPaint(
                              size: size,
                              painter: _BirdHitPainter(
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
                    'Large +10 · Medium +15 · Small +20 · Golden +50 · Miss -2',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            if (_showCountdown)
              CountdownOverlay(
                instruction: 'Tap birds in flight — golden birds are worth more!',
                onDone: _startGame,
              ),
            if (_result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'Bird Hit',
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

class _BirdHitPainter extends CustomPainter {
  _BirdHitPainter({
    required this.controller,
    required this.accent,
  });

  final BirdHitController controller;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    _drawSky(canvas, size);
    _drawClouds(canvas, size);
    _drawGround(canvas, size);

    for (final bird in controller.birds) {
      final cx = bird.x * size.width;
      final cy = bird.y * size.height;
      _drawBird(
        canvas,
        Offset(cx, cy),
        bird.size.scale,
        bird.facingRight,
        bird.wingOffset,
        isGolden: bird.isGolden,
      );
    }

    for (final effect in controller.hitEffects) {
      final age =
          DateTime.now().difference(effect.createdAt).inMilliseconds / 600;
      final alpha = (1 - age).clamp(0.0, 1.0);
      final color = effect.isGolden ? AppColors.accent : accent;
      for (var i = 0; i < 8; i++) {
        final angle = i * pi / 4;
        final dist = 10 + age * 40;
        canvas.drawCircle(
          Offset(
            effect.x + cos(angle) * dist,
            effect.y + sin(angle) * dist,
          ),
          3.5 * (1 - age * 0.5),
          Paint()..color = color.withValues(alpha: alpha * 0.8),
        );
      }
      final textPainter = TextPainter(
        text: TextSpan(
          text: effect.isGolden ? '+50' : '+',
          style: AppTextStyles.titleSmall.copyWith(
            color: color.withValues(alpha: alpha),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(effect.x - textPainter.width / 2, effect.y - 30 - age * 20),
      );
    }
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
            const Color(0xFF4DA8DA),
            const Color(0xFF87CEEB),
            const Color(0xFFB8E2F2),
            const Color(0xFFE8F4F8),
          ],
          stops: const [0.0, 0.35, 0.72, 1.0],
        ).createShader(rect),
    );

    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.1),
      36,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFFF9C4),
            const Color(0xFFFFE082).withValues(alpha: 0.6),
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.82, size.height * 0.1),
          radius: 36,
        )),
    );
  }

  void _drawClouds(Canvas canvas, Size size) {
    _drawCloud(canvas, Offset(size.width * 0.2, size.height * 0.14), 1.0);
    _drawCloud(canvas, Offset(size.width * 0.55, size.height * 0.08), 0.75);
    _drawCloud(canvas, Offset(size.width * 0.78, size.height * 0.22), 0.6);
  }

  void _drawCloud(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final r = 22.0 * scale;
    canvas.drawCircle(center, r, paint);
    canvas.drawCircle(center + Offset(-r * 0.9, r * 0.15), r * 0.75, paint);
    canvas.drawCircle(center + Offset(r * 0.85, r * 0.1), r * 0.8, paint);
    canvas.drawCircle(center + Offset(0, r * 0.35), r * 0.65, paint);
  }

  void _drawGround(Canvas canvas, Size size) {
    final groundTop = size.height * 0.82;
    final hillPath = Path()
      ..moveTo(0, groundTop + 20)
      ..quadraticBezierTo(
        size.width * 0.25,
        groundTop - 30,
        size.width * 0.5,
        groundTop + 10,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        groundTop + 40,
        size.width,
        groundTop + 5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      hillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF52B788),
            const Color(0xFF2D6A4F),
          ],
        ).createShader(Rect.fromLTWH(0, groundTop - 40, size.width, size.height)),
    );

    for (var i = 0; i < 12; i++) {
      final x = i * (size.width / 11) + 8;
      final h = 14 + (i % 3) * 6.0;
      final grass = Path()
        ..moveTo(x, groundTop + 18)
        ..quadraticBezierTo(x + 4, groundTop + 18 - h, x + 8, groundTop + 18);
      canvas.drawPath(
        grass,
        Paint()
          ..color = const Color(0xFF40916C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawBird(
    Canvas canvas,
    Offset center,
    double scale,
    bool facingRight,
    double wingPhase, {
    bool isGolden = false,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    if (!facingRight) canvas.scale(-1, 1);

    if (isGolden) {
      canvas.drawCircle(
        Offset.zero,
        34 * scale,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    final bodyColor = isGolden
        ? const Color(0xFFFFD166)
        : const Color(0xFF2B2D42);
    final wingLift = sin(wingPhase) * 8 * scale;

    final bodyPath = Path()
      ..addOval(Rect.fromCenter(
        center: Offset(2 * scale, 0),
        width: 36 * scale,
        height: 22 * scale,
      ));
    canvas.drawPath(bodyPath, Paint()..color = bodyColor);

    canvas.drawCircle(
      Offset(16 * scale, -4 * scale),
      9 * scale,
      Paint()..color = bodyColor,
    );
    canvas.drawCircle(
      Offset(20 * scale, -5 * scale),
      2.5 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(20.5 * scale, -5 * scale),
      1.2 * scale,
      Paint()..color = Colors.black87,
    );

    final beak = Path()
      ..moveTo(24 * scale, -4 * scale)
      ..lineTo(32 * scale, -2 * scale)
      ..lineTo(24 * scale, 0)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFE07A5F));

    final wingPath = Path()
      ..moveTo(-2 * scale, -2 * scale)
      ..quadraticBezierTo(
        -18 * scale,
        -14 * scale + wingLift,
        -28 * scale,
        4 * scale + wingLift * 0.5,
      )
      ..quadraticBezierTo(
        -14 * scale,
        6 * scale,
        -2 * scale,
        2 * scale,
      )
      ..close();
    canvas.drawPath(
      wingPath,
      Paint()..color = isGolden ? const Color(0xFFF4A261) : const Color(0xFF3D405B),
    );

    final tailPath = Path()
      ..moveTo(-16 * scale, 2 * scale)
      ..lineTo(-26 * scale, -6 * scale + wingLift * 0.3)
      ..lineTo(-22 * scale, 6 * scale)
      ..close();
    canvas.drawPath(tailPath, Paint()..color = bodyColor);

    if (isGolden) {
      final sparkle = Paint()..color = Colors.white.withValues(alpha: 0.7);
      canvas.drawCircle(Offset(-8 * scale, -10 * scale), 2 * scale, sparkle);
      canvas.drawCircle(Offset(6 * scale, 8 * scale), 1.5 * scale, sparkle);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BirdHitPainter oldDelegate) => true;
}
