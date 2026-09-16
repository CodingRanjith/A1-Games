import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_config.dart';
import '../core/services/app_settings_controller.dart';
import '../features/games/car_race/car_race_screen.dart';
import '../features/intro/intro_screen.dart';
import '../features/setup/car_choose_screen.dart';
import '../features/setup/character_select_screen.dart';
import '../features/setup/route_choose_screen.dart';
import '../features/splash/splash_screen.dart';
import 'theme/app_theme.dart';

class GameRushApp extends StatelessWidget {
  const GameRushApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();

    return MaterialApp(
      title: AppConfig.appFullName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      home: const _RaceFlow(),
    );
  }
}

enum _RaceStep { splash, intro, character, car, route, race }

/// Splash → intro GIF → driver → car → route → race. Other pages are not shown.
class _RaceFlow extends StatefulWidget {
  const _RaceFlow();

  @override
  State<_RaceFlow> createState() => _RaceFlowState();
}

class _RaceFlowState extends State<_RaceFlow> {
  _RaceStep _step = _RaceStep.splash;

  void _go(_RaceStep step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    switch (_step) {
      case _RaceStep.splash:
        return SplashScreen(onDone: () => _go(_RaceStep.intro));
      case _RaceStep.intro:
        return IntroScreen(onDone: () => _go(_RaceStep.character));
      case _RaceStep.character:
        return CharacterSelectScreen(
          onBack: () => _go(_RaceStep.intro),
          onNext: () => _go(_RaceStep.car),
        );
      case _RaceStep.car:
        return CarChooseScreen(
          onBack: () => _go(_RaceStep.character),
          onNext: () => _go(_RaceStep.route),
        );
      case _RaceStep.route:
        return RouteChooseScreen(
          onBack: () => _go(_RaceStep.car),
          onStart: () => _go(_RaceStep.race),
        );
      case _RaceStep.race:
        return CarRaceScreen(onExit: () => _go(_RaceStep.route));
    }
  }
}
