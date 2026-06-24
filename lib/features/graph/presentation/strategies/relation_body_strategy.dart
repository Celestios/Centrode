import 'dart:math';

abstract class RelationBodyStrategy {
  const RelationBodyStrategy();

  factory RelationBodyStrategy.fromType(String type) {
    switch (type) {
      case 'taper':
        return const TaperRelationBodyStrategy(startWidth: 0, endWidth: 0);
      case 'widthModulate':
        return const WidthModulateRelationBodyStrategy(amplitude: 0, frequency: 0);
      default:
        return const NoneRelationBodyStrategy();
    }
  }

  double widthAt(double t, double baseWidth);
}

class NoneRelationBodyStrategy extends RelationBodyStrategy {
  const NoneRelationBodyStrategy();

  @override
  double widthAt(double t, double baseWidth) => baseWidth;
}

class TaperRelationBodyStrategy extends RelationBodyStrategy {
  final double startWidth;
  final double endWidth;

  const TaperRelationBodyStrategy({required this.startWidth, required this.endWidth});

  @override
  double widthAt(double t, double baseWidth) {
    return startWidth + (endWidth - startWidth) * t;
  }
}

class WidthModulateRelationBodyStrategy extends RelationBodyStrategy {
  final double amplitude;
  final double frequency;

  const WidthModulateRelationBodyStrategy({required this.amplitude, required this.frequency});

  @override
  double widthAt(double t, double baseWidth) {
    return baseWidth + amplitude * sin(t * frequency * 2 * pi);
  }
}
