import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:vector_math/vector_math_64.dart';

import 'model3d.dart';

/// Minimal GLB (glTF 2 binary) loader for Kenney-style models.
/// Loads POSITION / NORMAL / TEXCOORD_0 / indices only. No Draco, no morphs.
class GlbLoader {
  GlbLoader._();

  static const _float = 5126;
  static const _uByte = 5121;
  static const _uShort = 5123;
  static const _uInt = 5125;

  static Future<Model3D> load(String assetPath) async {
    final bytes = (await rootBundle.load(assetPath)).buffer.asUint8List();
    if (bytes.length < 20) {
      throw StateError('GLB too small: $assetPath');
    }
    final magic = String.fromCharCodes(bytes.sublist(0, 4));
    if (magic != 'glTF') {
      throw StateError('Not a GLB: $assetPath');
    }

    Map<String, dynamic>? json;
    Uint8List? bin;
    var offset = 12;
    while (offset + 8 <= bytes.length) {
      final clen = bytes.buffer.asByteData().getUint32(offset, Endian.little);
      final ctype = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
      offset += 8;
      final chunk = bytes.sublist(offset, math.min(offset + clen, bytes.length));
      offset = (offset + clen + 3) & ~3;
      if (ctype.startsWith('JSON')) {
        json = jsonDecode(utf8.decode(chunk)) as Map<String, dynamic>;
      } else if (ctype.startsWith('BIN')) {
        bin = chunk;
      }
    }
    if (json == null || bin == null) {
      throw StateError('GLB missing JSON/BIN: $assetPath');
    }

    final dir = assetPath.contains('/')
        ? assetPath.substring(0, assetPath.lastIndexOf('/'))
        : '';
    String textureAsset = '$dir/Textures/colormap.png';
    final images = json['images'] as List<dynamic>?;
    if (images != null && images.isNotEmpty) {
      final uri = (images.first as Map)['uri'] as String?;
      if (uri != null && uri.isNotEmpty) {
        textureAsset = '$dir/$uri';
      }
    }

    final accessors = (json['accessors'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final views = (json['bufferViews'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final meshes = (json['meshes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final nodes = (json['nodes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final scenes = (json['scenes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final sceneIndex = (json['scene'] as num?)?.toInt() ?? 0;
    final rootNodes = sceneIndex < scenes.length
        ? ((scenes[sceneIndex]['nodes'] as List<dynamic>?) ?? [0])
            .map((e) => (e as num).toInt())
            .toList()
        : [for (var i = 0; i < nodes.length; i++) i];

    final parts = <MeshPart>[];

    void walk(int nodeIndex, Matrix4 parent) {
      if (nodeIndex < 0 || nodeIndex >= nodes.length) return;
      final node = nodes[nodeIndex];
      final local = _nodeMatrix(node);
      final world = parent.clone()..multiply(local);
      final meshIndex = (node['mesh'] as num?)?.toInt();
      if (meshIndex != null && meshIndex >= 0 && meshIndex < meshes.length) {
        final mesh = meshes[meshIndex];
        final name = (node['name'] as String?) ??
            (mesh['name'] as String?) ??
            'mesh_$meshIndex';
        final primitives = (mesh['primitives'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        for (final prim in primitives) {
          final part = _primitive(
            name: name,
            prim: prim,
            accessors: accessors,
            views: views,
            bin: bin!,
            nodeMatrix: world.clone(),
            textureAsset: textureAsset,
          );
          if (part != null) parts.add(part);
        }
      }
      final children = (node['children'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toInt());
      for (final c in children) {
        walk(c, world);
      }
    }

    for (final root in rootNodes) {
      walk(root, Matrix4.identity());
    }

    if (parts.isEmpty) {
      throw StateError('GLB has no mesh primitives: $assetPath');
    }
    return Model3D(assetPath: assetPath, parts: parts, textureAsset: textureAsset);
  }

  static Matrix4 _nodeMatrix(Map<String, dynamic> node) {
    if (node['matrix'] is List) {
      final m = (node['matrix'] as List).map((e) => (e as num).toDouble()).toList();
      return Matrix4.fromList(m);
    }
    final tList = node['translation'] as List<dynamic>?;
    final rList = node['rotation'] as List<dynamic>?;
    final sList = node['scale'] as List<dynamic>?;
    final t = tList == null
        ? Vector3.zero()
        : Vector3(
            (tList[0] as num).toDouble(),
            (tList[1] as num).toDouble(),
            (tList[2] as num).toDouble(),
          );
    final q = rList == null
        ? Quaternion.identity()
        : Quaternion(
            (rList[0] as num).toDouble(),
            (rList[1] as num).toDouble(),
            (rList[2] as num).toDouble(),
            (rList[3] as num).toDouble(),
          );
    final s = sList == null
        ? Vector3.all(1)
        : Vector3(
            (sList[0] as num).toDouble(),
            (sList[1] as num).toDouble(),
            (sList[2] as num).toDouble(),
          );
    return Matrix4.compose(t, q, s);
  }

  static MeshPart? _primitive({
    required String name,
    required Map<String, dynamic> prim,
    required List<Map<String, dynamic>> accessors,
    required List<Map<String, dynamic>> views,
    required Uint8List bin,
    required Matrix4 nodeMatrix,
    required String textureAsset,
  }) {
    final attrs = (prim['attributes'] as Map<String, dynamic>? ?? {});
    final posIndex = (attrs['POSITION'] as num?)?.toInt();
    if (posIndex == null) return null;
    final positions = _readFloat3(accessors[posIndex], views, bin);
    if (positions.isEmpty) return null;

    Float32List normals;
    final nIndex = (attrs['NORMAL'] as num?)?.toInt();
    if (nIndex != null) {
      normals = _readFloat3(accessors[nIndex], views, bin);
    } else {
      normals = Float32List(positions.length)..fillRange(0, positions.length, 0);
      for (var i = 1; i < normals.length; i += 3) {
        normals[i] = 1;
      }
    }

    Float32List uvs;
    final uvIndex = (attrs['TEXCOORD_0'] as num?)?.toInt();
    if (uvIndex != null) {
      uvs = _readFloat2(accessors[uvIndex], views, bin);
    } else {
      uvs = Float32List(positions.length ~/ 3 * 2);
    }

    final indicesIndex = (prim['indices'] as num?)?.toInt();
    Uint16List indices;
    if (indicesIndex != null) {
      indices = _readIndices(accessors[indicesIndex], views, bin);
    } else {
      final count = positions.length ~/ 3;
      indices = Uint16List(count);
      for (var i = 0; i < count; i++) {
        indices[i] = i;
      }
    }

    return MeshPart(
      name: name,
      positions: positions,
      normals: normals,
      uvs: uvs,
      indices: indices,
      nodeMatrix: nodeMatrix,
      textureAsset: textureAsset,
    );
  }

  static ByteData _viewBytes(
    Map<String, dynamic> accessor,
    List<Map<String, dynamic>> views,
    Uint8List bin,
  ) {
    final viewIndex = (accessor['bufferView'] as num?)?.toInt() ?? 0;
    final view = views[viewIndex];
    final viewOffset = (view['byteOffset'] as num?)?.toInt() ?? 0;
    final accOffset = (accessor['byteOffset'] as num?)?.toInt() ?? 0;
    return ByteData.sublistView(bin, viewOffset + accOffset);
  }

  static int _stride(Map<String, dynamic> accessor, List<Map<String, dynamic>> views, int comps, int size) {
    final viewIndex = (accessor['bufferView'] as num?)?.toInt() ?? 0;
    final view = views[viewIndex];
    return (view['byteStride'] as num?)?.toInt() ?? (size * comps);
  }

  static Float32List _readFloat3(
    Map<String, dynamic> accessor,
    List<Map<String, dynamic>> views,
    Uint8List bin,
  ) {
    final count = (accessor['count'] as num).toInt();
    final data = _viewBytes(accessor, views, bin);
    final stride = _stride(accessor, views, 3, 4);
    final out = Float32List(count * 3);
    for (var i = 0; i < count; i++) {
      final o = i * stride;
      out[i * 3] = data.getFloat32(o, Endian.little);
      out[i * 3 + 1] = data.getFloat32(o + 4, Endian.little);
      out[i * 3 + 2] = data.getFloat32(o + 8, Endian.little);
    }
    return out;
  }

  static Float32List _readFloat2(
    Map<String, dynamic> accessor,
    List<Map<String, dynamic>> views,
    Uint8List bin,
  ) {
    final count = (accessor['count'] as num).toInt();
    final data = _viewBytes(accessor, views, bin);
    final stride = _stride(accessor, views, 2, 4);
    final out = Float32List(count * 2);
    for (var i = 0; i < count; i++) {
      final o = i * stride;
      out[i * 2] = data.getFloat32(o, Endian.little);
      out[i * 2 + 1] = data.getFloat32(o + 4, Endian.little);
    }
    return out;
  }

  static Uint16List _readIndices(
    Map<String, dynamic> accessor,
    List<Map<String, dynamic>> views,
    Uint8List bin,
  ) {
    final count = (accessor['count'] as num).toInt();
    final type = (accessor['componentType'] as num).toInt();
    final data = _viewBytes(accessor, views, bin);
    final out = Uint16List(count);
    switch (type) {
      case _uByte:
        for (var i = 0; i < count; i++) {
          out[i] = data.getUint8(i);
        }
      case _uShort:
        for (var i = 0; i < count; i++) {
          out[i] = data.getUint16(i * 2, Endian.little);
        }
      case _uInt:
        for (var i = 0; i < count; i++) {
          out[i] = data.getUint32(i * 4, Endian.little) & 0xFFFF;
        }
      case _float:
        for (var i = 0; i < count; i++) {
          out[i] = data.getFloat32(i * 4, Endian.little).toInt();
        }
      default:
        for (var i = 0; i < count; i++) {
          out[i] = i;
        }
    }
    return out;
  }
}
