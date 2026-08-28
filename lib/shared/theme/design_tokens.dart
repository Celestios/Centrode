import 'package:flutter/widgets.dart';

/// Centralized quantized spacing tokens mapped to Centrode use cases.
abstract final class UiSpacing {
  UiSpacing._();

  /// 0.0 px - Zero spacing
  static const double none = 0.0;

  /// 4.0 px - Tight / Micro gaps, icon-to-label spacing, chip margins
  static const double tight = 4.0;

  /// 8.0 px - Standard component padding, list item gaps, control insets
  static const double standard = 8.0;

  /// 16.0 px - Container padding, card padding, modal content insets
  static const double container = 16.0;

  /// 24.0 px - Screen gutters, section separation, canvas top offsets
  static const double gutter = 24.0;
}

/// Standardized quantized EdgeInsets presets mapped to use cases.
abstract final class UiInsets {
  UiInsets._();

  /// 0.0 px
  static const EdgeInsets none = EdgeInsets.zero;

  /// 4.0 px all sides
  static const EdgeInsets tight = EdgeInsets.all(UiSpacing.tight);

  /// 8.0 px all sides
  static const EdgeInsets standard = EdgeInsets.all(UiSpacing.standard);

  /// 16.0 px all sides
  static const EdgeInsets container = EdgeInsets.all(UiSpacing.container);

  /// 24.0 px all sides
  static const EdgeInsets gutter = EdgeInsets.all(UiSpacing.gutter);

  /// Symmetric Horizontal
  static const EdgeInsets horizontalTight =
      EdgeInsets.symmetric(horizontal: UiSpacing.tight);
  static const EdgeInsets horizontalStandard =
      EdgeInsets.symmetric(horizontal: UiSpacing.standard);
  static const EdgeInsets horizontalContainer =
      EdgeInsets.symmetric(horizontal: UiSpacing.container);
  static const EdgeInsets horizontalGutter =
      EdgeInsets.symmetric(horizontal: UiSpacing.gutter);

  /// Symmetric Vertical
  static const EdgeInsets verticalTight =
      EdgeInsets.symmetric(vertical: UiSpacing.tight);
  static const EdgeInsets verticalStandard =
      EdgeInsets.symmetric(vertical: UiSpacing.standard);
  static const EdgeInsets verticalContainer =
      EdgeInsets.symmetric(vertical: UiSpacing.container);
  static const EdgeInsets verticalGutter =
      EdgeInsets.symmetric(vertical: UiSpacing.gutter);

  /// Common Control Combinations
  static const EdgeInsets control = EdgeInsets.symmetric(
    horizontal: UiSpacing.standard,
    vertical: UiSpacing.tight,
  );
  static const EdgeInsets button = EdgeInsets.symmetric(
    horizontal: UiSpacing.container,
    vertical: UiSpacing.standard,
  );
  static const EdgeInsets denseButton = EdgeInsets.symmetric(
    horizontal: UiSpacing.standard,
    vertical: UiSpacing.tight,
  );
}

/// Centralized corner radius tokens mapped to UI component tiers.
abstract final class UiRadius {
  UiRadius._();

  /// 0.0 px - Sharp rectangular corners
  static const double none = 0.0;

  /// 6.0 px - Form controls, compact buttons, sliders, input fields, badges
  static const double control = 6.0;

  /// 8.0 px - Standard cards, dropdown menus, default node corners
  static const double card = 8.0;

  /// 16.0 px - Floating glass panels, modals, dialogs, drawer shells
  static const double panel = 16.0;

  /// 999.0 px - Stadium capsules, pill buttons, circular badges
  static const double pill = 999.0;
}

/// Centralized icon sizing tokens mapped to visual density tiers.
abstract final class UiIconSize {
  UiIconSize._();

  /// 14.0 px - Dense toolbars, micro indicators, list icons, close badges
  static const double dense = 14.0;

  /// 18.0 px - Standard action buttons, menu icons, title bar tools
  static const double standard = 18.0;

  /// 24.0 px - Modal headers, primary action triggers, hero icons
  static const double header = 24.0;
}

/// Centralized control heights mapped to interactive component tiers.
abstract final class UiControlSize {
  UiControlSize._();

  /// 26.0 px - Inspector swatches, dense toggles, micro groups
  static const double dense = 26.0;

  /// 32.0 px - Standard inputs, dropdowns, buttons, tool items
  static const double standard = 32.0;

