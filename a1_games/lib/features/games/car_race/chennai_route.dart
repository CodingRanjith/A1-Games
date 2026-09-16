import 'dart:math' as math;

enum SideKind { city, sand, green }

enum NavTurn { depart, left, right, slightLeft, slightRight, straight, arrive }

class SidePair {
  const SidePair(this.left, this.right);

  final SideKind left;
  final SideKind right;
}

class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;
}

class RouteWaypoint {
  const RouteWaypoint({
    required this.geo,
    required this.place,
    required this.road,
  });

  final GeoPoint geo;
  final String place;
  final String road;
}

class RouteSample {
  const RouteSample({
    required this.x,
    required this.y,
    required this.alongMeters,
    required this.heading,
    required this.segmentIndex,
  });

  final double x;
  final double y;
  final double alongMeters;
  final double heading;
  final int segmentIndex;
}

class NavHint {
  const NavHint({
    required this.turn,
    required this.road,
    required this.place,
    required this.metersAhead,
  });

  final NavTurn turn;
  final String road;
  final String place;
  final double metersAhead;

  String get title {
    switch (turn) {
      case NavTurn.depart:
        return 'Head south';
      case NavTurn.left:
        return 'Turn left';
      case NavTurn.right:
        return 'Turn right';
      case NavTurn.slightLeft:
        return 'Keep left';
      case NavTurn.slightRight:
        return 'Keep right';
      case NavTurn.straight:
        return 'Continue straight';
      case NavTurn.arrive:
        return 'Arrive at destination';
    }
  }

  String get subtitle => 'onto $road';
}

/// One driveable map. Chennai is the default; any other city or searched place uses this too.
class RaceMap {
  RaceMap({
    required this.id,
    required this.name,
    required this.waypoints,
    required this.raceKm,
    this.country = '',
    this.sides = const {},
  });

  final String id;
  final String name;
  final String country;
  final List<RouteWaypoint> waypoints;
  final double raceKm;
  final Map<String, SidePair> sides;

  String get startName => waypoints.first.place;
  String get endName => waypoints.last.place;
  double get raceMeters => raceKm * 1000;
  GeoPoint get origin => waypoints.first.geo;

  List<RouteSample>? _samples;
  List<double>? _waypointAlong;
  List<NavTurn>? _waypointTurns;
}

const List<RouteWaypoint> chennaiWaypoints = [
    RouteWaypoint(
      geo: GeoPoint(13.1296, 80.2319),
      place: 'Moolakadai',
      road: 'GNT Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.1122, 80.2288),
      place: 'Peravallur',
      road: 'Paper Mills Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0984, 80.2322),
      place: 'Ayanavaram',
      road: 'Konnur High Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0841, 80.2404),
      place: 'Kilpauk',
      road: 'New Avadi Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0728, 80.2426),
      place: 'Chetpet',
      road: 'McNichols Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0606, 80.2478),
      place: 'Nungambakkam',
      road: 'Sterling Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0562, 80.2496),
      place: 'Thousand Lights',
      road: 'Anna Salai',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0436, 80.2468),
      place: 'Teynampet',
      road: 'Anna Salai',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0218, 80.2272),
      place: 'Saidapet',
      road: 'Anna Salai',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0069, 80.2206),
      place: 'Guindy',
      road: 'Inner Ring Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0052, 80.2384),
      place: 'Little Mount',
      road: 'Sardar Patel Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(13.0064, 80.2572),
      place: 'Adyar',
      road: 'LB Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(12.9960, 80.2549),
      place: 'Indira Nagar',
      road: 'LB Road',
    ),
    RouteWaypoint(
      geo: GeoPoint(12.9870, 80.2594),
      place: 'Thiruvanmiyur',
      road: 'Lattice Bridge Road',
    ),
  ];

extension RaceMapOps on RaceMap {
  List<RouteSample> get samples => _samples ??= _buildSamples();

  double get geometricMeters => _waypointAlong!.last;

  ({double x, double y}) toMeters(GeoPoint g) {
    const latM = 110948.0;
    final lngM = 110948.0 * math.cos(origin.lat * math.pi / 180);
    return (
      x: (g.lng - origin.lng) * lngM,
      y: (g.lat - origin.lat) * latM,
    );
  }

