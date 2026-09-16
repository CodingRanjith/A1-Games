import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:a1_games/app/theme/app_colors.dart';
import 'package:a1_games/app/theme/app_text_styles.dart';
import 'package:a1_games/core/services/game_launcher.dart';
import 'package:a1_games/core/services/haptic_service.dart';
import 'package:a1_games/core/services/sound_service.dart';
import 'package:a1_games/models/game_session.dart';
import 'package:a1_games/models/game_type.dart';
import 'package:a1_games/shared/dialogs/game_over_overlay.dart';
import 'package:a1_games/shared/widgets/countdown_overlay.dart';

import '../../story/mission_briefing.dart';
import 'car_catalog.dart';
import 'characters/character_models.dart';
import 'car_garage_service.dart';
import 'car_race_controller.dart';
import 'car_sprite_cache.dart';
import 'chennai_route.dart';
import 'live_race_map.dart';
import 'car_race_painter.dart';
import 'camera/drive_camera.dart';
import 'city/city_catalog.dart';
import 'render/model_cache.dart';
import 'vehicle/car_config.dart';

class CarRaceScreen extends StatefulWidget {
  const CarRaceScreen({super.key, this.onExit});

  final VoidCallback? onExit;

  @override
  State<CarRaceScreen> createState() => _CarRaceScreenState();
}

class _CarRaceScreenState extends State<CarRaceScreen> with GameFinishMixin {
  static const _accent = AppColors.gameCarRace;

  late CarRaceController _controller;
  bool _showBriefing = false;
  bool _showCountdown = false;
  ScoreResult? _result;
  bool _handlingGameOver = false;
  Offset? _dragStart;
  bool _didBindGarage = false;
  final CameraRig _camera = CameraRig();

