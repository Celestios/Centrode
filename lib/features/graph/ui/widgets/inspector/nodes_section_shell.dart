import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'showcase/node_showcase_card.dart';
import 'sections/node_typography_section.dart';
import 'sections/node_body_style_section.dart';
import 'sections/node_border_section.dart';
import 'sections/node_shadow_section.dart';
import 'components/glass_section_shell.dart';
import 'components/node_shape_definitions.dart';

class NodesSectionShell extends StatefulWidget {
  final bool isGlobal;
  final int selectedCount;
  final NodeRenderState? renderState;

  const NodesSectionShell({
    super.key,
    this.isGlobal = true,
    this.selectedCount = 0,
    this.renderState,
  });

  @override
  State<NodesSectionShell> createState() => _NodesSectionShellState();
}

class _NodesSectionShellState extends State<NodesSectionShell> {
  static const Map<String, int?> _highlightColorMap = {
    'none': null,
    'yellow': 0xFFFFE600,
    'cyan': 0xFF00E5FF,
    'green': 0xFF00FF66,
    'pink': 0xFFFF007A,
    'orange': 0xFFFF8800,
  };

  String _fontFamily = 'outfit';
  double _fontSize = 13.0;
  Color _textColor = Colors.white;
  String _highlightColor = 'none';
  Color? _nodeBgColor;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isStrikethrough = false;
  String _letterCase = 'normal';
  double _letterSpacing = 0.0;
  double _lineHeight = 1.2;
  bool _hasUnderline = false;
  String _underlineStyle = 'solid';
  Color _underlineColor = const Color(0xFF00E5FF);
  String _textAlign = 'center';
  TextDirection _textDirection = TextDirection.ltr;

  String _nodeShape = 'rounded';
  String _fillStyle = 'glass';
  Color? _fillTint;
  double _opacity = 85.0;
  double _cornerRadius = 12.0;

  double _borderWidth = 1.5;
  String _borderStyle = 'solid';
  double _borderOpacity = 60.0;
  Color? _borderColor;

  String _shadowMode = 'none';
  double _shadowBlur = 14.0;
  double _shadowDistance = 4.0;
  Color? _shadowColor;

  String? _lastSelectionSignature;

  NodeRenderState _getRenderState(BuildContext context) =>
      widget.renderState ?? context.watch<NodeRenderState>();

  List<UiNode> _getSelectedNodes(NodeRenderState renderState) {
    return renderState.selectedEntities
        .map((id) => renderState.getNode(id))
        .whereType<UiNode>()
        .toList();
  }

  bool _areNodeAppearancesEqual(List<UiNode> nodes) {
    if (nodes.isEmpty) return true;
    final firstStyle = nodes.first.style;
    for (int i = 1; i < nodes.length; i++) {
      final s = nodes[i].style;
      if (firstStyle != s) {
        if (firstStyle == null || s == null) return false;
        if (firstStyle.shape != s.shape ||
            firstStyle.fontFamily != s.fontFamily ||
            firstStyle.fontSize != s.fontSize ||
            firstStyle.textColor != s.textColor ||
            firstStyle.bgColor != s.bgColor ||
            firstStyle.borderRadius != s.borderRadius ||
            firstStyle.strokeWidth != s.strokeWidth ||
            firstStyle.strokeColor != s.strokeColor ||
            firstStyle.shadowBlur != s.shadowBlur ||
            firstStyle.shadowColor != s.shadowColor ||
            firstStyle.shadowOffsetY != s.shadowOffsetY) {
          return false;
        }
      }
    }
    return true;
  }

