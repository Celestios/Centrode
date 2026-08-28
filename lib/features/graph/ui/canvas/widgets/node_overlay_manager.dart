import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import '../../../../../src/rust/domain/contents.dart';
import '../../../presentation/view_state.dart';
import '../text/canvas_text_editor.dart';

class NodeOverlayManager {
  final OverlayState? _overlay;
  final Map<RawUuid, OverlayEntry> _activeOverlays = {};

  NodeOverlayManager(BuildContext context) : _overlay = Overlay.of(context);

  void showEditor({
    required RawUuid nodeId,
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

    final canvasAccent = AppThemeManager.instance.currentTheme.canvasAccentColor;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: pos.dx - 2,
        top: pos.dy - 2,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: size.width + 4,
            constraints: const BoxConstraints(minHeight: 40),
            padding: UiInsets.tight,
            decoration: BoxDecoration(
              color: canvasAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(UiRadius.control),
              border: Border.all(color: canvasAccent, width: UiStrokeWidth.thick),
              boxShadow: [
                BoxShadow(
                  color: canvasAccent.withValues(alpha: 0.38),
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
                fontFamily: fontFamily.isEmpty || fontFamily == 'System'
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
    required RawUuid nodeId,
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

    _activeOverlays[nodeId] = entry;
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
