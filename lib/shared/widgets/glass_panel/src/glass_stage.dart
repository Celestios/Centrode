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

class _GlassStageState extends State<GlassStage>
    with SingleTickerProviderStateMixin {
  final GlobalKey _bgKey = GlobalKey();
  ui.Image? _backdropImage;
  Size? _backdropLogicalSize;
  late Ticker _ticker;

  /// Atomic lock: prevents concurrent captures from flooding the memory bus.
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    widget.backdropRepaint?.addListener(_onRepaint);
  }

  @override
  void didUpdateWidget(GlassStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backdropRepaint != widget.backdropRepaint) {
      oldWidget.backdropRepaint?.removeListener(_onRepaint);
      widget.backdropRepaint?.addListener(_onRepaint);
    }
  }

  void _onRepaint() {
    _captureSnapshot();
  }

  void _tick(Duration elapsed) {
    _captureSnapshot();
  }

    Future<void> _captureSnapshot() async {
      if (widget.mode != GlassMode.quality || _isCapturing) return;

      final ctx = _bgKey.currentContext;
      if (ctx == null || !mounted) return;

      final boundary = ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null || boundary.debugNeedsPaint) return;

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
        });
        oldImage?.dispose();
      } catch (_) {
        // Silently swallow transient layout state failures
      } finally {
        if (mounted) _isCapturing = false;
      }
    }

  @override
  void dispose() {
    _ticker.dispose();
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