  void _syncFromSelection(List<UiNode> nodes, ThemeData theme) {
    if (nodes.isEmpty) {
      _resetToDefaults(theme);
      return;
    }

    if (nodes.length > 1 && !_areNodeAppearancesEqual(nodes)) {
      return;
    }

    final node = nodes.first;
    final style = node.style;
    if (style != null) {
      _fontFamily = style.fontFamily.isNotEmpty ? style.fontFamily : 'outfit';
      _fontSize = style.fontSize > 0 ? style.fontSize : 13.0;
      _textColor = style.textColor != 0 ? Color(style.textColor) : Colors.white;

      _nodeShape = style.shape.isNotEmpty ? style.shape : 'rounded';
      _cornerRadius = style.borderRadius >= 0 ? style.borderRadius : 12.0;
      if (style.bgColor == 0) {
        _fillStyle = 'outline';
        _nodeBgColor = null;
        _fillTint = null;
      } else {
        final col = Color(style.bgColor);
        final alphaVal = ((style.bgColor >> 24) & 0xFF);
        _opacity = (alphaVal / 255.0 * 100).clamp(10.0, 100.0);
        _nodeBgColor = col.withAlpha(255);
        _fillTint = col.withAlpha(255);
        _fillStyle = alphaVal < 240 ? 'glass' : 'solid';
      }

      _borderWidth = style.strokeWidth.toDouble();
      if (style.strokeColor != 0) {
        final sc = Color(style.strokeColor);
        final sAlpha = ((style.strokeColor >> 24) & 0xFF);
        _borderOpacity = (sAlpha / 255.0 * 100).clamp(0.0, 100.0);
        _borderColor = sc.withAlpha(255);
      } else {
        _borderColor = null;
        _borderOpacity = 60.0;
      }

      _shadowBlur = style.shadowBlur;
      _shadowDistance = style.shadowOffsetY;
      if (style.shadowColor != 0) {
        _shadowColor = Color(style.shadowColor);
        if (_shadowDistance == 0 && _shadowBlur > 0) {
          _shadowMode = 'glow';
        } else if (_shadowBlur <= 6 && _shadowBlur > 0) {
          _shadowMode = 'crisp';
        } else if (_shadowBlur > 6) {
          _shadowMode = 'soft';
        } else {
          _shadowMode = 'none';
        }
      } else {
        _shadowColor = null;
        _shadowMode = 'none';
      }
    }

    final content = node.content;
    if (content.blocks.isNotEmpty) {
      final firstBlock = content.blocks.first;
      _textAlign = firstBlock.attrs?.textAlign ?? 'center';
      final allInlines = content.blocks.expand((b) => b.content);
      _isBold = allInlines.any(
          (i) => i.marks?.any((m) => m.markType == MarkType.bold) == true);
      _isItalic = allInlines.any(
          (i) => i.marks?.any((m) => m.markType == MarkType.italic) == true);
      _hasUnderline = allInlines.any(
          (i) => i.marks?.any((m) => m.markType == MarkType.underline) == true);
      _isStrikethrough = allInlines.any((i) =>
          i.marks?.any((m) => m.markType == MarkType.strikethrough) == true);

      TextMark? hlMark;
      for (final inline in allInlines) {
        if (inline.marks != null) {
          for (final m in inline.marks!) {
            if (m.markType == MarkType.highlight) {
              hlMark = m;
              break;
            }
          }
          if (hlMark != null) break;
        }
      }

      if (hlMark?.attrs?.color != null) {
        final c = hlMark!.attrs!.color!;
        _highlightColor = _highlightColorMap.entries
            .firstWhere(
              (e) => e.value == c,
              orElse: () => const MapEntry('none', null),
            )
            .key;
      } else {
        _highlightColor = 'none';
      }
    }
  }

  void _resetToDefaults(ThemeData theme) {
    _fontFamily = 'outfit';
    _fontSize = 13.0;
    _textColor = Colors.white;
    _highlightColor = 'none';
    _nodeBgColor = null;
    _isBold = false;
    _isItalic = false;
    _isStrikethrough = false;
    _letterCase = 'normal';
    _letterSpacing = 0.0;
    _lineHeight = 1.2;
    _hasUnderline = false;
    _underlineStyle = 'solid';
    _underlineColor = const Color(0xFF00E5FF);
    _textAlign = 'center';
    _textDirection = TextDirection.ltr;
    _nodeShape = 'rounded';
    _fillStyle = 'glass';
    _fillTint = null;
    _opacity = 85.0;
    _cornerRadius = 12.0;
    _borderWidth = 1.5;
    _borderStyle = 'solid';
    _borderOpacity = 60.0;
    _borderColor = null;
    _shadowMode = 'none';
    _shadowBlur = 14.0;
    _shadowDistance = 4.0;
    _shadowColor = null;
  }

  int _computeNodeBgColor(ThemeData theme) {
    final base = _fillTint ?? _nodeBgColor ?? theme.cardColor;
    if (_fillStyle == 'solid') {
      return base
          .withValues(alpha: (_opacity / 100).clamp(0.05, 1.0))
          .toARGB32();
    } else if (_fillStyle == 'glass') {
      return base
          .withValues(
              alpha: (0.5 * (_opacity / 100)).clamp(0.05, 0.95))
          .toARGB32();
    } else {
      return 0x00000000;
    }
  }