  @override
  void initState() {
    super.initState();
    _controller = CarRaceController(spec: CarCatalog.playerCars.first);
    _controller.addListener(_onChanged);
    CarSpriteCache.preload().then((_) {
      if (mounted) setState(() {});
    });
    ModelCache.load(CarConfigs.emberGt.modelPath);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBindGarage) return;
    _didBindGarage = true;
    _applyGarageCar();
    _beginRaceEntry();
  }

  void _beginRaceEntry() {
    ModelCache.load(_controller.carConfig.modelPath);
    ModelCache.preload([
      ...CityCatalog.streamingPaths,
      ...CharacterModels.preloadPaths,
    ]);
    for (final id in CharacterModels.ids) {
      ModelCache.loadImage(CharacterModels.textureFor(id));
    }
    _camera.copyFrom(CameraRig.presets[_controller.cameraPreset]);
    setState(() {
      _showBriefing = true;
      _showCountdown = false;
      _result = null;
      _handlingGameOver = false;
    });
  }

  void _skipToCountdown() {
    setState(() {
      _showBriefing = false;
      _showCountdown = true;
    });
  }

  void _cycleCamera() {
    _controller.cycleCamera();
    _camera.copyFrom(CameraRig.presets[_controller.cameraPreset]);
  }

  void _leave() {
    final exit = widget.onExit;
    if (exit != null) {
      exit();
      return;
    }
    Navigator.of(context).pop();
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
      fromIndex: garage.fromIndex,
      toIndex: garage.toIndex,
      map: garage.route,
    );
    _controller.satelliteView = garage.satelliteView;
    _controller.driverId = garage.driver.id;
    _controller.driverSuit = garage.driver.suit;
    _controller.driverHair = garage.driver.hair;
    _controller.driverSkin = garage.driver.skin;
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
        'From': _controller.fromName,
        'To': _controller.toName,
        'Distance': '${_controller.distanceKm.toStringAsFixed(1)} / ${_controller.tripKm.toStringAsFixed(1)} km',
        'ETA': _controller.etaLabel,
        'Area': _controller.currentPlace,
        'Top Speed': '${_controller.peakKmh.toStringAsFixed(0)} km/h',
        'Coins': '${_controller.coins}',
        'Car': _controller.spec.name,
        if (_controller.isFinished) 'Result': 'Finished',
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

  void _replay() {
    _applyGarageCar();
    setState(() {
      _result = null;
      _showBriefing = false;
      _showCountdown = true;
      _handlingGameOver = false;
    });
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
    final driver = context.watch<CarGarageService>().driver;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return GestureDetector(
                onHorizontalDragStart: (d) => _dragStart = d.globalPosition,
                onHorizontalDragUpdate: (d) {
                  if (!_controller.isRunning || _controller.isPaused) return;
                  final w = MediaQuery.sizeOf(context).width;
                  _controller.setSteer((d.globalPosition.dx / w - 0.5) * 2);
                },
                onHorizontalDragEnd: (_) {
                  final start = _dragStart;
                  _dragStart = null;
                  _controller.setSteer(0);
                  if (start == null) return;
                },
                child: CustomPaint(
                  painter: CityRacePainter(controller: _controller),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * 0.36,
            child: _SteerZone(
              alignLeft: true,
              enabled: _controller.isRunning && !_controller.isPaused,
              onDown: () => _controller.setSteer(-1),
              onUp: () => _controller.setSteer(0),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: MediaQuery.sizeOf(context).width * 0.36,
            child: _SteerZone(
              alignLeft: false,
              enabled: _controller.isRunning && !_controller.isPaused,
              onDown: () => _controller.setSteer(1),
              onUp: () => _controller.setSteer(0),
            ),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
                final mapHeight = landscape ? 92.0 : 148.0;
                return Stack(
                  children: [
                    Positioned(
                      left: landscape ? 64 : 12,
                      right: 12,
                      top: 8,
                      height: mapHeight,
                      child: _RaceMapCard(controller: _controller),
                    ),
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _RoundIcon(
                        icon: Icons.arrow_back_rounded,
                        onTap: _leave,
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: landscape ? 56 : mapHeight + 16,
                      child: _RoundIcon(
                        icon: Icons.videocam_rounded,
                        onTap: _cycleCamera,
                      ),
                    ),
                    Positioned(
                      left: 8,
                      top: landscape ? 104 : mapHeight + 64,
                      child: _RoundIcon(
                        icon: _controller.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        onTap: _controller.isRunning && !_controller.isGameOver
                            ? () {
                                setState(() {
                                  if (_controller.isPaused) {
                                    _controller.resume();
                                  } else {
                                    _controller.pause();
                                  }
                                });
                              }
                            : null,
                      ),
                    ),
                    if (_controller.isRunning && !landscape)
                      Positioned(
                        left: 16,
                        right: 16,
                        top: mapHeight + 18,
                        child: IgnorePointer(
                          child: Text(
                            '${_controller.speedKmh.toStringAsFixed(0)} km/h  ·  ${_controller.timerText}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: 14,
                      bottom: landscape ? 16 : 28,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _Pedal(
                            holes: 4,
                            pressed: _controller.brakeHeld,
                            onDown: () => _controller.setBrake(true),
                            onUp: () => _controller.setBrake(false),
                            enabled: _controller.isRunning && !_controller.isPaused,
                          ),
                          const SizedBox(width: 12),
                          _HoldControl(
                            label: 'GAS',
                            pressed: _controller.throttleHeld,
                            enabled: _controller.isRunning && !_controller.isPaused,
                            color: const Color(0xFF2D6A4F),
                            onDown: () => _controller.setThrottle(true),
                            onUp: () => _controller.setThrottle(false),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 110,
                            child: _BoostBar(
                              value: _controller.nitroFuel,
                              boosting: _controller.nitroActive,
                              onTap: _nitro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
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
          if (_showBriefing)
            MissionBriefing(
              driver: driver,
              from: _controller.fromName,
              to: _controller.toName,
              roads: _controller.route.roadsBetween(_controller.fromIndex, _controller.toIndex),
              distance: '${_controller.route.tripKm(_controller.fromIndex, _controller.toIndex).toStringAsFixed(1)} km',
              eta: _controller.route.etaLabel(
                _controller.route.tripKm(_controller.fromIndex, _controller.toIndex),
                kmh: 42,
              ),
              onStart: _skipToCountdown,
              onSkip: _skipToCountdown,
            ),
          if (_showCountdown)
            CountdownOverlay(
              instruction:
                  'Hold GAS to accelerate. Touch the left or right side to steer.\nFinish the route. Other cars are gone — just drive.',
              onDone: _start,
            ),
          if (_result != null)
            GameOverOverlay(
              result: _result!,
              gameName: 'Route Racer',
              headline: _controller.isFinished ? 'FINISHED!' : 'GAME OVER',
              accentColor: _accent,
              onReplay: _replay,
              onHome: _leave,
            ),
        ],
      ),
    );
  }
}

class _RaceMapCard extends StatelessWidget {
  const _RaceMapCard({required this.controller});

  final CarRaceController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          LiveRaceMap(
            controller: controller,
            satellite: controller.satelliteView,
            fromIndex: controller.fromIndex,
            toIndex: controller.toIndex,
            follow: true,
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 6,
            child: _NavCard(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({required this.controller});

  final CarRaceController controller;

  String _meters(double m) {
    if (m >= 950) return '${(m / 1000).toStringAsFixed(1)} km';
    final rounded = (m / 10).round() * 10;
    return '${rounded.clamp(10, 900)} m';
  }

  @override
  Widget build(BuildContext context) {
    final hint = controller.navHint;
    final next = controller.upcomingTurns.length > 1 ? controller.upcomingTurns[1] : null;
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xF0FFFFFF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFF1A73E8), shape: BoxShape.circle),
                child: Icon(_iconFor(hint.turn), color: Colors.white, size: 24),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hint.turn == NavTurn.arrive ? 'Arrive' : _meters(hint.metersAhead),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF202124)),
                    ),
                    Text(
                      '${hint.title} · ${hint.road}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3C4043)),
                    ),
                    Text(
                      next == null
                          ? 'On ${controller.currentRoad}'
                          : 'Then ${next.title.toLowerCase()} onto ${next.road}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _iconFor(NavTurn turn) {
  switch (turn) {
    case NavTurn.left:
    case NavTurn.slightLeft:
      return Icons.turn_left_rounded;
    case NavTurn.right:
    case NavTurn.slightRight:
      return Icons.turn_right_rounded;
    case NavTurn.arrive:
      return Icons.flag_rounded;
    case NavTurn.depart:
    case NavTurn.straight:
      return Icons.straight_rounded;
  }
}

class _SteerZone extends StatelessWidget {
  const _SteerZone({
    required this.alignLeft,
    required this.enabled,
    required this.onDown,
    required this.onUp,
  });

  final bool alignLeft;
  final bool enabled;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    return Padding(
      padding: EdgeInsets.only(top: landscape ? 110 : 210, bottom: 120),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanDown: enabled ? (_) => onDown() : null,
        onPanEnd: enabled ? (_) => onUp() : null,
        onPanCancel: enabled ? onUp : null,
        child: Align(
          alignment: alignLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Icon(
              alignLeft ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 42,
            ),
          ),
        ),
      ),
    );
  }
}

class _HoldControl extends StatelessWidget {
  const _HoldControl({
    required this.label,
    required this.pressed,
    required this.enabled,
    required this.color,
    required this.onDown,
    required this.onUp,
  });

  final String label;
  final bool pressed;
  final bool enabled;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback onUp;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled ? (_) => onDown() : null,
      onPointerUp: enabled ? (_) => onUp() : null,
      onPointerCancel: enabled ? (_) => onUp() : null,
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 78,
          height: 78,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: pressed ? color : color.withValues(alpha: 0.82),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 0.6),
          ),
        ),
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _Pedal extends StatelessWidget {
  const _Pedal({
    required this.holes,
    required this.pressed,
    required this.onDown,
    required this.onUp,
    required this.enabled,
  });

  final int holes;
  final bool pressed;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled ? (_) => onDown() : null,
      onPointerUp: enabled ? (_) => onUp() : null,
      onPointerCancel: enabled ? (_) => onUp() : null,
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 80),
        child: CustomPaint(
          size: const Size(52, 78),
          painter: _PedalPainter(holes: holes, pressed: pressed),
        ),
      ),
    );
  }
}

