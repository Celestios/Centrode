import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final int selectedCount;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;
  final VoidCallback? onSelectAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.selectedCount = 0,
    this.onCancel,
    this.onDelete,
    this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title.toUpperCase(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                if (selectedCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$selectedCount selected',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: UiFont.compact,
                        ),
                      ),
                      const SizedBox(width: UiSpacing.standard),
                      if (onSelectAll != null) ...[
                        _ActionPill(
                          label: 'Select all',
                          onTap: onSelectAll,
                          backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                          borderColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          textColor: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: UiSpacing.tight),
                      ],
                      _ActionPill(
                        label: 'Cancel',
                        onTap: onCancel,
                        backgroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        borderColor: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                        textColor: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: UiSpacing.tight),
                      _ActionPill(
                        label: 'Delete',
                        onTap: onDelete,
                        backgroundColor: theme.colorScheme.error.withValues(alpha: 0.15),
                        borderColor: theme.colorScheme.error.withValues(alpha: 0.3),
                        textColor: theme.colorScheme.error,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 13,
                          color: theme.colorScheme.error,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: UiSpacing.standard),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Color? textColor;
  final Widget? icon;
  final FontWeight? fontWeight;

  const _ActionPill({
    required this.label,
    this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    this.textColor,
    this.icon,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CentrodeButton(
      onTap: onTap,
      borderRadius: BorderRadius.circular(UiRadius.control),
      enableHover: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(UiRadius.control),
          border: Border.all(color: borderColor),
        ),
        child: icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon!,
                  const SizedBox(width: 3),
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: UiFont.compact,
                      color: textColor,
                      fontWeight: fontWeight ?? FontWeight.w500,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: UiFont.compact,
                  color: textColor,
                  fontWeight: fontWeight ?? FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
