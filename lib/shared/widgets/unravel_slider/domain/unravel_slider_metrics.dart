import 'dart:math' as math;

/// Immutable, pure mathematical metrics and layout engine for [UnravelSlider].
///
/// Encapsulates the non-linear sigmoid/logit unravelling mathematics,
/// caching anchor value vectors to minimize per-frame computational overhead.
class UnravelSliderMetrics {
  final double trackExtent;
  final int itemCount;
  final double mainCellExtent;
  final double crossCellExtent;
  final double clearanceMargin;

  // Cached anchor value array in domain space
  final List<double> _optionValues;

  UnravelSliderMetrics._({
    required this.trackExtent,
    required this.itemCount,
    required this.mainCellExtent,
    required this.crossCellExtent,
    required this.clearanceMargin,
    required List<double> optionValues,
  }) : _optionValues = optionValues;

  factory UnravelSliderMetrics({
    double? trackExtent,
    double? trackWidth,
    required int itemCount,
    double? mainCellExtent,
    double cellWidth = 82.8,
    double? crossCellExtent,
    double cellHeight = 55.2,
    double? clearanceMargin,
  }) {
    final extent = trackExtent ?? trackWidth ?? 230.0;
    final mainCell = mainCellExtent ?? cellWidth;
    final crossCell = crossCellExtent ?? cellHeight;
    final clearance = clearanceMargin ?? 2.0;

    final handleBox = mainCell * 0.88;
    final margin = (handleBox / 2.0) + clearance;
    final handleTravel = math.max(10.0, extent - 2.0 * margin);
    final sigma = handleTravel;
    const unitsPerPx = 32.0 / 7.0;

    final n = math.max(1, itemCount);
    final values = List<double>.generate(n, (i) {
      if (n <= 1) return 0.0;
      final anchorU = handleTravel * i / (n - 1);
      final p = (margin + anchorU) / extent;
      // Clamp p safely inside (0.0001, 0.9999) to avoid logit infinity
      final clampedP = p.clamp(0.0001, 0.9999);
      final logitP = math.log(clampedP / (1.0 - clampedP));
      return unitsPerPx * anchorU + sigma * logitP;
    }, growable: false);

    return UnravelSliderMetrics._(
      trackExtent: extent,
      itemCount: n,
      mainCellExtent: mainCell,
      crossCellExtent: crossCell,
      clearanceMargin: clearance,
      optionValues: values,
    );
  }

  double get handleBoxExtent => mainCellExtent * 0.88;
  double get handleBoxWidth => handleBoxExtent;
  double get margin => (handleBoxExtent / 2.0) + clearanceMargin;
  double get handleTravel => math.max(10.0, trackExtent - 2.0 * margin);
  double get sigma => handleTravel;
  double get unitsPerPx => 32.0 / 7.0;

  double get trackWidth => trackExtent;
  double get cellWidth => mainCellExtent;
  double get cellHeight => crossCellExtent;
  double get trackHeight => crossCellExtent;
  double get valueMax => sigma * unitsPerPx;
  double get focusRadius => handleBoxExtent * 1.15;

  /// Returns the anchor position in pixels `u` for item [index].
  double anchorU(int index) {
    if (itemCount <= 1) return 0.0;
    final clamped = index.clamp(0, itemCount - 1);
    return handleTravel * clamped / (itemCount - 1);
  }

  /// Snaps arbitrary raw travel offset `rawU` to the nearest item anchor.
  double snapU(double rawU) {
    if (itemCount <= 1) return 0.0;
    final step = handleTravel / (itemCount - 1);
    final index = (rawU / step).round().clamp(0, itemCount - 1);
    return index * step;
  }

  /// Calculates visual coordinates for all items given current travel `u`.
  List<double> computePositions(double u) {
    final value = u * unitsPerPx;
    final s = sigma;
    final w = trackExtent;
    final n = _optionValues.length;

    final pos = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      final z = (_optionValues[i] - value) / s;
      final sigmoidZ = 1.0 / (1.0 + math.exp(-z));
      pos[i] = w * sigmoidZ;
    }
    return pos;
  }

  /// Computes the spatial focus [0.0, 1.0] of an item given its screen position
  /// and current [handleCenter].
  double spatialFocus(double itemPos, double handleCenter) {
    final d = (itemPos - handleCenter).abs();
    return (1.0 - d / focusRadius).clamp(0.0, 1.0);
  }

  /// Finds the index of the item closest to [handleCenter].
  int nearestIndex(double handleCenter, List<double> positions) {
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < positions.length; i++) {
      final d = (positions[i] - handleCenter).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  /// Finds the item index hit by a local coordinate tap [localPos].
  int hitTest(double localPos, List<double> positions) {
    final halfExtent = mainCellExtent / 2.0;
    var best = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < positions.length; i++) {
      final d = (localPos - positions[i]).abs();
      if (d <= halfExtent && d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }
}
