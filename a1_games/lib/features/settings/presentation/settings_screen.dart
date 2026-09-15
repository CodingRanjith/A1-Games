import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/services/app_settings_controller.dart';
import '../../../core/services/haptic_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text('Settings', style: AppTextStyles.displayMedium),
          const SizedBox(height: 20),
          _SectionCard(
            children: [
              SwitchListTile(
                title: Text('Sound', style: AppTextStyles.titleSmall),
                subtitle: Text(
                  'Game sound effects',
                  style: AppTextStyles.bodySmall,
                ),
                value: settings.soundEnabled,
                onChanged: (v) async {
                  final haptic = context.read<HapticService>();
                  await settings.setSoundEnabled(v);
                  haptic.selection();
                },
                secondary: const Icon(Icons.volume_up_rounded),
              ),
              SwitchListTile(
                title: Text('Vibration', style: AppTextStyles.titleSmall),
                subtitle: Text(
                  'Haptic feedback',
                  style: AppTextStyles.bodySmall,
                ),
                value: settings.vibrationEnabled,
                onChanged: (v) async {
                  final haptic = context.read<HapticService>();
                  await settings.setVibrationEnabled(v);
                  if (v) haptic.medium();
                },
                secondary: const Icon(Icons.vibration_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text('Theme', style: AppTextStyles.titleSmall),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('System'), icon: Icon(Icons.phone_android)),
                    ButtonSegment(value: 1, label: Text('Light'), icon: Icon(Icons.light_mode)),
                    ButtonSegment(value: 2, label: Text('Dark'), icon: Icon(Icons.dark_mode)),
                  ],
                  selected: {settings.themeModeIndex},
                  onSelectionChanged: (s) =>
                      settings.setThemeModeIndex(s.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text('Reset Progress', style: AppTextStyles.titleSmall),
                subtitle: Text(
                  'Clear scores and statistics',
                  style: AppTextStyles.bodySmall,
                ),
                onTap: () => _confirmReset(context, settings),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: Text('About', style: AppTextStyles.titleSmall),
                onTap: () => _showAbout(context),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text('Privacy Policy', style: AppTextStyles.titleSmall),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _PrivacyScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: Text('Terms of Use', style: AppTextStyles.titleSmall),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const _TermsScreen()),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.tag_rounded),
                title: Text('App Version', style: AppTextStyles.titleSmall),
                trailing: Text(
                  AppConfig.version,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Made by ${AppConfig.developerName}',
              style: AppTextStyles.caption.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(
    BuildContext context,
    AppSettingsController settings,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will erase all best scores, play counts, and streaks. Settings like sound and theme will be kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await settings.resetProgress();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress reset')),
        );
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appFullName,
      applicationVersion: AppConfig.version,
      applicationLegalese: '© ${DateTime.now().year} ${AppConfig.developerName}',
      children: [
        const SizedBox(height: 12),
        Text(AppConfig.tagline, style: AppTextStyles.body),
        const SizedBox(height: 8),
        Text(
          'Offline casual mini-games. No account required.',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      borderRadius: AppRadius.large,
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Privacy Policy', style: AppTextStyles.headline),
          const SizedBox(height: 12),
          Text(
            'GameRush 10 is an offline-first casual games app.\n\n'
            '• No account is required.\n'
            '• No personal information is collected by the core application.\n'
            '• Gameplay data (scores, settings, statistics) is stored only on your device.\n'
            '• No backend or cloud database is required for gameplay.\n'
            '• The app works fully in airplane mode.\n\n'
            'If advertising or analytics are added in a future version, this policy will be updated accordingly. '
            'This version does not include ads or analytics SDKs.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}

class _TermsScreen extends StatelessWidget {
  const _TermsScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Use')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Terms of Use', style: AppTextStyles.headline),
          const SizedBox(height: 12),
          Text(
            'By using ${AppConfig.appFullName}, you agree to use the app for personal entertainment. '
            'The software is provided as-is without warranties. '
            'Scores and progress are stored locally and may be lost if you uninstall the app or clear data.\n\n'
            'Please play responsibly and take breaks.',
            style: AppTextStyles.body,
          ),
        ],
      ),
    );
  }
}
