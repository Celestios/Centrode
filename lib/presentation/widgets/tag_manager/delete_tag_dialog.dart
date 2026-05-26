import 'dart:ui';
import 'package:flutter/material.dart';

/// Shows a dialog asking the user to confirm deletion of a tag.
/// Styled with a beautiful backdrop blur.
Future<bool?> showDeleteTagDialog(BuildContext context, String tagName) {
  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: theme.cardColor.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: theme.colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'DELETE TAG?',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the tag "$tagName" globally? This will remove it from all nodes and cannot be undone.',
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.4,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
              foregroundColor: theme.colorScheme.error,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    ),
  );
}
