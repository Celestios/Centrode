import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/ui_strings.dart';
import 'centrode_modal_dialog.dart';
import 'centrode_button.dart';

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
    barrierColor: Colors.transparent,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;
      final actionColor = isDestructive
          ? theme.colorScheme.error
          : theme.colorScheme.primary;

      return CentrodeModalDialog(
        icon: Icon(icon, color: actionColor),
        title: Text(title),
        content: Text(message),
        accentColor: actionColor,
        actions: [
          CentrodeButton(
            onTap: () => Navigator.of(dialogContext).pop(false),
            child: Container(
              height: 44.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UiRadius.pill),
                color: isDark
                    ? const Color(0xFF1E2631).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.88),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.10),
                  width: 1.0,
                ),
              ),
              child: Text(
                resolvedCancelLabel,
                style: TextStyle(
                  fontSize: UiFont.standard,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF333E48),
                ),
              ),
            ),
          ),
          CentrodeButton(
            onTap: () => Navigator.of(dialogContext).pop(true),
            child: Container(
              height: 44.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UiRadius.pill),
                color: actionColor,
                boxShadow: [
                  BoxShadow(
                    color: actionColor.withValues(alpha: 0.35),
                    blurRadius: 12.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                resolvedConfirmLabel,
                style: const TextStyle(
                  fontSize: UiFont.standard,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

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
    barrierColor: Colors.transparent,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;
      final primaryColor = theme.colorScheme.primary;

      return CentrodeModalDialog(
        icon: Icon(icon, color: primaryColor),
        title: Text(title),
        content: message != null ? Text(message) : null,
        showInput: true,
        inputController: textController,
        inputPlaceholder: hintText,
        accentColor: primaryColor,
        onInputSubmitted: (val) {
          final trimmed = val.trim();
          if (trimmed.isNotEmpty) {
            Navigator.of(dialogContext).pop(trimmed);
          }
        },
        actions: [
          CentrodeButton(
            onTap: () => Navigator.of(dialogContext).pop(null),
            child: Container(
              height: 44.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UiRadius.pill),
                color: isDark
                    ? const Color(0xFF1E2631).withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.88),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.10),
                  width: 1.0,
                ),
              ),
              child: Text(
                resolvedCancelLabel,
                style: TextStyle(
                  fontSize: UiFont.standard,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF333E48),
                ),
              ),
            ),
          ),
          CentrodeButton(
            onTap: () {
              final trimmed = textController.text.trim();
              if (trimmed.isNotEmpty) {
                Navigator.of(dialogContext).pop(trimmed);
              }
            },
            child: Container(
              height: 44.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UiRadius.pill),
                color: primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12.0,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                resolvedActionLabel,
                style: const TextStyle(
                  fontSize: UiFont.standard,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      );
    },
  ).whenComplete(() => textController.dispose());
}
