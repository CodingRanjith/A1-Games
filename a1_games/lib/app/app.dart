import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_config.dart';
import '../core/services/app_settings_controller.dart';
import '../data/local/local_storage_service.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/shell/main_shell.dart';
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
      home: const _RootNavigator(),
    );
  }
}

class _RootNavigator extends StatefulWidget {
  const _RootNavigator();

  @override
  State<_RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<_RootNavigator> {
  bool _showSplash = true;
  bool? _needsOnboarding;

  @override
  void initState() {
    super.initState();
    final storage = context.read<LocalStorageService>();
    _needsOnboarding = !storage.isOnboardingDone();
  }

  void _onSplashDone() {
    setState(() => _showSplash = false);
  }

  void _onOnboardingDone() {
    context.read<LocalStorageService>().setOnboardingDone(true);
    setState(() => _needsOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(onDone: _onSplashDone);
    }
    if (_needsOnboarding == true) {
      return OnboardingScreen(onDone: _onOnboardingDone);
    }
    return const MainShell();
  }
}
