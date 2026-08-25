import 'package:flutter/material.dart';

class FadingTabScrollView extends StatefulWidget {
  final Widget child;

  const FadingTabScrollView({
    super.key,
    required this.child,
  });

  @override
  State<FadingTabScrollView> createState() => _FadingTabScrollViewState();
}

class _FadingTabScrollViewState extends State<FadingTabScrollView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        setState(() {});
      }
    });
  }

  @override
  void didUpdateWidget(covariant FadingTabScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    double leftFade = 0.0;
    double rightFade = 0.0;

    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
      final offset = _scrollController.offset;
      final maxScroll = _scrollController.position.maxScrollExtent;
      const fadeExtent = 24.0;

      leftFade = (offset / fadeExtent).clamp(0.0, 1.0);
      rightFade = ((maxScroll - offset) / fadeExtent).clamp(0.0, 1.0);
    }

    final scrollView = SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: widget.child,
    );

    if (leftFade == 0.0 && rightFade == 0.0) {
      return scrollView;
    }

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        if (bounds.width <= 0) {
          return const LinearGradient(colors: [Colors.black, Colors.black]).createShader(bounds);
        }

        const fadeWidth = 24.0;
        final leftStop = (fadeWidth / bounds.width).clamp(0.0, 0.3);
        final rightStop = 1.0 - (fadeWidth / bounds.width).clamp(0.0, 0.3);

        final leftAlpha = (1.0 - leftFade).clamp(0.0, 1.0);
        final rightAlpha = (1.0 - rightFade).clamp(0.0, 1.0);

        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Color.fromRGBO(0, 0, 0, leftAlpha),
            Colors.black,
            Colors.black,
            Color.fromRGBO(0, 0, 0, rightAlpha),
          ],
          stops: [
            0.0,
            leftStop,
            rightStop,
            1.0,
          ],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: scrollView,
    );
  }
}