  GeoPoint geoFromMeters(double x, double y) {
    const latM = 110948.0;
    final lngM = 110948.0 * math.cos(origin.lat * math.pi / 180);
    return GeoPoint(origin.lat + y / latM, origin.lng + x / lngM);
  }

  double raceAlongForWaypoint(int index) {
    _ensure();
    final i = index.clamp(0, waypoints.length - 1);
    return (_waypointAlong![i] / geometricMeters) * raceMeters;
  }

  double tripKm(int fromIndex, int toIndex) {
    final a = raceAlongForWaypoint(fromIndex);
    final b = raceAlongForWaypoint(toIndex);
    return ((b - a).abs()) / 1000;
  }

  String etaLabel(double km, {double kmh = 42}) {
    final minutes = (km / kmh * 60).clamp(1, 999).round();
    if (minutes >= 60) {
      return '${minutes ~/ 60}h ${minutes % 60}m';
    }
    return '$minutes min';
  }

  List<GeoPoint> geosBetween(int fromIndex, int toIndex) {
    final start = raceAlongForWaypoint(fromIndex);
    final end = raceAlongForWaypoint(toIndex);
    final lo = math.min(start, end);
    final hi = math.max(start, end);
    return samples
        .where((s) {
          final race = (s.alongMeters / geometricMeters) * raceMeters;
          return race >= lo - 20 && race <= hi + 20;
        })
        .map((s) => geoFromMeters(s.x, s.y))
        .toList();
  }

  RouteSample sampleAt(double alongMeters) {
    final pts = samples;
    final t = (alongMeters.clamp(0, raceMeters) / raceMeters) * geometricMeters;
    var lo = 0;
    var hi = pts.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (pts[mid].alongMeters < t) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    final i = lo.clamp(1, pts.length - 1);
    final a = pts[i - 1];
    final b = pts[i];
    final span = (b.alongMeters - a.alongMeters).clamp(0.0001, 1e9);
    final u = ((t - a.alongMeters) / span).clamp(0.0, 1.0);
    return RouteSample(
      x: a.x + (b.x - a.x) * u,
      y: a.y + (b.y - a.y) * u,
      alongMeters: t,
      heading: _lerpHeading(a.heading, b.heading, u),
      segmentIndex: a.segmentIndex,
    );
  }

  NavHint hintAt(double raceAlongMeters, {double? untilAlong}) {
    _ensure();
    final endCap = untilAlong ?? raceMeters;
    if (raceAlongMeters >= endCap - 35) {
      final dest = waypoints.lastWhere(
        (w) => raceAlongForWaypoint(waypoints.indexOf(w)) <= endCap + 1,
        orElse: () => waypoints.last,
      );
      return NavHint(
        turn: NavTurn.arrive,
        road: dest.road,
        place: dest.place,
        metersAhead: 0,
      );
    }
    final geoAlong = (raceAlongMeters / raceMeters) * geometricMeters;
    final turns = _waypointTurns!;
    final along = _waypointAlong!;
    for (var i = 1; i < waypoints.length; i++) {
      final raceAt = (along[i] / geometricMeters) * raceMeters;
      if (raceAt > endCap + 30) break;
      if (geoAlong <= along[i] + 8) {
        final meters = ((along[i] - geoAlong) / geometricMeters) * raceMeters;
        return NavHint(
          turn: i == waypoints.length - 1 || raceAt >= endCap - 40
              ? NavTurn.arrive
              : turns[i],
          road: waypoints[i].road,
          place: waypoints[i].place,
          metersAhead: meters.clamp(0, raceMeters),
        );
      }
    }
    return NavHint(
      turn: NavTurn.arrive,
      road: waypoints.last.road,
      place: waypoints.last.place,
      metersAhead: 0,
    );
  }

  SidePair sidesForPlace(String place) =>
      sides[place] ?? const SidePair(SideKind.city, SideKind.city);

  String placeAt(double raceAlongMeters) {
    _ensure();
    final geoAlong = (raceAlongMeters / raceMeters) * geometricMeters;
    final along = _waypointAlong!;
    var best = waypoints.first.place;
    for (var i = 0; i < waypoints.length; i++) {
      if (along[i] <= geoAlong + 40) best = waypoints[i].place;
    }
    return best;
  }

