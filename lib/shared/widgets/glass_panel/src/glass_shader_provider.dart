part of '../glass_panel.dart';

/// Loads and caches the fragment shader used by quality-mode glass panels.
class GlassShaderProvider {
  static const String shaderAssetPath = 'shaders/liquid_glass.frag';
  static final _log = Logger('GlassShaderProvider');
  static ui.FragmentProgram? _shaderProgram;

  static ui.FragmentProgram? get shaderProgram => _shaderProgram;

  /// Preloads the fragment shader from assets.
  static Future<void> load() async {
    try {
      _log.info('Preloading liquid glass fragment shader...');
      _shaderProgram = await ui.FragmentProgram.fromAsset(shaderAssetPath);
      _log.info('Liquid glass shader preloaded successfully.');
    } catch (e, stack) {
      _log.severe('Failed to preload liquid glass shader: $e', e, stack);
    }
  }
}
