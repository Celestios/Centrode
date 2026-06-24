import 'package:mycelium/src/rust/domain/styles.dart';

class NodeVisualConstants {
  NodeVisualConstants._();

  static double fontScale(double fontSize) => fontSize / 14.0;
  static double scaledBadgeFontSize(double fontSize) => 10.0 * fontScale(fontSize);
  static double scaledShowMoreFontSize(double fontSize) => 10.0 * fontScale(fontSize);

  static double scaledPadding(NodeStyle style, double scale, {required bool isEditing}) {
    final double basePadding = isEditing ? 2.0 : style.padding;
    final double extraCornerPadding = style.borderRadius * 0.15;
    return (basePadding + extraCornerPadding) * scale;
  }

  static const double editingStrokeWidth = 3.0;
  static const double editingShadowBlur = 16.0;
  static const int editingShadowColor = 0x602196F3;
  static const double selectedShadowBlur = 8.0;
  static const int selectedShadowColor = 0x4442A5F5;
  static const int editingBorderColor = 0xFF2196F3;
  static const int selectedBorderColor = 0xFF42A5F5;
  static const double handleWidth = 5.0;
  static const double handleTopOffset = 24.0;
  static const int handleColor = 0x03000000;
  static const double expandToggleBottomOffset = 20.0;
  static const int expandToggleColor = 0xFF2196F5;
  static const double expandToggleFontSize = 10.0;
  static const double hoverOverlayAlpha = 0.05;

  static int metadataSphereColor({required bool hasTags, required bool hasComments}) {
    if (hasTags && hasComments) return 0xFFEC407A;
    if (hasTags) return 0xFF5C6BC0;
    return 0xFF26A69A;
  }
}