  String roadAt(double raceAlongMeters) {
    _ensure();
    final geoAlong = (raceAlongMeters / raceMeters) * geometricMeters;
    final along = _waypointAlong!;
    var best = waypoints.first.road;
    for (var i = 0; i < waypoints.length; i++) {
      if (along[i] <= geoAlong + 8) best = waypoints[i].road;
    }
    return best;
  }

  List<String> roadsBetween(int fromIndex, int toIndex) {
    final lo = math.min(fromIndex, toIndex).clamp(0, waypoints.length - 1);
    final hi = math.max(fromIndex, toIndex).clamp(0, waypoints.length - 1);
    final names = <String>[];
    for (var i = lo; i <= hi; i++) {
      final road = waypoints[i].road;
      if (names.isEmpty || names.last != road) names.add(road);
    }
    return names;
  }

  /// Next maneuvers after [raceAlongMeters], Google-style turn list.
  List<NavHint> upcoming(double raceAlongMeters, {double? untilAlong, int max = 3}) {
    _ensure();
    final endCap = untilAlong ?? raceMeters;
    final geoAlong = (raceAlongMeters / raceMeters) * geometricMeters;
    final turns = _waypointTurns!;
    final along = _waypointAlong!;
    final out = <NavHint>[];
    for (var i = 1; i < waypoints.length; i++) {
      final raceAt = (along[i] / geometricMeters) * raceMeters;
      if (raceAt > endCap + 30) break;
      if (along[i] + 12 < geoAlong) continue;
      final meters = ((along[i] - geoAlong) / geometricMeters) * raceMeters;
      out.add(
        NavHint(
          turn: i == waypoints.length - 1 || raceAt >= endCap - 40 ? NavTurn.arrive : turns[i],
          road: waypoints[i].road,
          place: waypoints[i].place,
          metersAhead: meters.clamp(0, raceMeters),
        ),
      );
      if (out.length >= max) break;
    }
    if (out.isEmpty) {
      out.add(hintAt(raceAlongMeters, untilAlong: endCap));
    }
    return out;
  }

  ({List<GeoPoint> done, List<GeoPoint> left}) splitRoute(
    int fromIndex,
    int toIndex,
    double alongMeters,
  ) {
    final start = raceAlongForWaypoint(fromIndex);
    final end = raceAlongForWaypoint(toIndex);
    final lo = math.min(start, end);
    final hi = math.max(start, end);
    final cut = alongMeters.clamp(lo, hi);
    final done = <GeoPoint>[];
    final left = <GeoPoint>[];
    for (final s in samples) {
      final race = (s.alongMeters / geometricMeters) * raceMeters;
      if (race < lo - 20 || race > hi + 20) continue;
      final g = geoFromMeters(s.x, s.y);
      if (race <= cut) {
        done.add(g);
      } else {
        if (left.isEmpty && done.isNotEmpty) left.add(done.last);
        left.add(g);
      }
    }
    return (done: done, left: left);
  }

  void _ensure() {
    samples;
  }

  List<RouteSample> _buildSamples() {
    final meters = waypoints.map((w) => toMeters(w.geo)).toList();
    final along = <double>[0];
    for (var i = 1; i < meters.length; i++) {
      final dx = meters[i].x - meters[i - 1].x;
      final dy = meters[i].y - meters[i - 1].y;
      along.add(along.last + math.sqrt(dx * dx + dy * dy));
    }
    _waypointAlong = along;
    _waypointTurns = List<NavTurn>.generate(waypoints.length, (i) {
      if (i == 0) return NavTurn.depart;
      if (i == waypoints.length - 1) return NavTurn.arrive;
      final hIn = _heading(meters[i - 1].x, meters[i - 1].y, meters[i].x, meters[i].y);
      final hOut = _heading(meters[i].x, meters[i].y, meters[i + 1].x, meters[i + 1].y);
      return turnFromDelta(_wrapAngle(hOut - hIn));
    });

    final out = <RouteSample>[];
    const step = 18.0;
    var dist = 0.0;
    while (dist <= along.last) {
      var i = 1;
      while (i < along.length && along[i] < dist) {
        i++;
      }
      i = i.clamp(1, along.length - 1);
      final a = along[i - 1];
      final b = along[i];
      final u = ((dist - a) / (b - a).clamp(0.0001, 1e9)).clamp(0.0, 1.0);
      final x = meters[i - 1].x + (meters[i].x - meters[i - 1].x) * u;
      final y = meters[i - 1].y + (meters[i].y - meters[i - 1].y) * u;
      final heading = _heading(meters[i - 1].x, meters[i - 1].y, meters[i].x, meters[i].y);
      out.add(
        RouteSample(
          x: x,
          y: y,
          alongMeters: dist,
          heading: heading,
          segmentIndex: i - 1,
        ),
      );
      dist += step;
    }
    final last = meters.last;
    out.add(
      RouteSample(
        x: last.x,
        y: last.y,
        alongMeters: along.last,
        heading: out.last.heading,
        segmentIndex: waypoints.length - 2,
      ),
    );
    return out;
  }

