import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/features/graph/models/node_style_resolver.dart'
    as resolver;
import 'package:centrode/presentation/theme/graph_theme.dart';
import 'package:centrode/shared/utils/color_utils.dart';

export 'package:centrode/features/graph/models/node_style_resolver.dart'
    show expandToggleSpace, taskBadgeHeight;

abstract class NodeStyleStrategy {
  const NodeStyleStrategy();

  NodeStyle computeStyle(UiNode node, GraphTheme theme);

  static CentrodeDerivedPalette? _palette;

  static void setPalette(CentrodeDerivedPalette palette) => _palette = palette;

  static CentrodeDerivedPalette get _currentPalette {
    return _palette ?? CentrodeDerivedPalette.fromColors(
      primary: const Color(0xFF1976D2),
      accent: const Color(0xFFFF4081),
      canvasAccent: const Color(0xFF2196F3),
    );
  }

  static NodeStyle fallbackStyle([
    double? width,
    double? height,
    double? fontSize,
  ]) =>
      resolver.fallbackStyle(width, height, fontSize);

  static NodeStyle scaleStyle(NodeStyle base) => resolver.scaleStyle(base);

  static int _containerBgColor(CentrodeDerivedPalette palette) =>
      palette.canvas.containerBorder
          .withValues(alpha: palette.alpha.containerFill)
          .toARGB32();

  static int _containerStrokeColor(CentrodeDerivedPalette palette) =>
      palette.canvas.containerBorder.toARGB32();

  static int _frameBgColor(CentrodeDerivedPalette palette) =>
      palette.canvas.frameBorder
          .withValues(alpha: palette.alpha.frameFill)
          .toARGB32();

  static int _frameStrokeColor(CentrodeDerivedPalette palette) =>
      palette.canvas.frameBorder.toARGB32();

  static NodeStyle resolveStyle(UiNode node, {GraphTheme? theme, CentrodeDerivedPalette? palette}) {
    if (node.resolvedStyle != null) return node.resolvedStyle!;
    final p = palette ?? _currentPalette;
    if (theme != null) {
      return DefaultNodeStyleStrategy(palette: p).computeStyle(node, theme);
    }
    return resolver.resolveStyle(
      node,
      containerBgColor: _containerBgColor(p),
      containerStrokeColor: _containerStrokeColor(p),
      frameBgColor: _frameBgColor(p),
      frameStrokeColor: _frameStrokeColor(p),
    );
  }
}

class DefaultNodeStyleStrategy implements NodeStyleStrategy {
  final CentrodeDerivedPalette? palette;

  const DefaultNodeStyleStrategy({this.palette});

  @override
  NodeStyle computeStyle(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;

    final p = palette ?? CentrodeDerivedPalette.fromColors(
      primary: const Color(0xFF1976D2),
      accent: const Color(0xFFFF4081),
      canvasAccent: const Color(0xFF2196F3),
    );

    if (node is ContainerUiNode) {
      return NodeStyleStrategy.fallbackStyle(
        node.size.width,
        node.size.height,
        theme.bodyFontSize,
      ).copyWith(
        bgColor: NodeStyleStrategy._containerBgColor(p),
        strokeColor: NodeStyleStrategy._containerStrokeColor(p),
        strokeWidth: UiStrokeWidth.thick.toInt(),
        fontFamily: theme.fontFamily,
        textColor: 0xFFFFFFFF,
        borderRadius: UiRadius.panel,
      );
    }

    if (node is FrameUiNode) {
      return NodeStyleStrategy.fallbackStyle(
        node.size.width,
        node.size.height,
        theme.bodyFontSize,
      ).copyWith(
        bgColor: NodeStyleStrategy._frameBgColor(p),
        strokeColor: NodeStyleStrategy._frameStrokeColor(p),
        strokeWidth: UiStrokeWidth.thick.toInt(),
        fontFamily: theme.fontFamily,
        textColor: 0xFFFFFFFF,
        borderRadius: UiRadius.card,
      );
    }

    final int bgColor = _computeBaseColor(node, theme, p);
    return NodeStyleStrategy.fallbackStyle(
      null,
      null,
      theme.bodyFontSize,
    ).copyWith(
      bgColor: bgColor,
      strokeColor: ColorUtils.getContrastStrokeColorInt(bgColor),
      fontFamily: theme.fontFamily,
      textColor: ColorUtils.getContrastTextColorInt(bgColor),
      borderRadius: theme.borderRadius,
    );
  }

  int _computeBaseColor(UiNode node, GraphTheme theme, CentrodeDerivedPalette palette) {
    final tints = palette.nodeTints;
    return switch (node) {
      InfoUiNode() => tints.info.toARGB32(),
      TaskUiNode() => tints.task.toARGB32(),
      CommentUiNode() => tints.comment.toARGB32(),
      DrawingUiNode() => tints.drawing.toARGB32(),
      ShapeUiNode() => tints.shape.toARGB32(),
      MediaUiNode() => tints.media.toARGB32(),
      InterUiNode() => tints.inter.toARGB32(),
      ContainerUiNode() => NodeStyleStrategy._containerBgColor(palette),
      FrameUiNode() => NodeStyleStrategy._frameStrokeColor(palette),
    };
  }
}
