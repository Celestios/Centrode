import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

class ContextMenuItem {
  final String label;
  final VoidCallback onTap;
  final bool visible;

  const ContextMenuItem({
    required this.label,
    required this.onTap,
    this.visible = true,
  });
}

class ContextMenuOverlay {
  static OverlayEntry? show({
    required BuildContext context,
    required Offset position,
    required List<ContextMenuItem> items,
    VoidCallback? onDismissed,
  }) {
    final visibleItems = items.where((item) => item.visible).toList();
    if (visibleItems.isEmpty) return null;

    OverlayEntry? entry;
    bool removed = false;

    void dismiss() {
      if (!removed && entry != null) {
        removed = true;
        entry!.remove();
        entry = null;
        onDismissed?.call();
      }
    }

    entry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: dismiss,
        child: Stack(
          children: [
            const SizedBox.expand(),
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(UiRadius.control),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final item in visibleItems)
                      _ContextMenuItemWidget(
                        label: item.label,
                        onTap: () {
                          item.onTap();
                          dismiss();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(entry!);
    return entry;
  }
}

class _ContextMenuItemWidget extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ContextMenuItemWidget({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CentrodeButton(
      onTap: onTap,
      enableHover: false,
      borderRadius: BorderRadius.circular(UiRadius.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(label),
      ),
    );
  }
}