  int _computeNodeStrokeColor(ThemeData theme) {
    final base = _borderColor ?? theme.colorScheme.primary;
    return base
        .withValues(alpha: (_borderOpacity / 100).clamp(0.0, 1.0))
        .toARGB32();
  }

  void _resetTextFormatting(ThemeData theme) {
    setState(() {
      _fontFamily = 'outfit';
      _fontSize = 13.0;
      _textColor = Colors.white;
      _highlightColor = 'none';
      _nodeBgColor = null;
      _isBold = false;
      _isItalic = false;
      _isStrikethrough = false;
      _letterCase = 'normal';
      _letterSpacing = 0.0;
      _lineHeight = 1.2;
      _hasUnderline = false;
      _underlineStyle = 'solid';
      _underlineColor = const Color(0xFF00E5FF);
      _textAlign = 'center';
      _textDirection = TextDirection.ltr;
    });
    final rs = _getRenderState(context);
    final nodes = _getSelectedNodes(rs);
    final nodeIds = nodes.map((n) => n.id).toList();
    if (nodeIds.isNotEmpty) {
      rs.updateNodesStyle(
        nodeIds,
        (style) => style.copyWith(
          fontFamily: 'outfit',
          fontSize: 13.0,
          textColor: Colors.white.toARGB32(),
          bgColor: theme.cardColor.toARGB32(),
        ),
      );
      for (final node in nodes) {
        final resetContent = node.content.resetFormatting();
        rs.commitEntityText(node.id, resetContent);
      }
    }
  }

  void _resetBodyStyle(ThemeData theme) {
    setState(() {
      _nodeShape = 'rounded';
      _fillStyle = 'glass';
      _fillTint = null;
      _opacity = 85.0;
      _cornerRadius = 12.0;
    });
    final rs = _getRenderState(context);
    final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
    if (nodeIds.isNotEmpty) {
      final bgInt = _computeNodeBgColor(theme);
      rs.updateNodesStyle(
        nodeIds,
        (style) => style.copyWith(
          shape: 'rounded',
          borderRadius: 12.0,
          bgColor: bgInt,
        ),
      );
    }
  }

  void _resetBorder(ThemeData theme) {
    setState(() {
      _borderWidth = 1.5;
      _borderStyle = 'solid';
      _borderOpacity = 60.0;
      _borderColor = null;
    });
    final rs = _getRenderState(context);
    final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
    if (nodeIds.isNotEmpty) {
      final strokeInt = _computeNodeStrokeColor(theme);
      rs.updateNodesStyle(
        nodeIds,
        (style) => style.copyWith(
          strokeWidth: UiStrokeWidth.thick.toInt(),
          strokeColor: strokeInt,
        ),
      );
    }
  }

