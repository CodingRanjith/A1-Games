import 'package:flutter/material.dart';

import 'character_assets.dart';

/// Soft cinematic character backdrop (Unreal-export style PNGs).
/// Fades to transparent so gameplay UI stays readable.
class CharacterBackdrop extends StatelessWidget {
  const CharacterBackdrop({
    super.key,
    required this.assetPath,
    this.alignment = Alignment.bottomRight,
    this.opacity = 0.42,
    this.widthFactor = 0.62,
    this.fadeLeft = true,
    this.child,
  });

  final String assetPath;
  final Alignment alignment;
  final double opacity;
  final double widthFactor;
  final bool fadeLeft;
  final Widget? child;

  factory CharacterBackdrop.forGame({
    Key? key,
    required String gameId,
    Widget? child,
    double opacity = 0.38,
  }) {
    return CharacterBackdrop(
      key: key,
      assetPath: CharacterAssets.forGameId(gameId) ?? CharacterAssets.hero,
      opacity: opacity,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: alignment,
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            heightFactor: 0.95,
            child: Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: fadeLeft ? Alignment.centerLeft : Alignment.topCenter,
                    end: fadeLeft ? Alignment.centerRight : Alignment.bottomCenter,
                    colors: fadeLeft
                        ? const [
                            Colors.transparent,
                            Colors.black54,
                            Colors.black,
                            Colors.black,
                          ]
                        : const [
                            Colors.transparent,
                            Colors.black87,
                            Colors.black,
                          ],
                    stops: fadeLeft
                        ? const [0.0, 0.25, 0.55, 1.0]
                        : const [0.0, 0.35, 1.0],
                  ).createShader(bounds);
                },
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
        ?child,
      ],
    );
  }
}

/// Full-bleed dimmed character plate behind home / splash.
class CharacterHeroPlate extends StatelessWidget {
  const CharacterHeroPlate({
    super.key,
    this.assetPath = CharacterAssets.hero,
    required this.child,
  });

  final String assetPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? const [Color(0xFF0F1A15), Color(0xFF1A2A22)]
                    : const [Color(0xFFEFF6F2), Color(0xFFF7F9F8)],
              ),
            ),
          ),
        ),
        Positioned(
          right: -20,
          top: 40,
          bottom: 80,
          width: MediaQuery.sizeOf(context).width * 0.55,
          child: Opacity(
            opacity: isDark ? 0.35 : 0.28,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              alignment: Alignment.centerRight,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
