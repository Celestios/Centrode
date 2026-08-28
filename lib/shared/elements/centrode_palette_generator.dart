import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';
import 'package:centrode/shared/utils/geometry/polyomino.dart';
import 'package:centrode/shared/utils/palette_layout.dart';

final _log = Logger('CentrodePaletteGenerator');

/// Interlocking Polyomino Puzzle Mosaic Generative Palette Explorer.
///
/// Divides the area into fine calculation tiles, grows 5 contiguous globular color regions,
/// and renders each region as a unified interlocking puzzle piece with smooth
/// rounded outer boundary corners, separation gaps, and in-tile controls.
class CentrodePaletteGenerator extends StatefulWidget {
  /// Base primary anchor color from active theme or selection.
  final Color? primaryAnchor;

  /// Initial list of 5 colors (optional).
  final List<Color>? initialPalette;

  /// Callback when a generated palette is applied or accepted.
  final ValueChanged<List<Color>>? onApplyPalette;

  /// Callback when an individual color is clicked.
  final ValueChanged<Color>? onColorSelected;

  /// Optional callback when close button is clicked.
  final VoidCallback? onClose;

  const CentrodePaletteGenerator({
    super.key,
    this.primaryAnchor,
    this.initialPalette,
    this.onApplyPalette,
    this.onColorSelected,
    this.onClose,
  });

  @override
  State<CentrodePaletteGenerator> createState() => _CentrodePaletteGeneratorState();
}

class _CentrodePaletteGeneratorState extends State<CentrodePaletteGenerator> {
  static const int kGridCols = 12;
  static const int kGridRows = 8;
  static const int kColorCount = 5;

  late List<Color> _palette;
  late List<bool> _lockedSlots;
  late List<List<int>> _grid; // grid[col][row] in 0..4
  bool _gridInitialized = false;
  PaletteMood _activeMood = PaletteMood.auto;
  final FocusNode _focusNode = FocusNode();
  int? _hoveredIndex;

