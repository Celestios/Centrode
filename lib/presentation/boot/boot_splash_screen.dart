import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:centrode/infrastructure/bootstrap/app_bootstrap.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Gate widget owning the boot sequence, showing the branded splash until
/// [child] can be presented.
class BootSplashScreen extends StatefulWidget {
  const BootSplashScreen({super.key, required this.child});

  final Widget child;

  @override
  State<BootSplashScreen> createState() => _BootSplashScreenState();
}

class _BootSplashScreenState extends State<BootSplashScreen> {
  bool _ready = false;
  String _stage = 'Starting Centrode...';

  @override
  void initState() {
    super.initState();
    unawaited(_boot());
  }

  Future<void> _boot() async {
    await AppBootstrap.initializeBackgroundServices((stage) {
      if (mounted) setState(() => _stage = stage);
    });

    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

    if (isDesktop) {
      await windowManager.hide();
      await windowManager.setSize(AppBootstrap.defaultWindowSize);
      await windowManager.setMinimumSize(const Size(960, 600));
      await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
      await windowManager.setHasShadow(true);
      await windowManager.center();
    }

    if (mounted) setState(() => _ready = true);

    if (isDesktop) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ready
        ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
        : BootSplashView(key: const ValueKey('splash'), stage: _stage);
  }
}

/// Launch view filling the frameless launch window, matching the original
/// splash design.
class BootSplashView extends StatefulWidget {
  const BootSplashView({super.key, required this.stage});

  final String stage;

  @override
  State<BootSplashView> createState() => _BootSplashViewState();
}

class _BootSplashViewState extends State<BootSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = AppThemeManager.instance.currentTheme.canvasAccentColor;
    final appVersion = const String.fromEnvironment('FLUTTER_BUILD_NAME');

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF0A0A0A)),
            Image.asset(
              'assets/splash_bg.png',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'CENTRODE',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 7.0,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: accentColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'The Central Hub for Your Life',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.6,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _BootProgressBar(controller: _shimmer, accentColor: accentColor),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _stageText,
                        key: ValueKey(_stageText),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.4,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Text(
                appVersion.isEmpty
                    ? 'Offline First Knowledge Network'
                    : 'v$appVersion • Offline First Knowledge Network',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _stageText =>
      widget.stage.isEmpty ? 'Starting Centrode...' : widget.stage;
}

class _BootProgressBar extends StatelessWidget {
  const _BootProgressBar({required this.controller, required this.accentColor});

  final Animation<double> controller;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    const trackWidth = 180.0;
    const trackHeight = 4.0;

    return SizedBox(
      width: trackWidth,
      height: trackHeight,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BootProgressPainter(controller.value, accentColor),
          );
        },
      ),
    );
  }
}

class _BootProgressPainter extends CustomPainter {
  _BootProgressPainter(this.phase, this.accentColor);

  final double phase;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final trackRadius = Radius.circular(size.height / 2);
    final trackRRect =
        RRect.fromRectAndRadius(Offset.zero & size, trackRadius);

    canvas.drawRRect(trackRRect,
        Paint()..color = Colors.white.withValues(alpha: 38 / 255));

    const sweep = 0.45;
    final t = (phase % 1.0) * 2 * math.pi;
    final eased = (1 - math.cos(t)) / 2;
    final center = size.width * eased;

    canvas.save();
    canvas.clipRRect(trackRRect);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center, size.height / 2),
        width: size.width * sweep,
        height: size.height,
      ),
      Paint()..color = accentColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BootProgressPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.accentColor != accentColor;
}