  void _resetShadow() {
    setState(() {
      _shadowMode = 'none';
      _shadowBlur = 14.0;
      _shadowDistance = 4.0;
      _shadowColor = null;
    });
    final rs = _getRenderState(context);
    final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
    if (nodeIds.isNotEmpty) {
      rs.updateNodesStyle(
        nodeIds,
        (style) => style.copyWith(
          shadowColor: 0x00000000,
          shadowBlur: 0.0,
          shadowOffsetY: 0.0,
          shadowOffsetX: 0.0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final effectiveRenderState = _getRenderState(context);
    final selectedNodes = _getSelectedNodes(effectiveRenderState);

    final currentSignature = selectedNodes.isEmpty
        ? '__EMPTY__'
        : selectedNodes
            .map((n) => '${n.id}_${n.style?.hashCode}_${n.content.hashCode}')
            .join(';');

    if (_lastSelectionSignature != currentSignature) {
      _lastSelectionSignature = currentSignature;
      _syncFromSelection(selectedNodes, theme);
    }

    final selectedShapeIndex = kAvailableNodeShapes
        .indexWhere((s) => s.id == _nodeShape)
        .clamp(0, kAvailableNodeShapes.length - 1);

    final badgeText =
        widget.isGlobal ? 'Global' : '${widget.selectedCount} Selected';

    return ShowcaseSectionShell(
      title: 'Node',
      icon: Icons.account_tree_rounded,
      accentColor: primaryAccent,
      badgeText: badgeText,
      showcase: NodeShowcaseCard(
        shape: _nodeShape,
        fillStyle: _fillStyle,
        opacity: _opacity,
        cornerRadius: _cornerRadius,
        borderStyle: _borderStyle,
        borderWidth: _borderWidth,
        borderOpacity: _borderOpacity,
        customBorderColor: _borderColor,
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        textAlign: _textAlign,
        highlightColor: _highlightColor,
        textColor: _textColor,
        underlineStyle: _hasUnderline ? _underlineStyle : 'none',
        underlineColor: _underlineColor,
        textDirection: _textDirection,
        isBold: _isBold,
        isItalic: _isItalic,
        isStrikethrough: _isStrikethrough,
        letterCase: _letterCase,
        letterSpacing: _letterSpacing,
        lineHeight: _lineHeight,
        customBgColor: _fillTint ?? _nodeBgColor,
        shadowMode: _shadowMode,
        shadowBlur: _shadowBlur,
        shadowDistance: _shadowDistance,
        customShadowColor: _shadowColor,
        topicText: 'Topic',
        accentColor: primaryAccent,
      ),
      child: Column(
        children: [
          NodeTypographySection(
            renderState: effectiveRenderState,
            fontFamily: _fontFamily,
            fontSize: _fontSize,
            textColor: _textColor,
            highlightColor: _highlightColor,
            nodeBgColor: _nodeBgColor,
            isBold: _isBold,
            isItalic: _isItalic,
            isStrikethrough: _isStrikethrough,
            letterCase: _letterCase,
            letterSpacing: _letterSpacing,
            lineHeight: _lineHeight,
            hasUnderline: _hasUnderline,
            underlineStyle: _underlineStyle,
            underlineColor: _underlineColor,
            textAlign: _textAlign,
            textDirection: _textDirection,
            accentColor: primaryAccent,
            onFontFamilyChanged: (v) => setState(() => _fontFamily = v),
            onFontSizeChanged: (v) => setState(() => _fontSize = v),
            onTextColorChanged: (v) => setState(() => _textColor = v),
            onHighlightColorChanged: (v) => setState(() => _highlightColor = v),
            onNodeBgColorChanged: (v) => setState(() => _nodeBgColor = v),
            onBoldToggled: () => setState(() => _isBold = !_isBold),
            onItalicToggled: () => setState(() => _isItalic = !_isItalic),
            onStrikethroughToggled: () => setState(() => _isStrikethrough = !_isStrikethrough),
            onUnderlineToggled: () => setState(() => _hasUnderline = !_hasUnderline),
            onLetterCaseChanged: (v) => setState(() => _letterCase = v),
            onTextAlignChanged: (v) => setState(() => _textAlign = v),
            onTextDirectionChanged: (v) => setState(() => _textDirection = v),
            onReset: () => _resetTextFormatting(theme),
          ),

          NodeBodyStyleSection(
            renderState: effectiveRenderState,
            nodeShape: _nodeShape,
            fillStyle: _fillStyle,
            fillTint: _fillTint,
            opacity: _opacity,
            cornerRadius: _cornerRadius,
            accentColor: primaryAccent,
            selectedShapeIndex: selectedShapeIndex,
            onShapeChanged: (v) => setState(() => _nodeShape = v),
            onFillStyleChanged: (v) => setState(() => _fillStyle = v),
            onFillTintChanged: (v) => setState(() => _fillTint = v),
            onOpacityChanged: (v) => setState(() => _opacity = v),
            onCornerRadiusChanged: (v) => setState(() => _cornerRadius = v),
            onReset: () => _resetBodyStyle(theme),
          ),

          NodeBorderSection(
            renderState: effectiveRenderState,
            borderWidth: _borderWidth,
            borderStyle: _borderStyle,
            borderOpacity: _borderOpacity,
            borderColor: _borderColor,
            accentColor: primaryAccent,
            onBorderWidthChanged: (v) => setState(() => _borderWidth = v),
            onBorderStyleChanged: (v) => setState(() => _borderStyle = v),
            onBorderOpacityChanged: (v) => setState(() => _borderOpacity = v),
            onBorderColorChanged: (v) => setState(() => _borderColor = v),
            onReset: () => _resetBorder(theme),
          ),

          NodeShadowSection(
            renderState: effectiveRenderState,
            shadowMode: _shadowMode,
            shadowBlur: _shadowBlur,
            shadowDistance: _shadowDistance,
            shadowColor: _shadowColor,
            accentColor: primaryAccent,
            onShadowModeChanged: (v) => setState(() => _shadowMode = v),
            onShadowBlurChanged: (v) => setState(() => _shadowBlur = v),
            onShadowDistanceChanged: (v) => setState(() => _shadowDistance = v),
            onShadowColorChanged: (v) => setState(() => _shadowColor = v),
            onReset: () => _resetShadow(),
          ),
        ],
      ),
    );
  }
}
