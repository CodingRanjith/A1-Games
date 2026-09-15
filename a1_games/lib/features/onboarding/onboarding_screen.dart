import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/constants/app_config.dart';

class _OnboardPage {
  const _OnboardPage({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.badge,
  });

  final String image;
  final String title;
  final String subtitle;
  final Color accent;
  final String badge;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _index = 0;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  static const _pages = [
    _OnboardPage(
      image: 'assets/onboarding/play.png',
      title: '10 Games.\nEndless Fun.',
      subtitle:
          'Race cities, hunt words, shoot bubbles, survive nights — all in one premium offline arcade.',
      accent: AppColors.primaryLight,
      badge: 'PLAY NOW',
    ),
    _OnboardPage(
      image: 'assets/onboarding/score.png',
      title: 'Beat Your\nBest Score.',
      subtitle:
          'Combos, streaks, and personal records stay on your phone. Challenge yourself every day.',
      accent: AppColors.secondary,
      badge: 'HIGH SCORE',
    ),
    _OnboardPage(
      image: 'assets/onboarding/offline.png',
      title: 'Play Anywhere.\nEven Offline.',
      subtitle:
          'No login. No Wi‑Fi needed. Open GameRush and play in airplane mode anytime.',
      accent: AppColors.accent,
      badge: 'OFFLINE READY',
    ),
  ];

  @override
  void dispose() {
    _pulse.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      widget.onDone();
      return;
    }
    _pageController.nextPage(
      duration: AppDurations.normal,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _CinematicPage(
                data: _pages[i],
                pulse: _pulse,
                isActive: i == _index,
              ),
            ),
            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 12, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Text(
                      AppConfig.appName,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onDone,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                      ),
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(24, 28, 24, 20 + bottomInset),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.92),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (i) {
                        final active = i == _index;
                        return AnimatedContainer(
                          duration: AppDurations.fast,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 28 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? page.accent
                                : Colors.white.withValues(alpha: 0.28),
                            borderRadius: AppRadius.pill,
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: page.accent.withValues(alpha: 0.55),
                                      blurRadius: 10,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: page.accent,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.medium,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _index == _pages.length - 1
                              ? "LET'S PLAY"
                              : 'CONTINUE',
                          style: AppTextStyles.button.copyWith(
                            color: const Color(0xFF0F1A15),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
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

class _CinematicPage extends StatelessWidget {
  const _CinematicPage({
    required this.data,
    required this.pulse,
    required this.isActive,
  });

  final _OnboardPage data;
  final Animation<double> pulse;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed photo
        Image.asset(
          data.image,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: const Color(0xFF0F1A15),
            child: Icon(Icons.image_rounded, size: 64, color: data.accent),
          ),
        ),
        // Cinematic overlays
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.25),
                Colors.black.withValues(alpha: 0.88),
              ],
              stops: const [0, 0.28, 0.55, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                data.accent.withValues(alpha: 0.18),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.2),
              ],
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 72, 28, 160),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedBuilder(
                  animation: pulse,
                  builder: (context, child) {
                    final t = isActive ? pulse.value : 0.5;
                    return Transform.translate(
                      offset: Offset(0, (1 - t) * 4),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: data.accent.withValues(alpha: 0.92),
                      borderRadius: AppRadius.pill,
                      boxShadow: [
                        BoxShadow(
                          color: data.accent.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      data.badge,
                      style: AppTextStyles.caption.copyWith(
                        color: const Color(0xFF0F1A15),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  key: ValueKey(data.title),
                  tween: Tween(begin: 0.92, end: 1),
                  duration: AppDurations.slow,
                  curve: Curves.easeOutCubic,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, alignment: Alignment.bottomLeft, child: child),
                  child: Text(
                    data.title,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.55),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  data.subtitle,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
