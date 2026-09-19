import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../../../presentation/workspace_tabs_controller.dart';

class UndoRedoButtons extends StatelessWidget {
  final TabSession? session;
  final bool isVertical;

  const UndoRedoButtons({
    super.key,
    required this.session,
    this.isVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final sessionObj = session;
    if (sessionObj == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

    return ListenableBuilder(
      listenable: sessionObj,
      builder: (context, _) {
        final canUndo = sessionObj.canUndo;
        final canRedo = sessionObj.canRedo;
        final undoCount = sessionObj.undoCount;
        final redoCount = sessionObj.redoCount;

        if (isVertical) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(UiRadius.panel),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.2),
                width: UiStrokeWidth.subtle,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HistoryBadgeButton(
                  icon: Icons.undo_rounded,
                  isEnabled: canUndo,
                  count: undoCount,
                  tooltip: canUndo
                      ? 'Undo ($undoCount actions)'
                      : 'Undo (No actions)',
                  onTap: canUndo ? () => sessionObj.undo() : null,
                  textColor: textColor,
                ),
                const SizedBox(height: UiSpacing.tight),
                HistoryBadgeButton(
                  icon: Icons.redo_rounded,
                  isEnabled: canRedo,
                  count: redoCount,
                  tooltip: canRedo
                      ? 'Redo ($redoCount actions)'
                      : 'Redo (No actions)',
                  onTap: canRedo ? () => sessionObj.redo() : null,
                  textColor: textColor,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(UiRadius.card),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.15),
              width: UiStrokeWidth.subtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HistoryBadgeButton(
                icon: Icons.undo_rounded,
                isEnabled: canUndo,
                count: undoCount,
                tooltip: canUndo
                    ? 'Undo ($undoCount actions remaining)'
                    : 'Undo (No actions available)',
                onTap: canUndo ? () => sessionObj.undo() : null,
                textColor: textColor,
              ),
              const SizedBox(width: 3),
              HoverScaleButton(
                onTap: () {},
                tooltip: 'Version Control\n$undoCount undo(s), $redoCount redo(s) available',
                borderRadius: BorderRadius.circular(UiRadius.control),
                hoverScale: 1.05,
                pressScale: 0.95,
                builder: (context, isHovered, _) => Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.history_rounded,
                    size: UiIconSize.standard,
                    color: (canUndo || canRedo)
                        ? (isHovered
                            ? theme.colorScheme.primary
                            : textColor.withValues(alpha: 0.85))
                        : textColor.withValues(alpha: 0.25),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              HistoryBadgeButton(
                icon: Icons.redo_rounded,
                isEnabled: canRedo,
                count: redoCount,
                tooltip: canRedo
                    ? 'Redo ($redoCount actions remaining)'
                    : 'Redo (No actions available)',
                onTap: canRedo ? () => sessionObj.redo() : null,
                textColor: textColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
