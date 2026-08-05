import 'package:flutter/material.dart';

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
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (onSelectAll != null) ...[
                        InkWell(
                          onTap: onSelectAll,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Select all',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      InkWell(
                        onTap: onCancel,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text(
                            'Cancel',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: onDelete,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: theme.colorScheme.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 13,
                                color: theme.colorScheme.error,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Delete',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(
            height: 1,
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
