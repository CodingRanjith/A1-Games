enum CityPropKind { road, sidewalk, building, tree, light, trafficLight, sign, parking, cone }

class CityProp {
  const CityProp({
    required this.kind,
    required this.modelPath,
    required this.x,
    required this.z,
    this.yaw = 0,
    this.scale = 1,
  });

  final CityPropKind kind;
  final String modelPath;
  final double x;
  final double z;
  final double yaw;
  final double scale;
}

/// Modular city strip. Duplicate along Z to extend the route without rebuilding the scene.
class CityCatalog {
  CityCatalog._();

  static const road = 'assets/models/roads/road-straight.glb';
  static const roadBarrier = 'assets/models/roads/road-straight-barrier.glb';
  static const crossroad = 'assets/models/roads/road-crossroad.glb';
  static const intersection = 'assets/models/roads/road-intersection.glb';
  static const sidewalk = 'assets/models/roads/road-side.glb';
  static const driveway = 'assets/models/roads/road-driveway-single.glb';
  static const streetLight = 'assets/models/roads/light-square.glb';
  static const trafficLight = 'assets/models/roads/traffic-light.glb';
  static const stopSign = 'assets/models/roads/road-sign-stop.glb';
  static const warningSign = 'assets/models/roads/road-sign-warning.glb';
  static const highwaySign = 'assets/models/roads/sign-highway.glb';

  static const shopA = 'assets/models/buildings/commercial/building-a.glb';
  static const shopC = 'assets/models/buildings/commercial/building-c.glb';
  static const shopE = 'assets/models/buildings/commercial/building-e.glb';
  static const tower = 'assets/models/buildings/commercial/building-skyscraper-a.glb';
  static const houseA = 'assets/models/buildings/suburban/building-type-a.glb';
  static const houseC = 'assets/models/buildings/suburban/building-type-c.glb';
  static const houseE = 'assets/models/buildings/suburban/building-type-e.glb';

  static const treeLarge = 'assets/models/environment/tree-large.glb';
  static const treeSmall = 'assets/models/environment/tree-small.glb';
  static const cone = 'assets/models/environment/props/cone.glb';

  static const tileLength = 14.0;
  static const roadScale = 14.0;

  static const List<String> streamingPaths = [
    road,
    sidewalk,
    streetLight,
    trafficLight,
    stopSign,
    shopA,
    shopC,
    houseA,
    treeLarge,
    treeSmall,
  ];

  static List<CityProp> moduleAt(int index) {
    final z = index * tileLength;
    final left = index.isEven ? shopA : shopC;
    final right = index % 3 == 0 ? houseA : (index % 3 == 1 ? houseC : houseE);
    final shopAlt = index % 4 == 0 ? shopE : left;
    return [
      CityProp(kind: CityPropKind.road, modelPath: road, x: 0, z: z, scale: roadScale),
      CityProp(kind: CityPropKind.sidewalk, modelPath: sidewalk, x: -9.2, z: z, yaw: 1.5708, scale: 8),
      CityProp(kind: CityPropKind.sidewalk, modelPath: sidewalk, x: 9.2, z: z, yaw: -1.5708, scale: 8),
      CityProp(kind: CityPropKind.building, modelPath: shopAlt, x: -13.5, z: z, yaw: 1.5708, scale: 7.2),
      CityProp(kind: CityPropKind.building, modelPath: right, x: 13.8, z: z, yaw: -1.5708, scale: 7.0),
      if (index % 5 == 0)
        CityProp(kind: CityPropKind.building, modelPath: tower, x: -18, z: z + 4, scale: 8.5),
      CityProp(kind: CityPropKind.tree, modelPath: treeLarge, x: -10.6, z: z - 3.2, scale: 6),
      CityProp(kind: CityPropKind.tree, modelPath: treeSmall, x: 10.8, z: z + 3.4, scale: 5.5),
      CityProp(kind: CityPropKind.light, modelPath: streetLight, x: 8.4, z: z - 4, scale: 6),
      CityProp(kind: CityPropKind.light, modelPath: streetLight, x: -8.4, z: z + 4, scale: 6),
      if (index % 4 == 2) ...[
        CityProp(kind: CityPropKind.trafficLight, modelPath: trafficLight, x: 7.6, z: z, scale: 5.5),
        CityProp(kind: CityPropKind.sign, modelPath: stopSign, x: -7.4, z: z + 2, scale: 5),
      ],
      if (index % 6 == 1)
        CityProp(kind: CityPropKind.parking, modelPath: driveway, x: 11.5, z: z, yaw: -1.5708, scale: 6),
      if (index % 7 == 3)
        CityProp(kind: CityPropKind.cone, modelPath: cone, x: 5.2, z: z + 1.5, scale: 3.2),
    ];
  }
}
