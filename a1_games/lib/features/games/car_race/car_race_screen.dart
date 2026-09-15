import 'dart:math' as math;

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

import 'car_catalog.dart';
import 'car_garage_service.dart';
import 'car_race_controller.dart';
import 'car_race_painter.dart';
import 'car_select_screen.dart';
import 'car_sprite_cache.dart';

class CarRaceScreen extends StatefulWidget {
  const CarRaceScreen({super.key});

  @override
  State<CarRaceScreen> createState() => _CarRaceScreenState();
}

class _CarRaceScreenState extends State<CarRaceScreen> with GameFinishMixin {
  static const _accent = AppColors.gameCarRace;

  late CarRaceController _controller;
  bool _showGarage = true;
  bool _showCountdown = false;
  ScoreResult? _result;
  bool _handlingGameOver = false;
  Offset? _dragStart;
  bool _didBindGarage = false;

  @override
  void initState() {
    super.initState();
    _controller = CarRaceController(spec: CarCatalog.playerCars.first);
    _controller.addListener(_onChanged);
    CarSpriteCache.preload().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBindGarage) return;
    _didBindGarage = true;
    _applyGarageCar();
  }

  void _applyGarageCar() {
    final garage = context.read<CarGarageService>();
    final spec = garage.selectedCar;
    final up = garage.upgradesFor(spec.id);
    _controller.removeListener(_onChanged);
    _controller.disposeController();
    _controller = CarRaceController(
      spec: spec,
      engineLevel: up.engine,
      nitroLevel: up.nitro,
    );
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (_controller.isGameOver && !_handlingGameOver && _result == null) {
      _handleGameOver();
    }
  }

  Future<void> _handleGameOver() async {
    _handlingGameOver = true;
    await context.read<CarGarageService>().addCoins(_controller.coins);
    final result = await finishGame(
      type: GameType.carRace,
      score: _controller.score,
      maxCombo: _controller.maxCombo,
      elapsed: _controller.elapsed,
      extraStats: {
        'Distance': '${_controller.distanceKm.toStringAsFixed(1)} km',
        'Top Speed': '${_controller.peakKmh.toStringAsFixed(0)} km/h',
        'City': _controller.city.label,
        'Coins': '${_controller.coins}',
        'Position': 'P${_controller.racePosition}',
        'Car': _controller.spec.name,
      },
    );
    if (!mounted) return;
    setState(() {
      _result = result;
      _handlingGameOver = false;
    });
  }

  void _start() {
    setState(() => _showCountdown = false);
    _controller.start();
  }

  void _openRaceFromGarage() {
    _applyGarageCar();
    setState(() {
      _showGarage = false;
      _showCountdown = true;
      _result = null;
      _handlingGameOver = false;
    });
  }

  void _replay() {
    _applyGarageCar();
    setState(() {
      _result = null;
      _showGarage = false;
      _showCountdown = true;
      _handlingGameOver = false;
    });
  }

  Future<void> _steer(void Function() action) async {
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    action();
    await haptic.selection();
    await sound.playTap();
  }

  Future<void> _nitro() async {
    final ok = _controller.activateNitro();
    if (!ok) return;
    final haptic = context.read<HapticService>();
    final sound = context.read<SoundService>();
    await haptic.medium();
    await sound.playTap();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.disposeController();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final best = context.watch<ScoreService>().getBestScore(GameType.carRace);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Column(
                  children: [
                    GameHud(
                      title: 'City Racer',
                      score: _controller.score,
                      best: best,
                      combo: _controller.combo > 0 ? _controller.combo : null,
                      accentColor: _accent,
                      onPause: _controller.isRunning && !_controller.isGameOver
                          ? () {
                              if (_controller.isPaused) {
                                _controller.resume();
                              } else {
                                _controller.pause();
                              }
                            }
                          : null,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: ClipRRect(
                          borderRadius: AppRadius.large,
                          child: Stack(
                            children: [
                              GestureDetector(
                                onHorizontalDragStart: (d) => _dragStart = d.globalPosition,
                                onHorizontalDragEnd: (d) {
                                  final start = _dragStart;
                                  _dragStart = null;
                                  if (start == null) return;
                                  final dx = d.velocity.pixelsPerSecond.dx;
                                  if (dx < -280) {
                                    _steer(_controller.moveLeft);
                                  } else if (dx > 280) {
                                    _steer(_controller.moveRight);
                                  }
                                },
                                onTapUp: (d) {
                                  final box = context.findRenderObject() as RenderBox?;
                                  if (box == null) return;
                                  final local = d.localPosition;
                                  final w = box.size.width;
                                  if (local.dx < w * 0.42) {
                                    _steer(_controller.moveLeft);
                                  } else if (local.dx > w * 0.58) {
                                    _steer(_controller.moveRight);
                                  }
                                },
                                child: CustomPaint(
                                  painter: CityRacePainter(controller: _controller),
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              if (_controller.isRunning)
                                Positioned(
                                  left: 10,
                                  top: 10,
                                  child: _RaceChip(
                                    text:
                                        'P${_controller.racePosition}  ·  LAP ${_controller.lap}  ·  ${_controller.distanceKm.toStringAsFixed(1)} km',
                                  ),
                                ),
                              if (_controller.isRunning)
                                Positioned(
                                  right: 10,
                                  top: 10,
                                  child: _RaceChip(text: '🪙 ${_controller.coins}'),
                                ),
                              if (_controller.isRunning)
                                Positioned(
                                  left: 8,
                                  bottom: 8,
                                  child: _Speedometer(
                                    kmh: _controller.speedKmh,
                                    nitro: _controller.nitroFuel,
                                    boosting: _controller.nitroActive,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _ControlBar(
                      onLeft: () => _steer(_controller.moveLeft),
                      onRight: () => _steer(_controller.moveRight),
                      onNitro: _nitro,
                      onBrakeDown: () => _controller.setBrake(true),
                      onBrakeUp: () => _controller.setBrake(false),
                      onGasDown: () => _controller.setThrottle(true),
                      onGasUp: () => _controller.setThrottle(false),
                      paused: _controller.isPaused || !_controller.isRunning,
                      nitroReady: _controller.nitroFuel >= 0.28 && !_controller.nitroActive,
                    ),
                  ],
                );
              },
            ),
            if (_controller.isPaused && !_controller.isGameOver)
              Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('PAUSED', style: AppTextStyles.headline.copyWith(color: Colors.white)),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _controller.resume,
                      child: const Text('RESUME'),
                    ),
                  ],
                ),
              ),
            if (_showCountdown)
              CountdownOverlay(
                instruction:
                    'Swipe lanes to dodge traffic.\nHold GAS / BRAKE · tap NITRO.',
                onDone: _start,
              ),
            if (_result != null)
              GameOverOverlay(
                result: _result!,
                gameName: 'City Racer',
                accentColor: _accent,
                onReplay: _replay,
                onHome: () => Navigator.of(context).pop(),
              ),
            if (_showGarage)
              CarGaragePanel(
                onRace: _openRaceFromGarage,
                onBack: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }
}

class _RaceChip extends StatelessWidget {
  const _RaceChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Speedometer extends StatelessWidget {
  const _Speedometer({
    required this.kmh,
    required this.nitro,
    required this.boosting,
  });

  final double kmh;
  final double nitro;
  final bool boosting;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: CustomPaint(
        painter: _SpeedoPainter(kmh: kmh, nitro: nitro, boosting: boosting),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  kmh.toStringAsFixed(0),
                  style: AppTextStyles.title.copyWith(color: Colors.white, height: 1),
                ),
                Text('km/h', style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedoPainter extends CustomPainter {
  _SpeedoPainter({required this.kmh, required this.nitro, required this.boosting});

  final double kmh;
  final double nitro;
  final bool boosting;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2 + 6);
    final r = size.width * 0.42;
    final bg = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), math.pi * 0.75, math.pi * 1.5, false, bg);
    final t = (kmh / 280).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      math.pi * 0.75,
      math.pi * 1.5 * t,
      false,
      Paint()
        ..color = boosting ? const Color(0xFF4CC9F0) : AppColors.gameCarRace
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 12),
      math.pi * 0.75,
      math.pi * 1.5 * nitro.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = const Color(0xFF4CC9F0).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SpeedoPainter oldDelegate) =>
      oldDelegate.kmh != kmh || oldDelegate.nitro != nitro || oldDelegate.boosting != boosting;
}

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.onLeft,
    required this.onRight,
    required this.onNitro,
    required this.onBrakeDown,
    required this.onBrakeUp,
    required this.onGasDown,
    required this.onGasUp,
    required this.paused,
    required this.nitroReady,
  });

  final VoidCallback onLeft;
  final VoidCallback onRight;
  final VoidCallback onNitro;
  final VoidCallback onBrakeDown;
  final VoidCallback onBrakeUp;
  final VoidCallback onGasDown;
  final VoidCallback onGasUp;
  final bool paused;
  final bool nitroReady;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _HoldKey(
                  label: 'BRAKE',
                  color: const Color(0xFFE76F51),
                  enabled: !paused,
                  onDown: onBrakeDown,
                  onUp: onBrakeUp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TapKey(
                  label: 'NITRO',
                  color: const Color(0xFF4CC9F0),
                  enabled: !paused && nitroReady,
                  onTap: onNitro,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HoldKey(
                  label: 'GAS',
                  color: const Color(0xFF52B788),
                  enabled: !paused,
                  onDown: onGasDown,
                  onUp: onGasUp,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _TapKey(label: '◀ LEFT', color: AppColors.gameCarRace, enabled: !paused, onTap: onLeft)),
              const SizedBox(width: 12),
              Expanded(child: _TapKey(label: 'RIGHT ▶', color: AppColors.gameCarRace, enabled: !paused, onTap: onRight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TapKey extends StatelessWidget {
  const _TapKey({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: enabled ? 0.9 : 0.25),
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.medium,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(label, style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13)),
          ),
        ),
      ),
    );
  }
}

class _HoldKey extends StatelessWidget {
  const _HoldKey({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onDown,
    required this.onUp,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: enabled ? 0.9 : 0.25),
      borderRadius: AppRadius.medium,
      child: Listener(
        onPointerDown: enabled ? (_) => onDown() : null,
        onPointerUp: enabled ? (_) => onUp() : null,
        onPointerCancel: enabled ? (_) => onUp() : null,
        child: SizedBox(
          height: 48,
          child: Center(
            child: Text(label, style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13)),
          ),
        ),
      ),
    );
  }
}
