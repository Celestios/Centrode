import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

/// Shows a dialog prompting the user to name the template.
Future<String?> showSaveTemplateDialog(BuildContext context) {
  return showCentrodeInputDialog(
    context: context,
    title: UiStrings.dialogs.saveTemplateTitle,
    message: UiStrings.dialogs.saveTemplateMessage,
    hintText: UiStrings.dialogs.templateNameHint,
    actionLabel: UiStrings.common.save,
    cancelLabel: UiStrings.common.cancel,
    icon: Icons.bookmark_add_outlined,
  );
}
