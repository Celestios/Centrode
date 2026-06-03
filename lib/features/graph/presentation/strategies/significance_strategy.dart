import 'package:mycelium/src/rust/domain/styles.dart' show NodeStyle;

class SignificanceStrategy {
  const SignificanceStrategy();

  /// Scales width and stroke proportionally to significance.
  /// Only applied when DisplayMode.significance is active.
  NodeStyle apply(NodeStyle base, int significance) {
    if (significance <= 0) return base;
    final scale = 1.0 + (significance * 0.05); // linear scaling example
    return base.copyWith(
      width: (base.width * scale).round(),
      height: (base.height * scale).round(),
      strokeWidth: (base.strokeWidth * scale).round(),
      fontSize: base.fontSize * scale,
    );
  }
}
