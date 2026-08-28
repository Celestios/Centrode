import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/shared/theme/design_tokens.dart';

class NodeVisualConstants {
  NodeVisualConstants._();

  static double fontScale(double fontSize) => CanvasTokens.fontScale(fontSize);
  static double scaledBadgeFontSize(double fontSize) =>
      10.0 * fontScale(fontSize);
  static double scaledShowMoreFontSize(double fontSize) =>
      10.0 * fontScale(fontSize);

  static double scaledPadding(
    NodeStyle style,
    double scale, {
    required bool isEditing,
  }) {
    final double basePadding = isEditing ? UiSpacing.tight : style.padding;
    final double extraCornerPadding = style.borderRadius * 0.15;
    return (basePadding + extraCornerPadding) * scale;
  }

  static const double editingStrokeWidth = UiStrokeWidth.thick;
  static const double editingShadowBlur = 16.0;
  static int get editingShadowColor =>
      AppThemeManager.instance.currentTheme.canvasAccentColor.withValues(alpha: 0.38).toARGB32();
  static const double selectedShadowBlur = 8.0;
  static const int selectedShadowColor = 0x4442A5F5;
  static int get editingBorderColor =>
      AppThemeManager.instance.currentTheme.canvasAccentColor.toARGB32();
  static const int selectedBorderColor = 0xFF42A5F5;
  static const double handleWidth = CanvasTokens.handleWidth;
  static const double handleTopOffset = CanvasTokens.handleTopOffset;
  static const int handleColor = 0x03000000;
  static const double expandToggleBottomOffset = 20.0;
  static const int expandToggleColor = 0xFF2196F5;
  static const double expandToggleFontSize = 10.0;
  static const double expandButtonHeight = CanvasTokens.expandButtonHeight;
  static const double expandIconSize = CanvasTokens.expandIconSize;
  static const double hoverOverlayAlpha = 0.05;

  static int metadataSphereColor({
    required bool hasTags,
    required bool hasComments,
  }) {
    if (hasTags && hasComments) return 0xFFEC407A;
    if (hasTags) return 0xFF5C6BC0;
    return 0xFF26A69A;
  }
}
