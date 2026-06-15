import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// A [Stack] that does not clip hit tests to its bounds.
///
/// This is useful in a pannable canvas where children might be visually
/// rendered outside the Stack's bounds but still need to receive pointer events.
class UnboundedStack extends Stack {
  const UnboundedStack({
    super.key,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
    super.children,
  });

  @override
  RenderUnboundedStack createRenderObject(BuildContext context) {
    return RenderUnboundedStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderUnboundedStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class RenderUnboundedStack extends RenderStack {
  RenderUnboundedStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
