import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

/// Shows a dialog asking the user to confirm deletion of a template.
Future<bool?> showDeleteTemplateDialog(
  BuildContext context,
  String templateName,
) {
  return showCentrodeConfirmDialog(
    context: context,
    title: UiStrings.dialogs.deleteTemplateTitle,
    message: UiStrings.dialogs.deleteTemplateMessage(templateName),
    confirmLabel: UiStrings.common.delete,
    cancelLabel: UiStrings.common.cancel,
    isDestructive: true,
  );
}
