import 'dart:ui' as ui;
import 'package:logging/logging.dart';

class LiquidGlassShaderProvider {
  static final _log = Logger('LiquidGlassShaderProvider');
  static ui.FragmentProgram? _shaderProgram;

  static ui.FragmentProgram? get shaderProgram => _shaderProgram;

  /// Preloads the liquid glass fragment shader from assets.
  static Future<void> load() async {
    try {
      _log.info('Preloading liquid glass fragment shader...');
      _shaderProgram = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      );
      _log.info('Liquid glass shader preloaded successfully.');
    } catch (e, stack) {
      _log.severe('Failed to preload liquid glass shader: $e', e, stack);
    }
  }
}
