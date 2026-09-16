import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_spacing.dart';
import '../../core/constants/app_config.dart';

class _Beat {
  const _Beat({required this.kicker, required this.title, required this.body});

  final String kicker;
  final String title;
  final String body;
}

/// Opening cutscene. Skip jumps the story the way a GTA intro does.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const _beats = [
    _Beat(
      kicker: 'CHENNAI  ·  NIGHT',
      title: 'The city is already moving.',
      body: 'Every road has a name. Every turn has a distance. You do not invent the path. You follow it.',
    ),
    _Beat(
      kicker: 'THE JOB',
      title: 'One route. One finish.',
      body: 'Pick a driver. Pick a car. The map draws the line from start pin to end pin. Stay on it.',
    ),
    _Beat(
      kicker: 'HOW YOU DRIVE',
      title: 'Look through the chase cam.',
      body: 'The road bends with the map. People walk. Hold gas. Touch left or right to steer. Finish the pin.',
    ),
  ];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 4200), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (_index >= _beats.length - 1) {
      widget.onDone();
      return;
    }
    setState(() => _index += 1);
    _arm();
  }

  void _skip() {
    _timer?.cancel();
    HapticFeedback.selectionClick();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beat = _beats[_index];
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF070B12),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF070B12)),
            const _NightStreet(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          AppConfig.appName,
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _skip,
                          child: const Text(
                            'SKIP',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.1),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      child: Column(
                        key: ValueKey(_index),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            beat.kicker,
                            style: const TextStyle(
                              color: Color(0xFF8AB4F8),
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            beat.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            beat.body,
                            style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        for (var i = 0; i < _beats.length; i++)
                          Container(
                            width: i == _index ? 22 : 8,
                            height: 4,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: i == _index ? Colors.white : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _advance,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1A73E8),
                            shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                          ),
                          child: Text(_index == _beats.length - 1 ? 'CONTINUE' : 'NEXT'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NightStreet extends StatelessWidget {
  const _NightStreet();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StreetPainter(), child: const SizedBox.expand());
  }
}

class _StreetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Rect.fromLTWH(0, 0, size.width, size.height * 0.46);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E1A33), Color(0xFF1C3358), Color(0xFF6A4A3A)],
        ).createShader(sky),
    );
    final road = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.38, size.height * 0.46)
      ..lineTo(size.width * 0.62, size.height * 0.46)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF2A3038));
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.46),
      Offset(size.width * 0.5, size.height),
      Paint()
        ..color = const Color(0xFFE6C15A)
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
