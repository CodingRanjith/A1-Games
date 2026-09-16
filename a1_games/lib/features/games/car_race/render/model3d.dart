import 'dart:typed_data';

import 'package:vector_math/vector_math_64.dart';

/// One drawable mesh attached to a glTF node (body, wheel, building, …).
class MeshPart {
  MeshPart({
    required this.name,
    required this.positions,
    required this.normals,
    required this.uvs,
    required this.indices,
    required this.nodeMatrix,
    required this.textureAsset,
  });

  final String name;
  final Float32List positions;
  final Float32List normals;
  final Float32List uvs;
  final Uint16List indices;
  final Matrix4 nodeMatrix;
  final String textureAsset;

  bool get isWheel => name.toLowerCase().contains('wheel');

  bool get isFrontWheel =>
      isWheel && (name.toLowerCase().contains('front') || name.toLowerCase().contains('f-'));
}

class Model3D {
  Model3D({
    required this.assetPath,
    required this.parts,
    required this.textureAsset,
  });

  final String assetPath;
  final List<MeshPart> parts;
  final String textureAsset;

  int get triangleCount =>
      parts.fold(0, (n, p) => n + p.indices.length ~/ 3);
}
