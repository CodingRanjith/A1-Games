import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';

class CountdownOverlay extends StatefulWidget {
  const CountdownOverlay({
    super.key,
    required this.onDone,
    this.instruction,
  });

  final VoidCallback onDone;
  final String? instruction;

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int _count = 3;
  Timer? _timer;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (!mounted) return;
      if (_count <= 1) {
        t.cancel();
        setState(() {
          _count = 0;
          _done = true;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) widget.onDone();
        });
      } else {
        setState(() => _count--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.instruction != null && !_done) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  widget.instruction!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),
            ],
            TweenAnimationBuilder<double>(
              key: ValueKey(_count),
              tween: Tween(begin: 0.5, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Text(
                _done ? 'GO!' : '$_count',
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 72,
                  color: _done ? AppColors.accent : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
