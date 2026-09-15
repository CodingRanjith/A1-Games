import 'dart:math' as math;
import 'dart:ui' as ui;

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

import 'city_survival_controller.dart';

/// Original characters only: Niko (hero kid) + Blue Bot (gadget buddy).
class CitySurvivalScreen extends StatefulWidget {
  const CitySurvivalScreen({super.key});

  @override
  State<CitySurvivalScreen> createState() => _CitySurvivalScreenState();
}

class _CitySurvivalScreenState extends State<CitySurvivalScreen>
    with GameFinishMixin {
  static const _accent = AppColors.gameCitySurvival;

  late CitySurvivalController _c;
  bool _showCountdown = true;
  ScoreResult? _result;
  bool _handlingOver = false;

  @override
  void initState() {
    super.initState();
    _c = CitySurvivalController();
    _c.addListener(_onChanged);
  }

  void _onChanged() {
    if (_c.isGameOver && !_handlingOver && _result == null) {
      _finish();
    }
    if (mounted) setState(() {});
  }

  Future<void> _finish() async {
    _handlingOver = true;
    final result = await finishGame(
      type: GameType.citySurvival,
      score: _c.score,
      maxCombo: _c.maxCombo,
      elapsed: _c.elapsed,
      extraStats: {
        'Kills': '${_c.kills}',
        'Stage': _c.stage == SurvivalStage.forest ? 'Forest' : 'City',
        'Combo': '${_c.maxCombo}',
      },
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _handlingOver = false;
    });
  }

  void _start() {
    setState(() => _showCountdown = false);
    _c.start();
  }

  void _replay() {
    setState(() {
      _result = null;
      _showCountdown = true;
      _handlingOver = false;
    });
    _c.removeListener(_onChanged);
    _c.disposeController();
    _c = CitySurvivalController();
    _c.addListener(_onChanged);
  }

  Future<void> _move(void Function() fn) async {
    final haptic = context.read<HapticService>();
    fn();
    await haptic.selection();
  }

  Future<void> _fight() async {
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    final hit = _c.attack();
    if (hit) {
      await haptic.medium();
      await sound.playSuccess();
    } else {
      await haptic.light();
      await sound.playTap();
    }
  }

  @override
  void dispose() {
    _c.removeListener(_onChanged);
    _c.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final best =
        context.watch<ScoreService>().getBestScore(GameType.citySurvival);

    return Scaffold(
      backgroundColor: const Color(0xFF0B120E),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                GameHud(
                  title: 'City Survival',
                  score: _c.score,
                  best: best,
                  lives: _c.lives,
                  combo: _c.combo > 0 ? _c.combo : null,
                  accentColor: _accent,
                  onPause: _c.isRunning && !_c.isGameOver
                      ? () => _c.isPaused ? _c.resume() : _c.pause()
                      : null,
                  extra: Text(
                    '${_c.stage == SurvivalStage.city ? "CITY STREETS" : "DARK FOREST"}  ·  Niko + Blue Bot',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ClipRRect(
                      borderRadius: AppRadius.large,
                      child: GestureDetector(
                        onHorizontalDragEnd: (d) {
                          final vx = d.velocity.pixelsPerSecond.dx;
                          if (vx < -250) {
                            _move(_c.moveLeft);
                          } else if (vx > 250) {
                            _move(_c.moveRight);
                          }
                        },
                        onTapUp: (d) {
                          final w = context.size?.width ?? 400;
                          if (d.localPosition.dx < w * 0.33) {
                            _move(_c.moveLeft);
                          } else if (d.localPosition.dx > w * 0.66) {
                            _move(_c.moveRight);
                          } else {
                            _fight();
                          }
                        },
                        child: CustomPaint(
                          painter: _SurvivalPainter(controller: _c),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                _Controls(
                  onLeft: () => _move(_c.moveLeft),
                  onFight: _fight,
                  onRight: () => _move(_c.moveRight),
                  enabled: _c.isRunning && !_c.isPaused && !_c.isGameOver,
                ),
              ],
            ),
            if (_c.isPaused && !_c.isGameOver)
              ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: FilledButton(
                    onPressed: _c.resume,
                    child: const Text('RESUME'),
                  ),
                ),
              ),
            if (_showCountdown)
              CountdownOverlay(
                instruction:
                    'Niko & Blue Bot vs zombies!\nSwipe to move · Tap center / FIGHT to attack\nCity → Forest',
                onDone: _start,
              ),
            if (_result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'City Survival',
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

class _Controls extends StatelessWidget {
  const _Controls({
    required this.onLeft,
    required this.onFight,
    required this.onRight,
    required this.enabled,
  });

  final VoidCallback onLeft;
  final VoidCallback onFight;
  final VoidCallback onRight;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: _Btn(
              label: '◀ MOVE',
              color: const Color(0xFF457B9D),
              onTap: enabled ? onLeft : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: _Btn(
              label: '⚔ FIGHT',
              color: AppColors.gameCitySurvival,
              onTap: enabled ? onFight : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _Btn(
              label: 'MOVE ▶',
              color: const Color(0xFF457B9D),
              onTap: enabled ? onRight : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  const _Btn({required this.label, required this.color, required this.onTap});

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: onTap == null ? 0.3 : 0.95),
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.medium,
        child: SizedBox(
          height: 56,
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.button.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurvivalPainter extends CustomPainter {
  _SurvivalPainter({required this.controller});

  final CitySurvivalController controller;

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.stage == SurvivalStage.city) {
      _paintCity(canvas, size);
    } else {
      _paintForest(canvas, size);
    }
    _paintGround(canvas, size);
    _paintZombies(canvas, size);
    _paintHeroes(canvas, size);
    _paintHits(canvas, size);
    if (controller.attackFlash) {
      canvas.drawCircle(
        _lanePoint(size, controller.playerLaneAnim, 0.72),
        48,
        Paint()
          ..color = const Color(0xFF4CC9F0).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _paintCity(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D1B2A), Color(0xFF1B263B), Color(0xFF243447)],
        ).createShader(rect),
    );

    final scroll = controller.scroll * 80;
    final rng = math.Random(42);
    var x = -scroll % 70;
    while (x < size.width + 40) {
      final w = 28.0 + rng.nextInt(36);
      final h = 70.0 + rng.nextInt(120);
      final top = size.height * 0.42 - h;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, top, w, h),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFF15202B),
      );
      final win = Paint()..color = const Color(0xFFFFB703).withValues(alpha: 0.45);
      for (var wy = top + 8; wy < size.height * 0.42 - 10; wy += 12) {
        for (var wx = x + 5; wx < x + w - 6; wx += 9) {
          if (rng.nextDouble() > 0.4) {
            canvas.drawRect(Rect.fromLTWH(wx, wy, 4, 5), win);
          }
        }
      }
      x += w + 8;
    }

    // Neon signs glow
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.22),
      30,
      Paint()
        ..color = const Color(0xFFF72585).withValues(alpha: 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _paintForest(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF08140E), Color(0xFF12261A), Color(0xFF1A3324)],
        ).createShader(rect),
    );

    final scroll = controller.scroll * 60;
    final rng = math.Random(99);
    var x = -scroll % 55;
    while (x < size.width + 30) {
      final trunkH = 90.0 + rng.nextInt(80);
      final base = size.height * 0.48;
      canvas.drawRect(
        Rect.fromLTWH(x + 10, base - trunkH, 10, trunkH),
        Paint()..color = const Color(0xFF3D2914),
      );
      canvas.drawCircle(
        Offset(x + 15, base - trunkH),
        22 + rng.nextInt(12).toDouble(),
        Paint()..color = Color.lerp(
          const Color(0xFF1B4332),
          const Color(0xFF2D6A4F),
          rng.nextDouble(),
        )!,
      );
      x += 40 + rng.nextInt(30);
    }

    // Moon shafts
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.12),
      22,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  void _paintGround(Canvas canvas, Size size) {
    final top = size.height * 0.48;
    final path = Path()
      ..moveTo(0, top)
      ..lineTo(size.width, top)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final isForest = controller.stage == SurvivalStage.forest;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isForest
              ? const [Color(0xFF2D4A3E), Color(0xFF1A2E24)]
              : const [Color(0xFF3A3A40), Color(0xFF222228)],
        ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
    );

    // Lane guides
    for (var i = 1; i < CitySurvivalController.laneCount; i++) {
      final t = i / CitySurvivalController.laneCount;
      canvas.drawLine(
        Offset(size.width * t, top),
        Offset(size.width * t, size.height),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08)
          ..strokeWidth = 2,
      );
    }
  }

  Offset _lanePoint(Size size, double lane, double yT) {
    final top = size.height * 0.48;
    final y = ui.lerpDouble(top, size.height * 0.92, yT.clamp(0.0, 1.0))!;
    final laneCenter = (lane + 0.5) / CitySurvivalController.laneCount;
    final x = size.width * laneCenter;
    return Offset(x, y);
  }

  void _paintZombies(Canvas canvas, Size size) {
    for (final z in controller.zombies) {
      final p = _lanePoint(size, z.lane.toDouble(), z.y);
      final scale = ui.lerpDouble(0.55, 1.15, z.y.clamp(0.0, 1.0))!;
      _drawZombie(canvas, p, scale, z);
    }
  }

  void _drawZombie(Canvas canvas, Offset c, double scale, Zombie z) {
    final s = 22.0 * scale;
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + s * 0.15), width: s * 1.1, height: s * 1.6),
        Radius.circular(6 * scale),
      ),
      Paint()..color = z.tint,
    );
    // Head
    canvas.drawCircle(
      Offset(c.dx, c.dy - s * 0.55),
      s * 0.42,
      Paint()..color = Color.lerp(z.tint, const Color(0xFFA7C957), 0.35)!,
    );
    // Eyes
    canvas.drawCircle(
      Offset(c.dx - s * 0.14, c.dy - s * 0.58),
      2.5 * scale,
      Paint()..color = Colors.redAccent,
    );
    canvas.drawCircle(
      Offset(c.dx + s * 0.14, c.dy - s * 0.58),
      2.5 * scale,
      Paint()..color = Colors.redAccent,
    );
    // HP bar for brutes
    if (z.maxHp > 1) {
      final bw = s * 1.2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(c.dx - bw / 2, c.dy - s * 1.25, bw, 5),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.black45,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            c.dx - bw / 2,
            c.dy - s * 1.25,
            bw * (z.hp / z.maxHp),
            5,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = Colors.lightGreenAccent,
      );
    }
  }

  void _paintHeroes(Canvas canvas, Size size) {
    final p = _lanePoint(size, controller.playerLaneAnim, 0.78);
    // Blue Bot (buddy) slightly behind-left
    _drawBlueBot(canvas, Offset(p.dx - 28, p.dy - 8), 0.95);
    // Niko (hero)
    _drawNiko(canvas, p, 1.15);
  }

  /// Original gadget buddy — round blue robot helper (not any franchise cat).
  void _drawBlueBot(Canvas canvas, Offset c, double scale) {
    final r = 16.0 * scale;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [Color(0xFF4CC9F0), Color(0xFF4361EE)],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      Offset(c.dx - 4 * scale, c.dy - 2 * scale),
      3 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(c.dx + 5 * scale, c.dy - 2 * scale),
      3 * scale,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(c.dx, c.dy + 5 * scale),
      2 * scale,
      Paint()..color = const Color(0xFFFFB703),
    );
    // Antenna
    canvas.drawLine(
      Offset(c.dx, c.dy - r),
      Offset(c.dx, c.dy - r - 8 * scale),
      Paint()
        ..color = Colors.white70
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(c.dx, c.dy - r - 8 * scale),
      3 * scale,
      Paint()..color = const Color(0xFFFF006E),
    );
  }

  /// Original kid hero Niko.
  void _drawNiko(Canvas canvas, Offset c, double scale) {
    final s = 20.0 * scale;
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + s * 0.2), width: s * 1.0, height: s * 1.4),
        Radius.circular(7 * scale),
      ),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF8C61), Color(0xFFE63946)],
        ).createShader(Rect.fromCenter(center: c, width: s, height: s * 2)),
    );
    // Head
    canvas.drawCircle(
      Offset(c.dx, c.dy - s * 0.55),
      s * 0.4,
      Paint()..color = const Color(0xFFFFDBB5),
    );
    // Hair
    canvas.drawArc(
      Rect.fromCircle(center: Offset(c.dx, c.dy - s * 0.65), radius: s * 0.42),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = const Color(0xFF3D2914)
        ..style = PaintingStyle.fill,
    );
    // Eyes
    canvas.drawCircle(
      Offset(c.dx - 4 * scale, c.dy - s * 0.55),
      2 * scale,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(c.dx + 4 * scale, c.dy - s * 0.55),
      2 * scale,
      Paint()..color = Colors.black87,
    );
  }

  void _paintHits(Canvas canvas, Size size) {
    final now = DateTime.now();
    for (final h in controller.hits) {
      final age = now.difference(h.born).inMilliseconds / 350.0;
      final p = _lanePoint(size, h.lane.toDouble(), h.y);
      canvas.drawCircle(
        p,
        18 * (1 - age),
        Paint()
          ..color = const Color(0xFF4CC9F0).withValues(alpha: 1 - age)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SurvivalPainter oldDelegate) => true;
}