  /// 40.0 px - Floating action bars, window title bars, large tiles
  static const double tile = 40.0;
}

/// Centralized stroke widths mapped to visual hierarchy.
abstract final class UiStrokeWidth {
  UiStrokeWidth._();

  /// 0.8 px - Subtle frosted glass border, sub-block dividers
  static const double subtle = 0.8;

  /// 1.0 px - Standard outlines, dividers, chip borders
  static const double standard = 1.0;

  /// 2.0 px - Active selection borders, focus outlines, editing stroke
  static const double thick = 2.0;
}

/// Centralized typography scale mapped to hierarchy tiers.
abstract final class UiFont {
  UiFont._();

  /// 10.0 px - Micro labels, date stamps, tiny badge indicators
  static const double micro = 10.0;

  /// 11.0 px - Compact hints, dense property rows, sub-labels
  static const double compact = 11.0;

  /// 12.0 px - Standard body text, button labels, input contents
  static const double standard = 12.0;

  /// 14.0 px - Section titles, modal headers, primary form labels
  static const double header = 14.0;

  /// 16.0 px - Dialog titles, card titles, main headings
  static const double title = 16.0;
}

/// Centralized alpha & opacity tokens mapped to visual hierarchy.
abstract final class UiAlpha {
  UiAlpha._();

  /// 0.05 - Faint hover overlay, subtle backdrop tint
  static const double micro = 0.05;

  /// 0.08 - Standard hover highlight, container fill tint, inactive tracks
  static const double subtle = 0.08;

  /// 0.10 - Container background wash, subtle chip background
  static const double wash = 0.10;

  /// 0.12 - Selection fill, badge background, soft mask
  static const double tint = 0.12;

  /// 0.18 - Subtle border framing, hover-scale border
  static const double borderSubtle = 0.18;

  /// 0.25 - Minimap lens, active chip fill, secondary borders
  static const double medium = 0.25;

  /// 0.35 - Active borders, focused glow, text selection
  static const double borderStrong = 0.35;

  /// 0.50 - Secondary indicators, disabled icons, backdrop shadow
  static const double half = 0.50;

  /// 0.65 - Connection lines, secondary labels, metadata text
  static const double muted = 0.65;

  /// 0.85 - Strong borders, primary glass body, elevated cards
  static const double glassBody = 0.85;

  /// 0.95 - Opaque glass header, pinned toolbar shells
  static const double glassHeader = 0.95;

  /// 1.00 - Fully opaque
  static const double opaque = 1.0;
}

/// Centralized motion & animation parameters.
abstract final class UiMotion {
  UiMotion._();

  /// Unified hover scale factor for interactive buttons and tiles
  static const double hoverScale = 1.05;

  /// Unified press scale factor for interactive buttons and tiles
  static const double pressScale = 0.95;

  /// Fast feedback animation duration (100ms: hover, click response)
  static const Duration fast = Duration(milliseconds: 100);

  /// Standard component transition duration (200ms: modal open, drawer slide)
  static const Duration standard = Duration(milliseconds: 200);
}

/// Canvas-specific layout constants mapped to graph engine use cases.
abstract final class CanvasTokens {
  CanvasTokens._();

  // Grid & Scaling
  static const double gridBase = 20.0;
  static const double gridDotRadius = 1.5;
  static const double referenceFontSize = 14.0;
  static double fontScale(double fontSize) => fontSize / referenceFontSize;

  // Node Bounds & Constraints
  static const double nodeDefaultWidth = 80.0;
  static const double nodeMinWidth = 60.0;
  static const double nodeMaxWidth = 640.0;
  static const double autoWrapThreshold = 310.0;
  static const double edgeResizeHitbox = 16.0;

  // Handles & Hitboxes
  static const double handleWidth = 5.0;
  static const double handleLength = 22.0;
  static const double handleTopOffset = UiSpacing.gutter;
  static const double portDrawRadius = 4.0;
  static const double portHoverRadius = 6.0;
  static const double portHitRadius = 20.0;

  // Expand Toggle
  static const double expandButtonHeight = 16.0;
  static const double expandIconSize = 12.0;
}

/// Workspace-specific layout constants mapped to workspace hub use cases.
abstract final class WorkspaceTokens {
  WorkspaceTokens._();

  static const double leftPanelWidth = 200.0;
  static const double topBarHeight = 48.0;
  static const double cardWidth = 184.0;
  static const double cardHeight = 160.0;
  static const double cardSpacing = 12.0;
}
