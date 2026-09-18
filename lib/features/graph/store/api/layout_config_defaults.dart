import 'package:centrode/src/rust/layout_engine/config.dart';

LayoutConfig defaultLayoutConfig() => const LayoutConfig(
  force: ForceConfig(
    repulsionConstant: 8000.0,
    springConstant: 0.06,
    idealLinkDistance: 220.0,
    collisionStrength: 1.2,
    baseMargin: 35.0,
    marginScale: 0.2,
    wallStrength: 1.2,
    wallPadding: 20.0,
    damping: 0.35,
    alphaDecay: 0.006,
    alphaMin: 0.001,
    relationStretchFactor: 0.5,
    nodeEdgeRepulsion: 1500.0,
    densityDispersionStrength: 300.0,
  ),
  convergence: ConvergenceCriteria(
    maxIterations: 600,
    energyThreshold: 0.005,
    displacementThreshold: 0.2,
    oscillationWindow: 10,
  ),
  batchSize: 1,
);
