import 'package:flutter/material.dart';
import 'surfaces/double_edge_surface.dart';
import 'surfaces/inset_surface.dart';

class CentrodeDeclarativeDialog extends StatefulWidget {
  final Widget? icon;
  final Widget? title;
  final Widget message;
  final Widget? action;
  final Duration duration;
  final Duration dimDelay;
  final double idleOpacity;
  final VoidCallback? onDismissed;
  final Color? accentColor;
  final double? width;
  final double cornerRadius;
  final EdgeInsetsGeometry padding;

  const CentrodeDeclarativeDialog({
    super.key,
    this.icon,
    this.title,
    required this.message,
    this.action,
    this.duration = const Duration(seconds: 5),
    this.dimDelay = const Duration(milliseconds: 1200),
    this.idleOpacity = 0.45,
    this.onDismissed,
    this.accentColor,
    this.width,
    this.cornerRadius = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
  });

  static Future<void> show({
    required BuildContext context,
    Widget? icon,
    Widget? title,
    required Widget message,
    Widget? action,
    Duration duration = const Duration(seconds: 5),
    Duration dimDelay = const Duration(milliseconds: 1200),
    double idleOpacity = 0.45,
    Color? accentColor,
    Alignment alignment = Alignment.bottomRight,
    EdgeInsets margin = const EdgeInsets.all(24.0),
    double? width = 360.0,
  }) async {
    final overlayState = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return Align(
          alignment: alignment,
          child: Padding(
            padding: margin,
            child: Material(
              color: Colors.transparent,
              child: CentrodeDeclarativeDialog(
                icon: icon,
                title: title,
                message: message,
                action: action,
                duration: duration,
                dimDelay: dimDelay,
                idleOpacity: idleOpacity,
                accentColor: accentColor,
                width: width,
                onDismissed: () {
                  entry.remove();
                },
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(entry);
  }

  @override
  State<CentrodeDeclarativeDialog> createState() => _CentrodeDeclarativeDialogState();
}

class _CentrodeDeclarativeDialogState extends State<CentrodeDeclarativeDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _entranceOpacityAnimation;

  bool _isHovered = false;
  bool _dimmed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.linear),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.15, curve: Curves.easeOutCubic),
      ),
    );

    _entranceOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.10, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onDismissed?.call();
      }
    });

    Future.delayed(widget.dimDelay, () {
      if (mounted) {
        setState(() {
          _dimmed = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter(PointerEvent _) {
    setState(() {
      _isHovered = true;
    });
    _controller.stop();
  }

  void _onExit(PointerEvent _) {
    setState(() {
      _isHovered = false;
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveAccent = widget.accentColor ?? theme.colorScheme.primary;
    final targetAlpha = (_dimmed && !_isHovered) ? widget.idleOpacity : 1.0;

    return MouseRegion(
      onEnter: _onEnter,
      onExit: _onExit,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final entranceVal = _entranceOpacityAnimation.value;
          return Opacity(
            opacity: entranceVal * targetAlpha,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              alignment: Alignment.bottomRight,
              child: child,
            ),
          );
        },
        child: SizedBox(
          width: widget.width,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.cornerRadius),
            child: CentrodeDoubleEdgeSurface(
              cornerRadius: widget.cornerRadius,
              padding: EdgeInsets.zero,
              accentColor: effectiveAccent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: widget.padding,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          IconTheme(
                            data: IconThemeData(
                              color: effectiveAccent,
                              size: 20.0,
                            ),
                            child: widget.icon!,
                          ),
                          const SizedBox(width: 12.0),
                        ],
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.title != null) ...[
                                DefaultTextStyle(
                                  style: TextStyle(
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    letterSpacing: -0.2,
                                  ),
                                  child: widget.title!,
                                ),
                                const SizedBox(height: 2.0),
                              ],
                              DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w400,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.75)
                                      : const Color(0xFF475569),
                                  height: 1.35,
                                ),
                                child: widget.message,
                              ),
                            ],
                          ),
                        ),
                        if (widget.action != null) ...[
                          const SizedBox(width: 12.0),
                          widget.action!,
                        ],
                      ],
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, _) {
                      return SizedBox(
                        height: 3.0,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: CentrodeInsetPainter(
                                  cornerRadius: 0.0,
                                  isDark: isDark,
                                  depth: 0.8,
                                  accentColor: effectiveAccent,
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: FractionallySizedBox(
                                widthFactor: _progressAnimation.value.clamp(0.0, 1.0),
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        effectiveAccent.withValues(alpha: 0.7),
                                        effectiveAccent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: effectiveAccent.withValues(alpha: 0.5),
                                        blurRadius: 4.0,
                                        offset: const Offset(0, -0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
