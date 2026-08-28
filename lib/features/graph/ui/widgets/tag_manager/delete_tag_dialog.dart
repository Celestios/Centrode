import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

/// Shows a dialog asking the user to confirm deletion of a tag.
Future<bool?> showDeleteTagDialog(BuildContext context, String tagName) {
  return showCentrodeConfirmDialog(
    context: context,
    title: UiStrings.dialogs.deleteTagTitle,
    message: UiStrings.dialogs.deleteTagMessage(tagName),
    confirmLabel: UiStrings.common.delete,
    cancelLabel: UiStrings.common.cancel,
    isDestructive: true,
  );
}
