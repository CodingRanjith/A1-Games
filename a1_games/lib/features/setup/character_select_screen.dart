import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../games/car_race/car_garage_service.dart';
import 'character_preview.dart';
import 'driver_catalog.dart';

class CharacterSelectScreen extends StatelessWidget {
  const CharacterSelectScreen({super.key, required this.onNext, this.onBack});

  final VoidCallback onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<CarGarageService>();
    final index = DriverCatalog.indexOf(garage.driverId);
    final driver = DriverCatalog.all[index];

    Future<void> shift(int delta) async {
      final next = (index + delta) % DriverCatalog.all.length;
      final id = DriverCatalog.all[next < 0 ? next + DriverCatalog.all.length : next].id;
      final haptic = context.read<HapticService>();
      final sound = context.read<SoundService>();
      await haptic.selection();
      await sound.playTap();
      await garage.selectDriver(id);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF10141C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    ),
                  Expanded(
                    child: Text(
                      'Choose driver',
                      style: AppTextStyles.headline.copyWith(color: Colors.white),
                    ),
                  ),
                  Text(
                    '${index + 1}/${DriverCatalog.all.length}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Drag the model left or right to see every side. Swipe to change driver.',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v < -280) {
                    shift(1);
                  } else if (v > 280) {
                    shift(-1);
                  }
                },
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => shift(-1),
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 40),
                    ),
                    Expanded(child: CharacterPreview3d(key: ValueKey(driver.id), driver: driver)),
                    IconButton(
                      onPressed: () => shift(1),
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
            ),
            Text(driver.name, style: AppTextStyles.headline.copyWith(color: Colors.white)),
            Text(driver.role, style: AppTextStyles.caption.copyWith(color: driver.accent)),
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: DriverCatalog.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final item = DriverCatalog.all[i];
                  final on = item.id == driver.id;
                  return GestureDetector(
                    onTap: () => garage.selectDriver(item.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 64,
                      decoration: BoxDecoration(
                        color: item.suit,
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: on ? Colors.white : Colors.white24,
                          width: on ? 2.5 : 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        item.name,
                        style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gameCarRace,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                  child: Text('SELECT DRIVER', style: AppTextStyles.button.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
