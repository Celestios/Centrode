import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/src/glass_alert_dialog.dart';

/// Shows a dialog prompting the user to name the template.
/// Styled with a beautiful backdrop blur.
Future<String?> showSaveTemplateDialog(BuildContext context) {
  final theme = Theme.of(context);
  final textController = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => GlassAlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 8),
          Text(
            'SAVE AS TEMPLATE',
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter a name for this template to save the selected subgraph as a reusable template.',
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: textController,
            autofocus: true,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Template name...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: Colors.black.withValues(alpha: 0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (val) {
              final name = val.trim();
              if (name.isNotEmpty) {
                Navigator.of(context).pop(name);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.6,
            ),
          ),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = textController.text.trim();
            if (name.isNotEmpty) {
              Navigator.of(context).pop(name);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withValues(
              alpha: 0.15,
            ),
            foregroundColor: theme.colorScheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('SAVE'),
        ),
      ],
    ),
  );
}