  NavTurn turnFromDelta(double delta) {
    if (delta > 0.55) return NavTurn.right;
    if (delta < -0.55) return NavTurn.left;
    if (delta > 0.18) return NavTurn.slightRight;
    if (delta < -0.18) return NavTurn.slightLeft;
    return NavTurn.straight;
  }

  double _heading(double x0, double y0, double x1, double y1) {
    return math.atan2(x1 - x0, y1 - y0);
  }

  double _lerpHeading(double a, double b, double t) {
    return a + _wrapAngle(b - a) * t;
  }

  double _wrapAngle(double a) {
    while (a > math.pi) {
      a -= math.pi * 2;
    }
    while (a < -math.pi) {
      a += math.pi * 2;
    }
    return a;
  }
}

RouteWaypoint mapStop(double lat, double lng, String place, String road) {
  return RouteWaypoint(geo: GeoPoint(lat, lng), place: place, road: road);
}

double mapPathKm(List<RouteWaypoint> stops) {
  if (stops.length < 2) return 8;
  const latM = 110.948;
  final origin = stops.first.geo;
  final lngM = 110.948 * math.cos(origin.lat * math.pi / 180);
  var km = 0.0;
  for (var i = 1; i < stops.length; i++) {
    final dx = (stops[i].geo.lng - stops[i - 1].geo.lng) * lngM;
    final dy = (stops[i].geo.lat - stops[i - 1].geo.lat) * latM;
    km += math.sqrt(dx * dx + dy * dy);
  }
  return (km * 10).round() / 10;
}

/// Drive loop around a searched place so the live map opens on that real location.
RaceMap mapAround(String place, double lat, double lng) {
  final stops = [
    mapStop(lat, lng, place, 'Start Road'),
    mapStop(lat + 0.012, lng + 0.004, 'North', 'North Road'),
    mapStop(lat + 0.016, lng + 0.014, 'Market', 'Market Street'),
    mapStop(lat + 0.008, lng + 0.022, 'Station', 'Station Road'),
    mapStop(lat - 0.002, lng + 0.018, 'Bridge', 'Bridge Road'),
    mapStop(lat - 0.010, lng + 0.008, 'Park', 'Park Road'),
    mapStop(lat - 0.008, lng - 0.004, 'Harbor', 'Coast Road'),
    mapStop(lat - 0.002, lng + 0.001, place, 'Finish Road'),
  ];
  return RaceMap(
    id: 'custom',
    name: place,
    waypoints: stops,
    raceKm: mapPathKm(stops),
    sides: const {
      'Harbor': SidePair(SideKind.sand, SideKind.sand),
      'Park': SidePair(SideKind.green, SideKind.city),
      'Market': SidePair(SideKind.city, SideKind.city),
    },
  );
}

class RaceMaps {
  RaceMaps._();

  static final chennai = RaceMap(
    id: 'chennai',
    name: 'Chennai',
    country: 'India',
    waypoints: chennaiWaypoints,
    raceKm: 22,
    sides: const {
      'Adyar': SidePair(SideKind.sand, SideKind.sand),
      'Indira Nagar': SidePair(SideKind.sand, SideKind.sand),
      'Thiruvanmiyur': SidePair(SideKind.sand, SideKind.sand),
      'Guindy': SidePair(SideKind.green, SideKind.city),
      'Little Mount': SidePair(SideKind.green, SideKind.city),
      'Moolakadai': SidePair(SideKind.city, SideKind.sand),
      'Peravallur': SidePair(SideKind.city, SideKind.sand),
      'Ayanavaram': SidePair(SideKind.city, SideKind.sand),
    },
  );

