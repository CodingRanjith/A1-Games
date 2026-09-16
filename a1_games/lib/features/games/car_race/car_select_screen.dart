import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:a1_games/app/theme/app_colors.dart';
import 'package:a1_games/app/theme/app_spacing.dart';
import 'package:a1_games/app/theme/app_text_styles.dart';
import 'package:a1_games/core/services/haptic_service.dart';
import 'package:a1_games/core/services/sound_service.dart';

import 'car_catalog.dart';
import 'car_garage_service.dart';
import 'chennai_route.dart';
import 'live_race_map.dart';
import 'render/car_preview_3d.dart';
import 'vehicle/car_config.dart';
import 'vehicle/vehicle_plate.dart';

class CarGaragePanel extends StatelessWidget {
  const CarGaragePanel({
    super.key,
    required this.onRace,
    required this.onBack,
  });

  final VoidCallback onRace;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<CarGarageService>();
    final selected = garage.focusedCar;
    final upgrades = garage.upgradesFor(selected.id);
    final unlocked = garage.isUnlocked(selected.id);

    return ColoredBox(
      color: const Color(0xE6080A12),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Garage', style: AppTextStyles.headline.copyWith(color: Colors.white)),
                        Text(
                          '${garage.route.name} · ${garage.route.startName} → ${garage.route.endName}',
                          style: AppTextStyles.caption.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: AppRadius.pill,
                    ),
                    child: Text(
                      '🪙 ${garage.coins}',
                      style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius: AppRadius.medium,
                child: LiveRaceMap(
                  map: garage.route,
                  satellite: garage.satelliteView,
                  fromIndex: garage.fromIndex,
                  toIndex: garage.toIndex,
                  follow: false,
                  interactive: true,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _PlaceDropdown(
                      label: 'From',
                      places: garage.route.waypoints,
                      index: garage.fromIndex,
                      maxIndex: garage.route.waypoints.length - 2,
                      onChanged: (i) => garage.setRoute(from: i),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward_rounded, color: Colors.white70),
                  ),
                  Expanded(
                    child: _PlaceDropdown(
                      label: 'To',
                      places: garage.route.waypoints,
                      index: garage.toIndex,
                      minIndex: garage.fromIndex + 1,
                      onChanged: (i) => garage.setRoute(to: i),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${garage.route.tripKm(garage.fromIndex, garage.toIndex).toStringAsFixed(1)} km  ·  ETA ${garage.route.etaLabel(garage.route.tripKm(garage.fromIndex, garage.toIndex))}',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                  Text('Satellite', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  Switch(
                    value: garage.satelliteView,
                    onChanged: garage.setSatellite,
                  ),
                ],
              ),
            ),
            Expanded(
              child: selected.id == 'cycle' || selected.id == 'bike'
                  ? VehiclePlate(id: selected.id, color: selected.color)
                  : CarConfigs.byId(selected.id).id == selected.id
                      ? CarPreview3d(config: CarConfigs.byId(selected.id))
                      : Image.asset(
                          selected.asset,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => VehiclePlate(id: selected.id, color: selected.color),
                        ),
            ),
            Text(selected.name, style: AppTextStyles.headline.copyWith(color: Colors.white)),
            Text(
              selected.tagline,
              style: AppTextStyles.caption.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _StatBar(label: 'Speed', value: selected.cruiseCap / 8.2 + upgrades.engine * 0.06),
            _StatBar(label: 'Handling', value: selected.handling / 1.25),
            _StatBar(label: 'Nitro', value: selected.nitroBoost / 1.85 + upgrades.nitro * 0.06),
            const SizedBox(height: 12),
            SizedBox(
              height: 108,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: CarCatalog.playerCars.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final car = CarCatalog.playerCars[i];
                  final on = car.id == selected.id;
                  final owned = garage.isUnlocked(car.id);
                  return GestureDetector(
                    onTap: () async {
                      final haptic = context.read<HapticService>();
                      final sound = context.read<SoundService>();
                      await haptic.selection();
                      await sound.playTap();
                      await garage.focusCar(car.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 86,
                      decoration: BoxDecoration(
                        borderRadius: AppRadius.medium,
                        border: Border.all(
                          color: on ? AppColors.gameCarRace : Colors.white24,
                          width: on ? 2 : 1,
                        ),
                        color: Colors.white10,
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: car.id == 'cycle' || car.id == 'bike'
                                  ? VehiclePlate(id: car.id, color: car.color)
                                  : Image.asset(
                                      car.asset,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, _, _) => VehiclePlate(id: car.id, color: car.color),
                                    ),
                            ),
                          ),
                          Text(
                            owned ? car.name : '${car.cost}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: owned ? Colors.white : Colors.amber,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _UpgradeChip(
                          label: 'Engine ${upgrades.engine}/${CarUpgrades.maxLevel}',
                          cost: garage.engineCost(selected.id),
                          enabled: unlocked && upgrades.engine < CarUpgrades.maxLevel,
                          onTap: () async {
                            final haptic = context.read<HapticService>();
                            final ok = await garage.upgradeEngine(selected.id);
                            if (ok) {
                              await haptic.medium();
                            } else {
                              await haptic.light();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _UpgradeChip(
                          label: 'Nitro ${upgrades.nitro}/${CarUpgrades.maxLevel}',
                          cost: garage.nitroCost(selected.id),
                          enabled: unlocked && upgrades.nitro < CarUpgrades.maxLevel,
                          onTap: () async {
                            final haptic = context.read<HapticService>();
                            final ok = await garage.upgradeNitro(selected.id);
                            if (ok) {
                              await haptic.medium();
                            } else {
                              await haptic.light();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gameCarRace,
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                      ),
                      onPressed: () async {
                        final haptic = context.read<HapticService>();
                        final sound = context.read<SoundService>();
                        final messenger = ScaffoldMessenger.of(context);
                        await haptic.selection();
                        await sound.playTap();
                        if (!unlocked) {
                          final ok = await garage.unlockCar(selected.id);
                          if (!ok) {
                            messenger.showSnackBar(
                              SnackBar(content: Text('Need ${selected.cost} coins to unlock ${selected.name}')),
                            );
                          }
                          return;
                        }
                        onRace();
                      },
                      child: Text(
                        unlocked ? 'RACE' : 'UNLOCK  ${selected.cost}',
                        style: AppTextStyles.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white70)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: AppRadius.pill,
              child: LinearProgressIndicator(
                minHeight: 8,
                value: value.clamp(0.15, 1),
                backgroundColor: Colors.white12,
                color: AppColors.gameCarRace,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradeChip extends StatelessWidget {
  const _UpgradeChip({
    required this.label,
    required this.cost,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final int cost;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white10,
      borderRadius: AppRadius.medium,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.medium,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            children: [
              Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white)),
              Text(
                enabled ? 'Upgrade  $cost' : 'MAX',
                style: AppTextStyles.caption.copyWith(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceDropdown extends StatelessWidget {
  const _PlaceDropdown({
    required this.label,
    required this.places,
    required this.index,
    required this.onChanged,
    this.minIndex = 0,
    this.maxIndex,
  });

  final String label;
  final List<RouteWaypoint> places;
  final int index;
  final int minIndex;
  final int? maxIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final last = maxIndex ?? places.length - 1;
    final items = [
      for (var i = minIndex; i <= last; i++)
        DropdownMenuItem(
          value: i,
          child: Text(places[i].place, overflow: TextOverflow.ellipsis),
        ),
    ];
    final value = index.clamp(minIndex, last);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white54)),
        DropdownButton<int>(
          isExpanded: true,
          value: value,
          dropdownColor: const Color(0xFF1A1E28),
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          items: items,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

