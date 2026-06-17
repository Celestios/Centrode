import 'package:mycelium/src/rust/domain/styles.dart' show NodeStyle;

class SignificanceStrategy {
  const SignificanceStrategy();

  /// Scales fontSize proportionally to significance.
  /// Node dimensions are recalculated by the layout engine from the scaled fontSize.
  /// Only applied when DisplayMode.importance is active.
  NodeStyle apply(NodeStyle base, int significance) {
    if (significance <= 0) return base;
    final scaledFontSize = base.fontSize * (1.0 + significance * 0.20);
    return base.copyWith(
      fontSize: scaledFontSize,
    );
  }
}