  static final mumbai = _city('mumbai', 'Mumbai', 'India', [
    mapStop(18.9322, 72.8264, 'Churchgate', 'Marine Drive'),
    mapStop(18.9435, 72.8231, 'Chowpatty', 'Marine Drive'),
    mapStop(19.0178, 72.8478, 'Dadar', 'Senapati Bapat Marg'),
    mapStop(19.0544, 72.8406, 'Bandra', 'Linking Road'),
    mapStop(19.1197, 72.8464, 'Andheri', 'Western Express Highway'),
    mapStop(19.1663, 72.8526, 'Goregaon', 'Western Express Highway'),
    mapStop(19.2307, 72.8567, 'Borivali', 'S V Road'),
  ], sand: const ['Chowpatty']);

  static final delhi = _city('delhi', 'Delhi', 'India', [
    mapStop(28.6129, 77.2295, 'India Gate', 'Rajpath'),
    mapStop(28.6315, 77.2167, 'Connaught Place', 'Barakhamba Road'),
    mapStop(28.6514, 77.1907, 'Karol Bagh', 'Pusa Road'),
    mapStop(28.6496, 77.1225, 'Rajouri Garden', 'Najafgarh Road'),
    mapStop(28.6219, 77.0878, 'Janakpuri', 'Outer Ring Road'),
    mapStop(28.5921, 77.0460, 'Dwarka', 'Dwarka Expressway'),
  ]);

  static final bengaluru = _city('bengaluru', 'Bengaluru', 'India', [
    mapStop(12.9766, 77.5713, 'Majestic', 'K G Road'),
    mapStop(12.9756, 77.6068, 'MG Road', 'MG Road'),
    mapStop(12.9784, 77.6408, 'Indiranagar', '100 Feet Road'),
    mapStop(12.9591, 77.6974, 'Marathahalli', 'Outer Ring Road'),
    mapStop(12.9698, 77.7500, 'Whitefield', 'ITPL Road'),
  ], green: const ['Whitefield']);

  static final hyderabad = _city('hyderabad', 'Hyderabad', 'India', [
    mapStop(17.3616, 78.4747, 'Charminar', 'Charminar Road'),
    mapStop(17.3930, 78.4750, 'Abids', 'Abids Road'),
    mapStop(17.4156, 78.4347, 'Banjara Hills', 'Road No 1'),
    mapStop(17.4318, 78.4070, 'Jubilee Hills', 'Road No 36'),
    mapStop(17.4435, 78.3772, 'Hitech City', 'Hitech City Road'),
  ]);

  static final kolkata = _city('kolkata', 'Kolkata', 'India', [
    mapStop(22.5958, 88.2636, 'Howrah', 'Howrah Bridge Approach'),
    mapStop(22.5726, 88.3639, 'Esplanade', 'J L Nehru Road'),
    mapStop(22.5535, 88.3527, 'Park Street', 'Park Street'),
    mapStop(22.5769, 88.4332, 'Salt Lake', 'Broadway'),
    mapStop(22.6141, 88.4625, 'New Town', 'Major Arterial Road'),
  ]);

  static final kochi = _city('kochi', 'Kochi', 'India', [
    mapStop(9.9658, 76.2421, 'Fort Kochi', 'Beach Road'),
    mapStop(9.9816, 76.2999, 'Ernakulam', 'MG Road'),
    mapStop(10.0150, 76.3100, 'Edappally', 'NH 66'),
    mapStop(10.0531, 76.3270, 'Kalamassery', 'NH 66'),
  ], sand: const ['Fort Kochi']);

  static final dubai = _city('dubai', 'Dubai', 'UAE', [
    mapStop(25.0805, 55.1403, 'Marina', 'Marina Walk'),
    mapStop(25.1412, 55.1850, 'Jumeirah', 'Jumeirah Beach Road'),
    mapStop(25.1972, 55.2744, 'Downtown', 'Sheikh Zayed Road'),
    mapStop(25.2324, 55.2960, 'Deira', 'Al Ittihad Road'),
  ], sand: const ['Marina', 'Jumeirah']);

