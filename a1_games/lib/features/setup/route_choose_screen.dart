import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../../core/services/haptic_service.dart';
import '../games/car_race/car_garage_service.dart';
import '../games/car_race/chennai_route.dart';
import '../games/car_race/live_race_map.dart';

class RouteChooseScreen extends StatelessWidget {
  const RouteChooseScreen({super.key, required this.onStart, required this.onBack});

  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final garage = context.watch<CarGarageService>();
    final route = garage.route;
    final km = route.tripKm(garage.fromIndex, garage.toIndex);
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;

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
                    child: Text('Choose location', style: AppTextStyles.headline.copyWith(color: Colors.white)),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: RaceMaps.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final city = RaceMaps.all[i];
                  final on = garage.cityId == city.id;
                  return ChoiceChip(
                    label: Text(city.name),
                    selected: on,
                    onSelected: (_) => garage.setCity(city.id),
                    selectedColor: AppColors.gameCarRace,
                    labelStyle: TextStyle(color: on ? Colors.white : Colors.white70, fontSize: 12),
                    backgroundColor: Colors.white10,
                    side: const BorderSide(color: Colors.white24),
                  );
                },
              ),
            ),
            const _PlaceSearch(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: ClipRRect(
                  borderRadius: AppRadius.large,
                  child: LiveRaceMap(
                    key: ValueKey(route.id + route.name),
                    map: route,
                    satellite: garage.satelliteView,
                    fromIndex: garage.fromIndex,
                    toIndex: garage.toIndex,
                    follow: false,
                    interactive: true,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                route.country.isEmpty ? route.name : '${route.name}, ${route.country}',
                style: AppTextStyles.caption.copyWith(color: Colors.white54),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: landscape
                  ? Row(
                      children: [
                        Expanded(child: _from(garage, route)),
                        const SizedBox(width: 12),
                        Expanded(child: _to(garage, route)),
                      ],
                    )
                  : Column(
                      children: [
                        _from(garage, route),
                        const SizedBox(height: 8),
                        _to(garage, route),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${km.toStringAsFixed(1)} km  ·  ${route.etaLabel(km)}',
                      style: AppTextStyles.caption.copyWith(color: Colors.white),
                    ),
                  ),
                  Text('Satellite', style: AppTextStyles.caption.copyWith(color: Colors.white70)),
                  Switch(value: garage.satelliteView, onChanged: garage.setSatellite),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.gameCarRace,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
                  ),
                  child: Text('START RACE', style: AppTextStyles.button.copyWith(color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _from(CarGarageService garage, RaceMap route) {
    return _PlaceDropdown(
      label: 'From',
      places: route.waypoints,
      index: garage.fromIndex,
      maxIndex: route.waypoints.length - 2,
      onChanged: (i) => garage.setRoute(from: i),
    );
  }

  Widget _to(CarGarageService garage, RaceMap route) {
    return _PlaceDropdown(
      label: 'To',
      places: route.waypoints,
      index: garage.toIndex,
      minIndex: garage.fromIndex + 1,
      onChanged: (i) => garage.setRoute(to: i),
    );
  }
}

class _PlaceSearch extends StatefulWidget {
  const _PlaceSearch();

  @override
  State<_PlaceSearch> createState() => _PlaceSearchState();
}

class _PlaceSearchState extends State<_PlaceSearch> {
  final _text = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _text.text.trim();
    if (q.length < 2 || _busy) return;
    setState(() => _busy = true);
    final garage = context.read<CarGarageService>();
    final haptic = context.read<HapticService>();
    final ok = await garage.searchLocation(q);
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Place not found. Check the name and internet, then try again.')),
      );
      return;
    }
    await haptic.selection();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Search any place',
                hintStyle: const TextStyle(color: Colors.white38),
                isDense: true,
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(borderRadius: AppRadius.medium, borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _busy ? null : _search,
            icon: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.search_rounded, color: Colors.white),
          ),
        ],
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
    final items = <DropdownMenuItem<int>>[];
    for (var i = minIndex; i <= last; i++) {
      items.add(
        DropdownMenuItem(
          value: i,
          child: Text(places[i].place),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption.copyWith(color: Colors.white54)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: AppRadius.medium,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: index.clamp(minIndex, last),
              dropdownColor: const Color(0xFF1C2430),
              style: AppTextStyles.body.copyWith(color: Colors.white),
              items: items,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
