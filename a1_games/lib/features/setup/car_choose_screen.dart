import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/services/haptic_service.dart';
import '../../core/services/sound_service.dart';
import '../games/car_race/car_catalog.dart';
import '../games/car_race/car_garage_service.dart';
import '../games/car_race/render/car_preview_3d.dart';
import '../games/car_race/vehicle/vehicle_plate.dart';
import '../games/car_race/vehicle/car_config.dart';

class CarChooseScreen extends StatelessWidget {
  const CarChooseScreen({super.key, required this.onNext, required this.onBack});

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<CarGarageService>();
    final cars = CarCatalog.playerCars;
    final index = cars.indexWhere((c) => c.id == garage.focusedCarId);
    final selected = cars[index < 0 ? 0 : index];

    Future<void> shift(int delta) async {
      final next = (index + delta) % cars.length;
      final i = next < 0 ? next + cars.length : next;
      final haptic = context.read<HapticService>();
      final sound = context.read<SoundService>();
      await haptic.selection();
      await sound.playTap();
      await garage.focusCar(cars[i].id);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF10141C),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Text('Choose vehicle', style: AppTextStyles.headline.copyWith(color: Colors.white)),
                  ),
                  Text('🪙 ${garage.coins}', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                ],
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
                    Expanded(child: _vehicleView(selected)),
                    IconButton(
                      onPressed: () => shift(1),
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 40),
                    ),
                  ],
                ),
              ),
            ),
            Text(selected.name, style: AppTextStyles.headline.copyWith(color: Colors.white)),
            Text(selected.tagline, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
            const SizedBox(height: 10),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: cars.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final car = cars[i];
                  final on = car.id == selected.id;
                  return GestureDetector(
                    onTap: () => garage.focusCar(car.id),
                    child: Container(
                      width: 92,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: AppRadius.medium,
                        border: Border.all(color: on ? AppColors.gameCarRace : Colors.white24, width: on ? 2 : 1),
                      ),
                      child: Column(
                        children: [
                          Expanded(child: _thumb(car.id, car.asset, car.color)),
                          Text(
                            car.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gameCarRace,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                  child: Text(
                    'DRIVE',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _vehicleView(RaceCarSpec selected) {
    if (selected.id == 'cycle' || selected.id == 'bike') {
      return VehiclePlate(id: selected.id, color: selected.color);
    }
    if (CarConfigs.byId(selected.id).id == selected.id) {
      return CarPreview3d(config: CarConfigs.byId(selected.id));
    }
    return _thumb(selected.id, selected.asset, selected.color);
  }

  Widget _thumb(String id, String asset, Color color) {
    if (id == 'cycle' || id == 'bike') {
      return VehiclePlate(id: id, color: color);
    }
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => VehiclePlate(id: id, color: color),
    );
  }
}
