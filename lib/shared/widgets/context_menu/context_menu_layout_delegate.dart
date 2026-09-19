import 'package:flutter/widgets.dart';

class ContextMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect targetRect;
  final Offset? clickPosition;
  final EdgeInsets screenPadding;
  final List<Rect> avoidRects;

  const ContextMenuLayoutDelegate({
    required this.targetRect,
    this.clickPosition,
    required this.screenPadding,
    this.avoidRects = const [],
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: 180.0,
      maxWidth: 260.0,
      maxHeight: constraints.maxHeight - 32,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const margin = 8.0;
    const gap = 6.0;

    final bool isAreaTarget = targetRect.width > 2.0 && targetRect.height > 2.0;

    double x;
    double y;

    if (!isAreaTarget) {
      final click = clickPosition ?? targetRect.topLeft;
      x = click.dx;
      y = click.dy;

      if (x + childSize.width > size.width - margin) {
        x = x - childSize.width;
      }
      if (y + childSize.height > size.height - margin) {
        y = y - childSize.height;
      }
    } else {
      final click = clickPosition ?? targetRect.center;
      final bool preferRight = click.dx >= targetRect.center.dx;

      final rightX = targetRect.right + gap;
      final canFitRight = rightX + childSize.width <= size.width - margin;

      final leftX = targetRect.left - childSize.width - gap;
      final canFitLeft = leftX >= margin;

      final bottomY = targetRect.bottom + gap;
      final canFitBottom = bottomY + childSize.height <= size.height - margin;

      final topY = targetRect.top - childSize.height - gap;
      final canFitTop = topY >= margin;

      if (preferRight && canFitRight) {
        x = rightX;
      } else if (!preferRight && canFitLeft) {
        x = leftX;
      } else if (canFitRight) {
        x = rightX;
      } else if (canFitLeft) {
        x = leftX;
      } else {
        x = targetRect.left.clamp(margin, size.width - childSize.width - margin);
      }

      if (x == rightX || x == leftX) {
        y = click.dy.clamp(margin, size.height - childSize.height - margin);
      } else {
        if (canFitBottom) {
          y = bottomY;
        } else if (canFitTop) {
          y = topY;
        } else {
          y = (size.height - childSize.height) / 2;
        }
      }
    }

    Rect candidate = Rect.fromLTWH(x, y, childSize.width, childSize.height);

    for (final obstacle in avoidRects) {
      if (candidate.overlaps(obstacle)) {
        final rightX = obstacle.right + gap;
        final leftX = obstacle.left - childSize.width - gap;
        final bottomY = obstacle.bottom + gap;
        final topY = obstacle.top - childSize.height - gap;

        final canFitRight = rightX + childSize.width <= size.width - margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(rightX, y, childSize.width, childSize.height)
                    .overlaps(targetRect));
        final canFitLeft = leftX >= margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(leftX, y, childSize.width, childSize.height)
                    .overlaps(targetRect));
        final canFitBottom = bottomY + childSize.height <= size.height - margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(x, bottomY, childSize.width, childSize.height)
                    .overlaps(targetRect));
        final canFitTop = topY >= margin &&
            (!isAreaTarget ||
                !Rect.fromLTWH(x, topY, childSize.width, childSize.height)
                    .overlaps(targetRect));

        if (canFitLeft) {
          x = leftX;
        } else if (canFitRight) {
          x = rightX;
        } else if (canFitBottom) {
          y = bottomY;
        } else if (canFitTop) {
          y = topY;
        }
        candidate = Rect.fromLTWH(x, y, childSize.width, childSize.height);
      }
    }

    if (x < margin) x = margin;
    if (y < margin) y = margin;
    if (x + childSize.width > size.width - margin) {
      x = size.width - childSize.width - margin;
    }
    if (y + childSize.height > size.height - margin) {
      y = size.height - childSize.height - margin;
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant ContextMenuLayoutDelegate oldDelegate) {
    return targetRect != oldDelegate.targetRect ||
        clickPosition != oldDelegate.clickPosition ||
        avoidRects != oldDelegate.avoidRects ||
        screenPadding != oldDelegate.screenPadding;
  }
}
