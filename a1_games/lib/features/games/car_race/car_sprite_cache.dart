import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import 'car_catalog.dart';

/// Decodes racing sprites once, at reduced size, for mid-range Android.
class CarSpriteCache {
  CarSpriteCache._();

  static final Map<String, ui.Image> _images = {};
  static Future<void>? _loading;

  static ui.Image? get(String path) => _images[path];

  static bool get isReady => _images.isNotEmpty;

  static Future<void> preload() {
    return _loading ??= _loadAll();
  }

  static Future<void> _loadAll() async {
    for (final path in CarCatalog.allAssetPaths) {
      try {
        final data = await rootBundle.load(path);
        final bytes = data.buffer.asUint8List();
        final targetW = path.contains('/city/')
            ? 512
            : path.contains('/cars/')
                ? 120
                : 96;
        final codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: targetW,
        );
        final frame = await codec.getNextFrame();
        _images[path] = frame.image;
      } catch (_) {
        // Fallback painter draws vector cars if a file is missing.
      }
    }
  }
}
