part of 'liquid_glass_menu.dart';

/// Renders a backdrop separately from glass controls so Skia can sample the
/// background without recursively capturing the glass itself.
class LiquidGlassStage extends StatefulWidget {
  final LiquidGlassSettings settings;
  final Widget background;
  final Widget child;
  final Listenable? repaint;
  final Listenable? backdropRepaint;

  const LiquidGlassStage({
    super.key,
    required this.settings,
    required this.background,
    required this.child,
    this.repaint,
    this.backdropRepaint,
  });

  @override
  State<LiquidGlassStage> createState() => _LiquidGlassStageState();
}

class _LiquidGlassStageState extends State<LiquidGlassStage> {
  static const int _initialWarmupCaptures = 6;

  final GlobalKey _backgroundKey = GlobalKey();
  ui.Image? _backdropImage;
  Size? _backdropLogicalSize;
  bool _captureScheduled = false;
  int _captureSerial = 0;
  int _warmupCapturesRemaining = 0;
  double? _lastDevicePixelRatio;

  @override
  void initState() {
    super.initState();
    widget.backdropRepaint?.addListener(_handleBackdropChanged);
    _scheduleCapture(warmupCaptures: _initialWarmupCaptures);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    if (_lastDevicePixelRatio != dpr) {
      _lastDevicePixelRatio = dpr;
      _scheduleCapture(warmupCaptures: _initialWarmupCaptures);
    }
  }

  @override
  void didUpdateWidget(LiquidGlassStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backdropRepaint != widget.backdropRepaint) {
      oldWidget.backdropRepaint?.removeListener(_handleBackdropChanged);
      widget.backdropRepaint?.addListener(_handleBackdropChanged);
    }
    if (oldWidget.background != widget.background) {
      _scheduleCapture(warmupCaptures: _initialWarmupCaptures);
    }
  }

  @override
  void dispose() {
    widget.backdropRepaint?.removeListener(_handleBackdropChanged);
    _captureSerial++;
    _backdropImage?.dispose();
    super.dispose();
  }

  void _handleBackdropChanged() {
    _scheduleCapture();
  }

  void _scheduleCapture({int warmupCaptures = 0}) {
    if (ui.ImageFilter.isShaderFilterSupported) return;
    if (warmupCaptures > _warmupCapturesRemaining) {
      _warmupCapturesRemaining = warmupCaptures;
    }
    if (_captureScheduled) return;

    _captureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureScheduled = false;
      unawaited(_captureBackdrop());
    });
  }

  Future<void> _captureBackdrop() async {
    if (ui.ImageFilter.isShaderFilterSupported) return;
    if (!mounted) return;

    final boundaryContext = _backgroundKey.currentContext;
    final renderObject = boundaryContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return;
    }

    if (renderObject.debugNeedsPaint) {
      _scheduleCapture();
      return;
    }

    final logicalSize = renderObject.size;
    if (logicalSize.isEmpty) return;

    final pixelRatio = math.min(1.5, MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0);
    final serial = ++_captureSerial;

    try {
      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      if (!mounted || serial != _captureSerial) {
        image.dispose();
        return;
      }

      final oldImage = _backdropImage;
      setState(() {
        _backdropImage = image;
        _backdropLogicalSize = logicalSize;
      });
      oldImage?.dispose();

      if (_warmupCapturesRemaining > 0) {
        _warmupCapturesRemaining--;
        _scheduleCapture();
      }
    } catch (_) {
      if (mounted && _warmupCapturesRemaining > 0) {
        _warmupCapturesRemaining--;
        _scheduleCapture();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (notification) {
        _scheduleCapture(warmupCaptures: _initialWarmupCaptures);
        return true;
      },
      child: SizeChangedLayoutNotifier(
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(key: _backgroundKey, child: widget.background),
            LiquidGlassGroup(
              settings: widget.settings,
              repaint: widget.repaint,
              backdropImage: _backdropImage,
              backdropLogicalSize: _backdropLogicalSize,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