  static final singapore = _city('singapore', 'Singapore', 'Singapore', [
    mapStop(1.2834, 103.8607, 'Marina Bay', 'Raffles Avenue'),
    mapStop(1.3048, 103.8318, 'Orchard', 'Orchard Road'),
    mapStop(1.3123, 103.8384, 'Newton', 'Scotts Road'),
    mapStop(1.3521, 103.8198, 'Toa Payoh', 'Lorong 6'),
  ], sand: const ['Marina Bay']);

  static final london = _city('london', 'London', 'UK', [
    mapStop(51.4994, -0.1248, 'Westminster', 'Victoria Embankment'),
    mapStop(51.5390, -0.1426, 'Camden', 'Camden High Street'),
    mapStop(51.5362, -0.1030, 'Islington', 'Upper Street'),
    mapStop(51.4826, 0.0077, 'Greenwich', 'Greenwich High Road'),
  ], green: const ['Greenwich']);

  static final newYork = _city('new_york', 'New York', 'USA', [
    mapStop(40.7033, -74.0170, 'Battery Park', 'State Street'),
    mapStop(40.7233, -74.0030, 'SoHo', 'Broadway'),
    mapStop(40.7549, -73.9840, 'Midtown', '5th Avenue'),
    mapStop(40.7829, -73.9654, 'Central Park', 'Central Park West'),
    mapStop(40.8116, -73.9465, 'Harlem', 'Malcolm X Boulevard'),
  ], green: const ['Central Park']);

  static final tokyo = _city('tokyo', 'Tokyo', 'Japan', [
    mapStop(35.6595, 139.7004, 'Shibuya', 'Shibuya Crossing'),
    mapStop(35.6938, 139.7034, 'Shinjuku', 'Yasukuni Street'),
    mapStop(35.6812, 139.7671, 'Tokyo Station', 'Yaesu'),
    mapStop(35.7138, 139.7770, 'Ueno', 'Ueno Park Street'),
  ], green: const ['Ueno']);

  static final List<RaceMap> all = [
    chennai,
    mumbai,
    delhi,
    bengaluru,
    hyderabad,
    kolkata,
    kochi,
    dubai,
    singapore,
    london,
    newYork,
    tokyo,
  ];

  static RaceMap byId(String id) {
    return all.firstWhere((m) => m.id == id, orElse: () => chennai);
  }

  static RaceMap _city(
    String id,
    String name,
    String country,
    List<RouteWaypoint> stops, {
    List<String> sand = const [],
    List<String> green = const [],
  }) {
    final sides = <String, SidePair>{};
    for (final place in sand) {
      sides[place] = const SidePair(SideKind.sand, SideKind.sand);
    }
    for (final place in green) {
      sides[place] = const SidePair(SideKind.green, SideKind.city);
    }
    return RaceMap(
      id: id,
      name: name,
      country: country,
      waypoints: stops,
      raceKm: mapPathKm(stops),
      sides: sides,
    );
  }
}

/// Test and legacy entry for the original Chennai race.
class ChennaiRoute {
  ChennaiRoute._();

  static RaceMap get map => RaceMaps.chennai;
  static String get startName => map.startName;
  static String get endName => map.endName;
  static double get raceKm => map.raceKm;
  static double get raceMeters => map.raceMeters;
  static List<RouteWaypoint> get waypoints => map.waypoints;
  static List<RouteSample> get samples => map.samples;

  static double tripKm(int fromIndex, int toIndex) => map.tripKm(fromIndex, toIndex);

  static String etaLabel(double km, {double kmh = 42}) => map.etaLabel(km, kmh: kmh);

  static NavHint hintAt(double raceAlongMeters, {double? untilAlong}) =>
      map.hintAt(raceAlongMeters, untilAlong: untilAlong);

  static SidePair sidesForPlace(String place) => map.sidesForPlace(place);

  static List<NavHint> upcoming(double raceAlongMeters, {double? untilAlong, int max = 3}) =>
      map.upcoming(raceAlongMeters, untilAlong: untilAlong, max: max);

  static List<String> roadsBetween(int fromIndex, int toIndex) => map.roadsBetween(fromIndex, toIndex);

  static ({List<GeoPoint> done, List<GeoPoint> left}) splitRoute(
    int fromIndex,
    int toIndex,
    double alongMeters,
  ) =>
      map.splitRoute(fromIndex, toIndex, alongMeters);
}
