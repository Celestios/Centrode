import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/unravel_slider/unravel_slider.dart';

const List<double> kPredefinedFontSizes = [
  8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 48.0,
];

/// Font size selector box that opens an UnravelSlider dropdown menu on click.
class FontSizeUnravelPicker extends StatefulWidget {
  final double fontSize;
  final ValueChanged<double> onChanged;
  final Color activeColor;

  const FontSizeUnravelPicker({
    super.key,
    required this.fontSize,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  State<FontSizeUnravelPicker> createState() => _FontSizeUnravelPickerState();
}

class _FontSizeUnravelPickerState extends State<FontSizeUnravelPicker> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _closeDropdown();
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // Full-screen barrier to dismiss on outside tap
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
              ),
            ),
            // Anchored vertical popup overlay directly underneath the 72px stepper box
            Positioned(
              width: 72,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 36),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: CentrodeDerivedPalette.of(context).surface.dialogBackground,
                      borderRadius: BorderRadius.circular(UiRadius.card),
                      border: Border.all(
                        color: widget.activeColor.withValues(alpha: 0.35),
                        width: UiStrokeWidth.subtle,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final closestIdx = _findClosestIndex(widget.fontSize);
                        return UnravelSlider<double>(
                          orientation: Axis.vertical,
                          trackHeight: constraints.maxHeight,
                          items: kPredefinedFontSizes,
                          selectedIndex: closestIdx,
                          onSelected: (idx) {
                            widget.onChanged(kPredefinedFontSizes[idx]);
                          },
                          theme: UnravelSliderThemeData(
                            accentColor: widget.activeColor,
                            cellWidth: 64.0,
                            cellHeight: 32.0,
                            trackBorderRadius: const BorderRadius.all(Radius.circular(6)),
                            handleBorderRadius: const BorderRadius.all(Radius.circular(5)),
                            trackBackgroundColor: Colors.transparent,
                          ),
                          itemBuilder: (context, item, focus, isSelected) {
                            return Center(
                              child: Text(
                                '${item.round()}',
                                style: TextStyle(
                                  fontSize: UiFont.compact + (focus * 3.0),
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                  color: isSelected
                                      ? widget.activeColor
                                      : Colors.white.withValues(alpha: 0.4 + 0.5 * focus),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(entry);
    setState(() {
      _overlayEntry = entry;
      _isOpen = true;
    });
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (_isOpen && mounted) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  int _findClosestIndex(double val) {
    int bestIdx = 0;
    double minDiff = double.infinity;
    for (int i = 0; i < kPredefinedFontSizes.length; i++) {
      final diff = (kPredefinedFontSizes[i] - val).abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        width: 72,
        height: UiControlSize.standard,
        decoration: BoxDecoration(
          color: _isOpen
              ? widget.activeColor.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(UiRadius.control),
          border: Border.all(
            color: _isOpen
                ? widget.activeColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.08),
            width: UiStrokeWidth.subtle,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleDropdown,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${widget.fontSize.round()}',
                    style: TextStyle(
                      fontSize: UiFont.standard,
                      fontWeight: FontWeight.w600,
                      color: _isOpen ? widget.activeColor : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => widget.onChanged((widget.fontSize + 1).clamp(8, 48)),
                    child: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 13,
                      color: Colors.white60,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => widget.onChanged((widget.fontSize - 1).clamp(8, 48)),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 13,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
