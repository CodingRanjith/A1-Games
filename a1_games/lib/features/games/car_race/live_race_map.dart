import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'car_race_controller.dart';
import 'chennai_route.dart';

/// Free live tiles: OpenStreetMap streets + Esri World Imagery satellite.
/// Needs internet. No Google/Mapbox API key. No backend.
class LiveRaceMap extends StatefulWidget {
  const LiveRaceMap({
    super.key,
    this.controller,
    this.map,
    required this.satellite,
    required this.fromIndex,
    required this.toIndex,
    this.follow = true,
    this.interactive = false,
  });

  final CarRaceController? controller;
  final RaceMap? map;
  final bool satellite;
  final int fromIndex;
  final int toIndex;
  final bool follow;
  final bool interactive;

  @override
  State<LiveRaceMap> createState() => _LiveRaceMapState();
}

class _LiveRaceMapState extends State<LiveRaceMap> {
  final MapController _map = MapController();
  DateTime _lastMove = DateTime.fromMillisecondsSinceEpoch(0);

  static const _osm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _esri =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncCamera(force: true));
  }

  @override
  void didUpdateWidget(covariant LiveRaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onTick);
      widget.controller?.addListener(_onTick);
    }
    if (oldWidget.satellite != widget.satellite ||
        oldWidget.map?.id != widget.map?.id ||
        oldWidget.fromIndex != widget.fromIndex ||
        oldWidget.toIndex != widget.toIndex) {
      _syncCamera(force: true);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (!widget.follow) return;
    final now = DateTime.now();
    if (now.difference(_lastMove).inMilliseconds < 80) return;
    _lastMove = now;
    _syncCamera();
  }

  RaceMap get _route => widget.map ?? widget.controller?.route ?? RaceMaps.chennai;

  LatLng get _center {
    final c = widget.controller;
    if (c != null && (c.isRunning || c.worldX != 0 || c.worldY != 0)) {
      final g = c.carGeo;
      return LatLng(g.lat, g.lng);
    }
    final g = _route.waypoints[widget.fromIndex.clamp(0, _route.waypoints.length - 1)].geo;
    return LatLng(g.lat, g.lng);
  }

  double get carAlong => widget.controller?.alongMeters ?? _route.raceAlongForWaypoint(widget.fromIndex);

  double get _rotationDeg {
    final c = widget.controller;
    if (!widget.follow || c == null) return 0;
    return c.displayHeading * 180 / math.pi;
  }

  void _syncCamera({bool force = false}) {
    try {
      _map.moveAndRotate(_center, widget.follow ? 17.2 : 12.4, _rotationDeg);
    } catch (_) {
      if (force) {
        // Map not ready yet.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final from = _route.waypoints[widget.fromIndex.clamp(0, _route.waypoints.length - 1)];
    final to = _route.waypoints[widget.toIndex.clamp(0, _route.waypoints.length - 1)];
    final split = _route.splitRoute(
      widget.fromIndex,
      widget.toIndex,
      carAlong,
    );
    final done = split.done.map((g) => LatLng(g.lat, g.lng)).toList();
    final left = split.left.map((g) => LatLng(g.lat, g.lng)).toList();
    final car = widget.controller;

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: widget.follow ? 17.2 : 12.4,
        initialRotation: _rotationDeg,
        backgroundColor: const Color(0xFFE8EEF2),
        interactionOptions: InteractionOptions(
          flags: widget.interactive
              ? InteractiveFlag.pinchZoom | InteractiveFlag.drag
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: widget.satellite ? _esri : _osm,
          userAgentPackageName: 'com.techackode.a1_games',
          maxNativeZoom: 19,
          retinaMode: false,
        ),
        if (done.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(points: done, color: const Color(0xFF9AA0A6), strokeWidth: 6),
            ],
          ),
        if (left.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(points: left, color: const Color(0xFF174EA6), strokeWidth: 9),
              Polyline(points: left, color: const Color(0xFF1A73E8), strokeWidth: 5),
            ],
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: LatLng(from.geo.lat, from.geo.lng),
              width: 40,
              height: 40,
              child: const _MapPin(color: Color(0xFF34A853), letter: 'A'),
            ),
            Marker(
              point: LatLng(to.geo.lat, to.geo.lng),
              width: 40,
              height: 40,
              child: const _MapPin(color: Color(0xFFEA4335), letter: 'B'),
            ),
            if (car != null)
              Marker(
                point: LatLng(car.carGeo.lat, car.carGeo.lng),
                width: 36,
                height: 36,
                child: Transform.rotate(
                  angle: widget.follow ? 0 : car.displayHeading,
                  child: const _NavChevron(),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({required this.color, required this.letter});

  final Color color;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Text(
            letter,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
        Container(width: 3, height: 10, color: color),
      ],
    );
  }
}

class _NavChevron extends StatelessWidget {
  const _NavChevron();

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.navigation_rounded, color: Color(0xFF1A73E8), size: 28);
  }
}
