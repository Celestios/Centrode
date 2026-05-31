part of 'liquid_glass_menu.dart';

/// Simplified shape data structure used to pass geometry information to the shader.
/// Each LiquidGlass widget gets converted into this format for GPU processing.
class ShapeData {
  final Offset center;
  final Size size;
  final double borderRadius;
  final Color color;

  ShapeData(this.center, this.size, this.borderRadius, this.color);
}
