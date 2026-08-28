import 'package:centrode/shared/theme/design_tokens.dart';
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

  static NodeStyle fallbackStyle([
    double? width,
    double? height,
    double? fontSize,
  ]) =>
      resolver.fallbackStyle(width, height, fontSize);

  static NodeStyle scaleStyle(NodeStyle base) => resolver.scaleStyle(base);

  static NodeStyle resolveStyle(UiNode node, {GraphTheme? theme}) {
    if (node.resolvedStyle != null) return node.resolvedStyle!;
    if (theme != null) {
      return const DefaultNodeStyleStrategy().computeStyle(node, theme);
    }
    return resolver.resolveStyle(node);
  }
}

class DefaultNodeStyleStrategy implements NodeStyleStrategy {
  const DefaultNodeStyleStrategy();

  @override
  NodeStyle computeStyle(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;

    if (node is ContainerUiNode) {
      return NodeStyleStrategy.fallbackStyle(
        node.size.width,
        node.size.height,
        theme.bodyFontSize,
      ).copyWith(
        bgColor: resolver.containerBgColor,
        strokeColor: resolver.containerStrokeColor,
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
        bgColor: resolver.frameBgColor,
        strokeColor: resolver.frameStrokeColor,
        strokeWidth: UiStrokeWidth.thick.toInt(),
        fontFamily: theme.fontFamily,
        textColor: 0xFFFFFFFF,
        borderRadius: UiRadius.card,
      );
    }

    final int bgColor = _computeBaseColor(node, theme);
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

  int _computeBaseColor(UiNode node, GraphTheme theme) {
    return switch (node) {
      TaskUiNode() => 0xFF34D399,
      DrawingUiNode() => 0x00000000,
      ContainerUiNode() => resolver.containerBgColor,
      FrameUiNode() => resolver.frameStrokeColor,
      InfoUiNode() => theme.primaryColor.toARGB32(),
      _ => theme.primaryColor.toARGB32(),
    };
  }
}
