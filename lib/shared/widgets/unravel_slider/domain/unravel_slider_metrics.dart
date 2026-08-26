import 'dart:math' as math;

/// Immutable, pure mathematical metrics and layout engine for [UnravelSlider].
///
/// Encapsulates the non-linear sigmoid/logit unravelling mathematics,
/// caching anchor value vectors to minimize per-frame computational overhead.
class UnravelSliderMetrics {
  final double trackWidth;
  final int itemCount;
  final double cellWidth;
  final double cellHeight;
  final double clearanceMargin;

  // Cached anchor value array in domain space
  final List<double> _optionValues;

  UnravelSliderMetrics._({
    required this.trackWidth,
    required this.itemCount,
    required this.cellWidth,
    required this.cellHeight,
    required this.clearanceMargin,
    required List<double> optionValues,
  }) : _optionValues = optionValues;

  factory UnravelSliderMetrics({
    required double trackWidth,
    required int itemCount,
    double cellWidth = 82.8,
    double cellHeight = 55.2,
    double clearanceMargin = 15.2,
  }) {
    final handleBoxW = cellWidth * 0.72;
    final margin = (handleBoxW / 2.0) + clearanceMargin;
    final handleTravel = math.max(10.0, trackWidth - 2.0 * margin);
    final sigma = handleTravel;
    const unitsPerPx = 32.0 / 7.0;

    final n = math.max(1, itemCount);
    final values = List<double>.generate(n, (i) {
      if (n <= 1) return 0.0;
      final anchorU = handleTravel * i / (n - 1);
      final p = (margin + anchorU) / trackWidth;
      // Clamp p safely inside (0, 1) to avoid logit infinity
      final clampedP = p.clamp(0.001, 0.999);
      final logitP = math.log(clampedP / (1.0 - clampedP));
      return unitsPerPx * anchorU + sigma * logitP;
    }, growable: false);

    return UnravelSliderMetrics._(
      trackWidth: trackWidth,
      itemCount: n,
      cellWidth: cellWidth,
      cellHeight: cellHeight,
      clearanceMargin: clearanceMargin,
      optionValues: values,
    );
  }

  double get handleBoxWidth => cellWidth * 0.72;
  double get margin => (handleBoxWidth / 2.0) + clearanceMargin;
  double get handleTravel => math.max(10.0, trackWidth - 2.0 * margin);
  double get sigma => handleTravel;
  double get unitsPerPx => 32.0 / 7.0;
  double get valueMax => sigma * unitsPerPx;
  double get trackHeight => cellHeight + 24.0;
  double get focusRadius => handleBoxWidth * 1.15;

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

  /// Calculates visual screen X coordinates for all items given current travel `u`.
  List<double> computeXs(double u) {
    final value = u * unitsPerPx;
    final s = sigma;
    final w = trackWidth;
    final n = _optionValues.length;

    final xs = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      final z = (_optionValues[i] - value) / s;
      final sigmoidZ = 1.0 / (1.0 + math.exp(-z));
      xs[i] = w * sigmoidZ;
    }
    return xs;
  }

  /// Computes the spatial focus [0.0, 1.0] of an item given its screen [itemX]
  /// and current [handleCenter].
  double spatialFocus(double itemX, double handleCenter) {
    final d = (itemX - handleCenter).abs();
    return (1.0 - d / focusRadius).clamp(0.0, 1.0);
  }

  /// Finds the index of the item closest to [handleCenter].
  int nearestIndex(double handleCenter, List<double> xs) {
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < xs.length; i++) {
      final d = (xs[i] - handleCenter).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  /// Finds the item index hit by a local coordinate tap [localX].
  /// Resolves compressed tail overlaps by selecting the item closest to [localX].
  int hitTest(double localX, List<double> xs) {
    final halfW = cellWidth / 2.0;
    var best = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < xs.length; i++) {
      final d = (localX - xs[i]).abs();
      if (d <= halfW && d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }
}
