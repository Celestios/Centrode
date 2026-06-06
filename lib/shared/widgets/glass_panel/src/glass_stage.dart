// glass_panel/src/glass_stage.dart
part of '../glass_panel.dart';

/// Wraps the background in a [RepaintBoundary] and captures it each frame at
/// 25% scale (negligible GPU→CPU transfer cost). The downsampled [ui.Image] is
/// propagated to descendant [GlassGroup] widgets via [_GlassBackdropScope].
class GlassStage extends StatefulWidget {
  final GlassSettings settings;
  final Widget background;
  final Widget child;
  final GlassMode mode;
  final Listenable? backdropRepaint;

  const GlassStage({
    super.key,
    required this.settings,
    required this.background,
    required this.child,
    this.mode = GlassMode.quality,
    this.backdropRepaint,
  });

  @override
  State<GlassStage> createState() => _GlassStageState();
}

class _GlassStageState extends State<GlassStage> {
  final GlobalKey _bgKey = GlobalKey();
  ui.Image? _backdropImage;
  Size? _backdropLogicalSize;
  DateTime? _lastCaptureTime;
  Timer? _throttleTimer;

  final List<Timer> _warmupTimers = [];

  /// Atomic lock: prevents concurrent captures from flooding the memory bus.
  bool _isCapturing = false;
  bool _hasPendingCaptureRequest = false;

  @override
  void initState() {
    super.initState();
    widget.backdropRepaint?.addListener(_onRepaint);
    _scheduleWarmupCaptures();
  }

  @override
  void didUpdateWidget(GlassStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backdropRepaint != widget.backdropRepaint) {
      oldWidget.backdropRepaint?.removeListener(_onRepaint);
      widget.backdropRepaint?.addListener(_onRepaint);
      _requestCapture();
    }
    if (oldWidget.background != widget.background) {
      _scheduleWarmupCaptures();
    }
  }

  void _scheduleWarmupCaptures() {
    _cancelWarmupTimers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _requestCapture();
    });

    // Schedule delayed captures to ensure the background is captured after
    // asynchronous assets (like images) load.
    final delays = [100, 400, 1000, 2500];
    for (final delay in delays) {
      _warmupTimers.add(
        Timer(Duration(milliseconds: delay), () {
          if (mounted) {
            _requestCapture();
          }
        }),
      );
    }
  }

  void _cancelWarmupTimers() {
    for (final timer in _warmupTimers) {
      timer.cancel();
    }
    _warmupTimers.clear();
  }

  void _onRepaint() {
    _requestCapture();
  }

  void _requestCapture() {
    if (widget.mode != GlassMode.quality) return;
    if (_isCapturing) {
      _hasPendingCaptureRequest = true;
      return;
    }

    final now = DateTime.now();
    final timeSinceLastCapture = _lastCaptureTime == null
        ? Duration.zero
        : now.difference(_lastCaptureTime!);

    const throttleDuration = Duration(milliseconds: 33);

    if (timeSinceLastCapture >= throttleDuration) {
      _throttleTimer?.cancel();
      _throttleTimer = null;
      _captureSnapshot();
    } else {
      _hasPendingCaptureRequest = true;
      if (_throttleTimer == null) {
        final remaining = throttleDuration - timeSinceLastCapture;
        _throttleTimer = Timer(remaining, () {
          _throttleTimer = null;
          if (mounted && _hasPendingCaptureRequest) {
            _hasPendingCaptureRequest = false;
            _requestCapture();
          }
        });
      }
    }
  }

  void _retryCapture() {
    if (!mounted || widget.mode != GlassMode.quality) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _requestCapture();
      }
    });
  }

  Future<void> _captureSnapshot() async {
    final ctx = _bgKey.currentContext;
    if (ctx == null || !mounted) {
      _retryCapture();
      return;
    }

    final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || boundary.debugNeedsPaint) {
      _retryCapture();
      return;
    }

    _isCapturing = true;
    try {
      // 1. Exploit the existing display cache (Fast, zero poisoning)
      final nativeRatio = MediaQuery.devicePixelRatioOf(ctx);
      final fullResImage = await boundary.toImage(pixelRatio: nativeRatio);

      if (!mounted) {
        fullResImage.dispose();
        return;
      }

      // 2. Decouple and downsample offline
      const scale = 0.25;
      final scaledWidth = (fullResImage.width * scale).ceil();
      final scaledHeight = (fullResImage.height * scale).ceil();

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      
      // Perform a GPU texture blit with bilinear filtering
      canvas.drawImageRect(
        fullResImage,
        Rect.fromLTWH(0, 0, fullResImage.width.toDouble(), fullResImage.height.toDouble()),
        Rect.fromLTWH(0, 0, scaledWidth.toDouble(), scaledHeight.toDouble()),
        Paint()..filterQuality = FilterQuality.medium, 
      );

      final downsampledImage = await recorder.endRecording().toImage(scaledWidth, scaledHeight);
      
      // Immediately free the high-res texture memory
      fullResImage.dispose(); 

      final oldImage = _backdropImage;
      setState(() {
        _backdropImage = downsampledImage;
        _backdropLogicalSize = boundary.size;
        _lastCaptureTime = DateTime.now();
      });
      oldImage?.dispose();
    } catch (_) {
      _retryCapture();
    } finally {
      if (mounted) {
        _isCapturing = false;
        if (_hasPendingCaptureRequest) {
          _hasPendingCaptureRequest = false;
          _requestCapture();
        }
      }
    }
  }

  @override
  void dispose() {
    _cancelWarmupTimers();
    _throttleTimer?.cancel();
    widget.backdropRepaint?.removeListener(_onRepaint);
    _backdropImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _bgKey, child: widget.background),
        _GlassBackdropScope(
          settings: widget.settings,
          mode: widget.mode,
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
  final ui.Image? backdropImage;
  final Size? backdropLogicalSize;

  const _GlassBackdropScope({
    required this.settings,
    required this.mode,
    required this.backdropImage,
    required this.backdropLogicalSize,
    required super.child,
  });

  static _GlassBackdropScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GlassBackdropScope>();
  }

  @override
  bool updateShouldNotify(_GlassBackdropScope oldWidget) {
    return oldWidget.backdropImage != backdropImage ||
        oldWidget.settings != settings ||
        oldWidget.mode != mode;
  }
}