  @override
  void initState() {
    super.initState();
    _lockedSlots = List.filled(kColorCount, false);

    if (widget.initialPalette != null && widget.initialPalette!.length == kColorCount) {
      _palette = List<Color>.from(widget.initialPalette!);
    } else {
      _palette = ColorTheoryEngine.generateThemedExplorationPalette(
        primaryAnchor: widget.primaryAnchor ?? const Color(0xFF6366F1),
        mood: _activeMood,
        count: kColorCount,
      );
    }
    _generatePuzzleGrid();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Generates the 5-color interlocking region grid, delegating the
  /// seed-sampled Voronoi layout to [generatePaletteGrid]. Locked colors keep
  /// their exact previous cells (their shape), and only unlocked cells are
  /// re-partitioned.
  void _generatePuzzleGrid() {
    _grid = generatePaletteGrid(
      cols: kGridCols,
      rows: kGridRows,
      colorCount: kColorCount,
      lockedSlots: _lockedSlots,
      previousGrid: _gridInitialized ? _grid : null,
    );
    _gridInitialized = true;
    _log.fine('Puzzle grid generated');
  }

  void _generateNewPalette() {
    setState(() {
      _palette = ColorTheoryEngine.generateThemedExplorationPalette(
        primaryAnchor: widget.primaryAnchor ?? _palette[1],
        existingPalette: _palette,
        lockedSlots: _lockedSlots,
        mood: _activeMood,
        count: kColorCount,
      );
      _generatePuzzleGrid();
    });
  }

  void _toggleLock(int index) {
    setState(() {
      _lockedSlots[index] = !_lockedSlots[index];
    });
  }

  Future<void> _copyHex(Color color) async {
    final hex = ColorTheoryEngine.toHex(color);
    await Clipboard.setData(ClipboardData(text: hex));
  }

  String _getColorName(Color color, int index) {
    final oklch = OklchColor.fromColor(color);
    if (oklch.l < 0.35) return 'Deep Foundation';
    if (oklch.l > 0.85) return 'High-Key Pastel';
    if (oklch.c > 0.18) return 'Vivid Accent';
    if (index == 1) return 'Primary Iris';
    return 'Harmonic Tone';
  }

  /// Label anchors for each color region: pole of inaccessibility (deepest
  /// interior cell via BFS distance field) refined by a depth-weighted centroid
  /// with outlier trimming, so tags never float on an arm or outside the piece.
  /// Delegates to [computeRegionAnchors].
  List<Offset> _computeVisualCenters(Size size) =>
      computeRegionAnchors(_grid, kGridCols, kGridRows, kColorCount, size);

  /// Builds a single, gap-inset, smooth rounded vector outline for each color
  /// piece (convex *and* concave corners traced as one clean contour).
  /// Delegates to [computeRegionOutlines].
  List<Path> _computeShapePaths(Size size) =>
      computeRegionOutlines(_grid, kGridCols, kGridRows, kColorCount, size);

  // Region geometry (boundary tracing, inset, rounding, anchors) now lives in
  // package:centrode/shared/utils/geometry/polyomino.dart.

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = palette.surface.panelBackground;
    final cardBg = palette.surface.cardBackground;
    final borderSubtle = palette.border(Theme.of(context).dividerColor);

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
          _generateNewPalette();
        }
      },
      child: Container(
        width: 620,
        decoration: BoxDecoration(
          color: panelBg,
          borderRadius: BorderRadius.circular(UiRadius.panel),
          border: Border.all(color: borderSubtle, width: UiStrokeWidth.standard),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.70 : 0.25),
              blurRadius: 32,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Top Navigation Bar
            _buildTopBar(cardBg, borderSubtle),

            // 2. Interlocking Big Color Shapes Stage with Smooth Rounded Contours
            _buildPuzzleMosaicStage(),

            // 3. Bottom Harmony Mood Selector Bar
            _buildHarmonyFooter(cardBg, borderSubtle),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color cardBg, Color borderSubtle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderSubtle, width: UiStrokeWidth.subtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(UiRadius.pill),
              border: Border.all(color: borderSubtle, width: UiStrokeWidth.subtle),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Press ', style: TextStyle(fontSize: UiFont.compact, color: Colors.white70)),
                Text(
                  'SPACE',
                  style: TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(' to explore', style: TextStyle(fontSize: UiFont.compact, color: Colors.white70)),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: _generateNewPalette,
                    icon: const Icon(Icons.casino_outlined, size: UiIconSize.dense),
                    label: const Text('Re-roll'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                  ),
                  const SizedBox(width: UiSpacing.tight),
                  ElevatedButton.icon(
                    onPressed: () => widget.onApplyPalette?.call(_palette),
                    icon: const Icon(Icons.check_rounded, size: UiIconSize.dense),
                    label: const Text('Apply Palette'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                  ),
                  if (widget.onClose != null) ...[
                    const SizedBox(width: UiSpacing.tight),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: UiIconSize.standard,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: widget.onClose,
                      tooltip: 'Close',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzleMosaicStage() {
    return Container(
      padding: const EdgeInsets.all(12),
      height: 310,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final shapePaths = _computeShapePaths(size);
          final visualCenters = _computeVisualCenters(size);

          return MouseRegion(
            onHover: (event) {
              final pos = event.localPosition;
              int? found;
              for (int i = 0; i < kColorCount; i++) {
                if (shapePaths[i].contains(pos)) {
                  found = i;
                  break;
                }
              }
              if (_hoveredIndex != found) {
                setState(() => _hoveredIndex = found);
              }
            },
            onExit: (_) {
              if (_hoveredIndex != null) {
                setState(() => _hoveredIndex = null);
              }
            },
            child: GestureDetector(
              onTapUp: (details) {
                final pos = details.localPosition;
                for (int i = 0; i < kColorCount; i++) {
                  if (shapePaths[i].contains(pos)) {
                    widget.onColorSelected?.call(_palette[i]);
                    break;
                  }
                }
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Unified Interlocking Polyomino Mosaic Painter
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PuzzleMosaicPainter(
                        shapePaths: shapePaths,
                        palette: _palette,
                        lockedSlots: _lockedSlots,
                        hoveredIndex: _hoveredIndex,
                      ),
                    ),
                  ),

                  // 2. Direct In-Tile Controls positioned on visual interior centers
                  ...List.generate(kColorCount, (colorIdx) {
                    final color = _palette[colorIdx];
                    final isLocked = _lockedSlots[colorIdx];
                    final textColor = ColorTheoryEngine.bestContrastingTextColor(color);
                    final hexString = ColorTheoryEngine.toHex(color);
                    final colorName = _getColorName(color, colorIdx);
                    final center = visualCenters[colorIdx];

                    const w = 98.0;
                    const h = 40.0;
                    final posX = (center.dx - (w / 2)).clamp(6.0, size.width - w - 6.0);
                    final posY = (center.dy - (h / 2)).clamp(6.0, size.height - h - 6.0);

                    return Positioned(
                      left: posX,
                      top: posY,
                      width: w,
                      height: h,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  hexString,
                                  style: TextStyle(
                                    fontFamily: 'Consolas',
                                    fontWeight: FontWeight.w800,
                                    fontSize: UiFont.compact,
                                    color: textColor,
                                    shadows: const [
                                      Shadow(color: Colors.black54, blurRadius: 4),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleLock(colorIdx),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isLocked ? Colors.white : Colors.black45,
                                    borderRadius: BorderRadius.circular(UiRadius.pill),
                                    border: Border.all(
                                      color: isLocked ? Colors.white : Colors.white24,
                                      width: UiStrokeWidth.subtle,
                                    ),
                                  ),
                                  child: Icon(
                                    isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                                    size: 11,
                                    color: isLocked ? Colors.black : Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  colorName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: textColor.withValues(alpha: 0.88),
                                    shadows: const [
                                      Shadow(color: Colors.black38, blurRadius: 2),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 3),
                              GestureDetector(
                                onTap: () => _copyHex(color),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white24,
                                      width: UiStrokeWidth.subtle,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHarmonyFooter(Color cardBg, Color borderSubtle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(top: BorderSide(color: borderSubtle, width: UiStrokeWidth.subtle)),
      ),
      child: Row(
        children: [
          const Text(
            'HARMONY:',
            style: TextStyle(
              fontSize: UiFont.micro,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: Colors.white54,
            ),
          ),
          const SizedBox(width: UiSpacing.standard),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: PaletteMood.values.map((mood) {
                  final isSelected = mood == _activeMood;
                  final label = switch (mood) {
                    PaletteMood.auto => '1-3-1 Auto',
                    PaletteMood.vibrant => 'Vibrant',
                    PaletteMood.pastel => 'Pastel',
                    PaletteMood.deep => 'Deep',
                    PaletteMood.warm => 'Warm',
                    PaletteMood.cool => 'Cool',
                    PaletteMood.neon => 'Neon',
                  };

                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) {
                          setState(() => _activeMood = mood);
                          _generateNewPalette();
                        }
                      },
                      visualDensity: VisualDensity.compact,
                      labelStyle: TextStyle(
                        fontSize: UiFont.compact,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Puzzle Mosaic Painter: High-performance renderer for precomputed polyomino paths
// -----------------------------------------------------------------------------

class _PuzzleMosaicPainter extends CustomPainter {
  final List<Path> shapePaths;
  final List<Color> palette;
  final List<bool> lockedSlots;
  final int? hoveredIndex;

  const _PuzzleMosaicPainter({
    required this.shapePaths,
    required this.palette,
    required this.lockedSlots,
    required this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < shapePaths.length; i++) {
      final path = shapePaths[i];
      final color = palette[i];
      final isLocked = lockedSlots[i];
      final isHovered = hoveredIndex == i;

      // 1. Ambient Drop Shadow
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: isHovered ? 0.60 : 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isHovered ? 8.0 : 4.0);
      canvas.drawPath(path.shift(const Offset(0, 3)), shadowPaint);

      // 2. Solid Color Fill (single traced contour — no interior edges)
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // 3. Subtle Smooth Boundary Stroke
      final borderPaint = Paint()
        ..color = isLocked
            ? Colors.white
            : (isHovered ? Colors.white70 : Colors.white24)
        ..strokeWidth = isLocked ? 2.0 : (isHovered ? 1.5 : UiStrokeWidth.subtle)
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PuzzleMosaicPainter oldDelegate) {
    return oldDelegate.palette != palette ||
        oldDelegate.lockedSlots != lockedSlots ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.shapePaths != shapePaths;
  }
}
