import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/src/glass_alert_dialog.dart';
import '../theme/design_tokens.dart';
import '../theme/ui_strings.dart';

/// Shows a standardized Centrode confirmation modal with frosted glass backdrop.
Future<bool?> showCentrodeConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? confirmLabel,
  String? cancelLabel,
  bool isDestructive = true,
  IconData icon = Icons.warning_amber_rounded,
}) {
  final resolvedConfirmLabel = confirmLabel ?? UiStrings.common.delete;
  final resolvedCancelLabel = cancelLabel ?? UiStrings.common.cancel;
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final primaryColor = isDestructive
          ? theme.colorScheme.error
          : theme.colorScheme.primary;

      return GlassAlertDialog(
        title: Row(
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: UiIconSize.header,
            ),
            const SizedBox(width: UiSpacing.standard),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: UiFont.title,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              resolvedCancelLabel,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.15),
              foregroundColor: primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiRadius.card),
                side: BorderSide(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: UiStrokeWidth.standard,
                ),
              ),
            ),
            child: Text(resolvedConfirmLabel),
          ),
        ],
      );
    },
  );
}

/// Shows a standardized Centrode text input modal with frosted glass backdrop.
Future<String?> showCentrodeInputDialog({
  required BuildContext context,
  required String title,
  String? message,
  String? hintText,
  String? initialValue,
  String? actionLabel,
  String? cancelLabel,
  IconData icon = Icons.bookmark_add_rounded,
}) {
  final resolvedActionLabel = actionLabel ?? UiStrings.common.save;
  final resolvedCancelLabel = cancelLabel ?? UiStrings.common.cancel;
  final textController = TextEditingController(text: initialValue);

  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final primaryColor = theme.colorScheme.primary;

      return GlassAlertDialog(
        title: Row(
          children: [
            Icon(
              icon,
              color: primaryColor,
              size: UiIconSize.header,
            ),
            const SizedBox(width: UiSpacing.standard),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: UiFont.title,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message != null) ...[
              Text(
                message,
                style: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: UiSpacing.gutter),
            ],
            TextField(
              controller: textController,
              autofocus: true,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontSize: UiFont.header,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                  fontSize: UiFont.header,
                ),
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.15),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: UiSpacing.container,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiRadius.card),
                  borderSide: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                    width: UiStrokeWidth.standard,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiRadius.card),
                  borderSide: BorderSide(
                    color: primaryColor.withValues(alpha: 0.6),
                    width: UiStrokeWidth.thick,
                  ),
                ),
              ),
              onSubmitted: (value) {
                final trimmed = value.trim();
                if (trimmed.isNotEmpty) {
                  Navigator.of(dialogContext).pop(trimmed);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: Text(
              resolvedCancelLabel,
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final trimmed = textController.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(dialogContext).pop(trimmed);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor.withValues(alpha: 0.15),
              foregroundColor: primaryColor,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(UiRadius.card),
                side: BorderSide(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: UiStrokeWidth.standard,
                ),
              ),
            ),
            child: Text(resolvedActionLabel),
          ),
        ],
      );
    },
  );
}
