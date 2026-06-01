part of '../glass_panel.dart';

/// Captures the background and exposes backdrop state to descendant glass widgets.
class GlassStage extends StatefulWidget {
  final GlassSettings settings;
  final Widget background;
  final Widget child;
  final GlassMode mode;
  final Listenable? repaint;
  final Listenable? backdropRepaint;

  const GlassStage({
    super.key,
    required this.settings,
    required this.background,
    required this.child,
    this.mode = GlassMode.quality,
    this.repaint,
    this.backdropRepaint,
  });

  @override
  State<GlassStage> createState() => _GlassStageState();
}

class _GlassStageState extends State<GlassStage> {
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
  void didUpdateWidget(GlassStage oldWidget) {
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

    final pixelRatio = math.min(
      1.5,
      MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0,
    );
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
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _backgroundKey, child: widget.background),
        _GlassBackdropScope(
          settings: widget.settings,
          mode: widget.mode,
          repaint: widget.repaint,
          backdropImage: _backdropImage,
          backdropLogicalSize: _backdropLogicalSize,
          child: widget.child,
        ),
      ],
    );
  }
}

class _GlassBackdropScope extends InheritedWidget {
  final GlassSettings settings;
  final GlassMode mode;
  final Listenable? repaint;
  final ui.Image? backdropImage;
  final Size? backdropLogicalSize;

  const _GlassBackdropScope({
    required this.settings,
    required this.mode,
    required this.repaint,
    required this.backdropImage,
    required this.backdropLogicalSize,
    required super.child,
  });

  static _GlassBackdropScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GlassBackdropScope>();
  }

  @override
  bool updateShouldNotify(_GlassBackdropScope oldWidget) {
    return oldWidget.settings != settings ||
        oldWidget.mode != mode ||
        oldWidget.repaint != repaint ||
        oldWidget.backdropImage != backdropImage ||
        oldWidget.backdropLogicalSize != backdropLogicalSize;
  }
}
