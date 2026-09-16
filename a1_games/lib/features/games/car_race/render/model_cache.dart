import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'glb_loader.dart';
import 'model3d.dart';

/// Lazy GLB + texture cache. Does not load the whole city at startup.
class ModelCache {
  ModelCache._();

  static final Map<String, Model3D> _models = {};
  static final Map<String, Future<Model3D?>> _modelLoads = {};
  static final Map<String, ui.Image> _images = {};
  static final Map<String, Future<ui.Image?>> _imageLoads = {};

  static bool get hasAnything => _models.isNotEmpty;

  static Model3D? peek(String path) => _models[path];

  static ui.Image? image(String path) => _images[path];

  static Future<Model3D?> load(String path) {
    if (_models.containsKey(path)) return Future.value(_models[path]);
    return _modelLoads.putIfAbsent(path, () async {
      try {
        final model = await GlbLoader.load(path);
        _models[path] = model;
        await loadImage(model.textureAsset);
        return model;
      } catch (e, st) {
        debugPrint('ModelCache failed $path: $e\n$st');
        return null;
      }
    });
  }

  static Future<ui.Image?> loadImage(String path) {
    if (_images.containsKey(path)) return Future.value(_images[path]);
    return _imageLoads.putIfAbsent(path, () async {
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 256,
        );
        final frame = await codec.getNextFrame();
        _images[path] = frame.image;
        return frame.image;
      } catch (e) {
        debugPrint('ModelCache image failed $path: $e');
        return null;
      }
    });
  }

  static Future<void> preload(List<String> paths) async {
    for (final path in paths) {
      await load(path);
    }
  }
}
