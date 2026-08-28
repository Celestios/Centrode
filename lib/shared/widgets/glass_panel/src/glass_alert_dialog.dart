import 'package:centrode/shared/theme/design_tokens.dart';
import 'dart:ui';
import 'package:flutter/material.dart';

class GlassAlertDialog extends StatelessWidget {
  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;

  const GlassAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: theme.cardColor.withValues(alpha: 0.95),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UiRadius.panel),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
            width: UiStrokeWidth.standard,
          ),
        ),
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}