class _PedalPainter extends CustomPainter {
  _PedalPainter({required this.holes, required this.pressed});

  final int holes;
  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    canvas.drawRRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: pressed
              ? const [Color(0xFF1A1A1A), Color(0xFF3A3A3A)]
              : const [Color(0xFF2A2A2A), Color(0xFF101010)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRRect(
      r,
      Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final hole = Paint()..color = const Color(0xFF0A0A0A);
    final cols = 2;
    final rows = (holes / cols).ceil();
    var n = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        if (n >= holes) break;
        final cx = size.width * (0.32 + col * 0.36);
        final cy = size.height * (0.22 + row * (0.56 / math.max(1, rows - 1)));
        canvas.drawCircle(Offset(cx, cy), 6.2, hole);
        n++;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PedalPainter oldDelegate) =>
      oldDelegate.pressed != pressed || oldDelegate.holes != holes;
}

class _BoostBar extends StatelessWidget {
  const _BoostBar({
    required this.value,
    required this.boosting,
    required this.onTap,
  });

  final double value;
  final bool boosting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 18,
        child: Column(
          children: [
            const Text(
              'Boost',
              style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Container(
                        width: 12,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                      Container(
                        width: 12,
                        height: box.maxHeight * value.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: boosting
                                ? const [Color(0xFFFF9A3C), Color(0xFFFF4D00)]
                                : const [Color(0xFFC0392B), Color(0xFFE74C3C)],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

