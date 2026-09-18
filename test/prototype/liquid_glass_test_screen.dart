import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

class LiquidGlassDemo extends StatefulWidget {
  const LiquidGlassDemo({super.key});

  @override
  State<LiquidGlassDemo> createState() => _LiquidGlassDemoState();
}

class _LiquidGlassDemoState extends State<LiquidGlassDemo> {
  double _refractStrength = 0.0;
  double _blurRadius = 7.0;
  double _specStrength = 2.0;
  double _blendPx = 14.0;
  double _bridgeThicknessFactor = 1.0;
  bool _useLocalCoordinates = true;
  bool _forceCpuFallback = false;

  Offset _position1 = const Offset(50, 100);
  Offset _position2 = const Offset(320, 200);
  Offset _position3 = const Offset(100, 300);
  Offset _position4 = const Offset(300, 400);

  @override
  Widget build(BuildContext context) {
    final settings = GlassSettings(
      blendPx: _blendPx,
      specAngle: 0.8,
      refractStrength: _refractStrength,
      distortFalloffPx: 35,
      blurRadiusPx: _blurRadius,
      specStrength: _specStrength,
      specWidth: 1.5,
      specPower: 4,
      bridgeThicknessFactor: _bridgeThicknessFactor,
      useLocalCoordinates: _useLocalCoordinates,
      forceCpuFallback: _forceCpuFallback,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('OC Liquid Glass Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: GlassStage(
              settings: settings,
              background: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/bg.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              child: GlassGroup(
                settings: settings,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Positioned(
                          left: _position1.dx,
                          top: _position1.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _position1 = Offset(
                                  (_position1.dx + details.delta.dx).clamp(
                                    0.0,
                                    constraints.maxWidth - 250,
                                  ),
                                  (_position1.dy + details.delta.dy).clamp(
                                    0.0,
                                    constraints.maxHeight - 80,
                                  ),
                                );
                              });
                            },
                            child: GlassPanel(
                              width: 250,
                              height: 80,
                              borderRadius: 40,
                              color: Colors.amber.withAlpha(100),
                              child: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: UiIconSize.header,
                                      ),
                                      const SizedBox(width: UiSpacing.standard),
                                      Text(
                                        'Glass Panel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: UiSpacing.standard),
                                      Icon(
                                        Icons.star,
                                        color: Colors.white,
                                        size: UiIconSize.header,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _position2.dx,
                          top: _position2.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _position2 = Offset(
                                  (_position2.dx + details.delta.dx).clamp(
                                    0.0,
                                    constraints.maxWidth - 100,
                                  ),
                                  (_position2.dy + details.delta.dy).clamp(
                                    0.0,
                                    constraints.maxHeight - 100,
                                  ),
                                );
                              });
                            },
                            child: GlassPanel(
                              width: 100,
                              height: 100,
                              borderRadius: 50,
                              color: Colors.lightGreen.withAlpha(200),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.eco,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  const SizedBox(height: UiSpacing.tight),
                                  Text(
                                    'ECO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: UiFont.header,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _position3.dx,
                          top: _position3.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _position3 = Offset(
                                  (_position3.dx + details.delta.dx).clamp(
                                    0.0,
                                    constraints.maxWidth - 80,
                                  ),
                                  (_position3.dy + details.delta.dy).clamp(
                                    0.0,
                                    constraints.maxHeight - 120,
                                  ),
                                );
                              });
                            },
                            child: GlassPanel(
                              width: 80,
                              height: 120,
                              borderRadius: 20,
                              child: const Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.pink,
                                    size: UiIconSize.header,
                                  ),
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: UiIconSize.standard,
                                  ),
                                  Icon(
                                    Icons.thumb_up,
                                    color: Colors.blue,
                                    size: UiIconSize.header,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: _position4.dx,
                          top: _position4.dy,
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setState(() {
                                _position4 = Offset(
                                  (_position4.dx + details.delta.dx).clamp(
                                    0.0,
                                    constraints.maxWidth - 60,
                                  ),
                                  (_position4.dy + details.delta.dy).clamp(
                                    0.0,
                                    constraints.maxHeight - 60,
                                  ),
                                );
                              });
                            },
                            child: GlassPanel(
                              width: 60,
                              height: 60,
                              borderRadius: 30,
                              color: Colors.black.withAlpha(150),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.nights_stay,
                                      color: Colors.white,
                                      size: UiIconSize.standard,
                                    ),
                                    Text(
                                      'DARK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: UiFont.micro,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            padding: UiInsets.container,
            child: Column(
              children: [
                Text(
                  'Refraction Strength: ${_refractStrength.toStringAsFixed(3)}',
                ),
                Slider(
                  value: _refractStrength,
                  min: -0.2,
                  max: 0.2,
                  onChanged: (value) =>
                      setState(() => _refractStrength = value),
                ),
                Text('Blur Radius: ${_blurRadius.toStringAsFixed(1)}'),
                Slider(
                  value: _blurRadius,
                  min: 0,
                  max: 20,
                  onChanged: (value) => setState(() => _blurRadius = value),
                ),
                Text('Specular Strength: ${_specStrength.toStringAsFixed(1)}'),
                Slider(
                  value: _specStrength,
                  min: 0,
                  max: 5,
                  onChanged: (value) => setState(() => _specStrength = value),
                ),
                Text('Blend Pixels: ${_blendPx.toStringAsFixed(1)}'),
                Slider(
                  value: _blendPx,
                  min: 5,
                  max: 40,
                  onChanged: (value) => setState(() => _blendPx = value),
                ),
                Text(
                  'Bridge Thickness: ${_bridgeThicknessFactor.toStringAsFixed(2)}',
                ),
                Slider(
                  value: _bridgeThicknessFactor,
                  min: 0.1,
                  max: 2.0,
                  onChanged: (value) =>
                      setState(() => _bridgeThicknessFactor = value),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Renderer coordinate system:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Row(
                      children: [
                        const Text('Skia (Global)'),
                        Switch(
                          value: _useLocalCoordinates,
                          onChanged: (value) =>
                              setState(() => _useLocalCoordinates = value),
                        ),
                        const Text('Impeller (Local)'),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Force CPU Fallback Path:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Switch(
                      value: _forceCpuFallback,
                      onChanged: (value) =>
                          setState(() => _forceCpuFallback = value),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
