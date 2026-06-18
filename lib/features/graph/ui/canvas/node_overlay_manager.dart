import 'package:flutter/material.dart';
import '../../../../src/rust/domain/contents.dart';
import '../../presentation/view_state.dart';
import 'canvas_text_editor.dart';

class NodeOverlayManager {
  final OverlayState? _overlay;
  final Map<String, OverlayEntry> _activeOverlays = {};

  NodeOverlayManager(BuildContext context)
      : _overlay = Overlay.of(context);

  void showEditor({
    required String nodeId,
    required NodeViewState viewState,
    required String contentText,
    required double fontSize,
    required String fontFamily,
    required int textColor,
  }) {
    hideAll();

    if (_overlay == null) return;

    final pos = viewState.positionNotifier.value;
    final size = viewState.sizeNotifier.value;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: pos.dx - 2,
        top: pos.dy - 2,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width + 4,
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF2196F3).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF2196F3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x602196F3),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: CanvasTextEditor(
              entityId: nodeId,
              content: const Content(text: '', blocks: []),
              maxLines: null,
              textStyle: TextStyle(
                fontSize: fontSize,
                fontFamily:
                    fontFamily.isEmpty || fontFamily == 'System'
                        ? null
                        : fontFamily,
                color: Color(textColor),
              ),
            ),
          ),
        ),
      ),
    );

    _activeOverlays[nodeId] = entry;
    _overlay.insert(entry);
  }

  void showMetadataPreview({
    required String nodeId,
    required NodeViewState viewState,
    required Widget child,
  }) {
    hideAll();

    if (_overlay == null) return;

    final pos = viewState.positionNotifier.value;
    final size = viewState.sizeNotifier.value;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: pos.dx + size.width / 2 - 110,
        top: pos.dy - 12,
        child: child,
      ),
    );

    _activeOverlays['metadata_$nodeId'] = entry;
    _overlay.insert(entry);
  }

  void hideAll() {
    for (final entry in _activeOverlays.values) {
      entry.remove();
    }
    _activeOverlays.clear();
  }

  void dispose() {
    hideAll();
  }
}
