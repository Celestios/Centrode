import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class SortOption<T> {
  final T value;
  final String label;
  final IconData icon;

  const SortOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}

class SearchableSortedListHeader<T> extends StatelessWidget {
  final TextEditingController searchController;
  final String hintText;
  final T currentSort;
  final List<SortOption<T>> sortOptions;
  final ValueChanged<T> onSortChanged;
  final String tooltip;
  final int? itemCount;
  final String? itemLabel;
  final Widget? leading;

  const SearchableSortedListHeader({
    super.key,
    required this.searchController,
    required this.hintText,
    required this.currentSort,
    required this.sortOptions,
    required this.onSortChanged,
    required this.tooltip,
    this.itemCount,
    this.itemLabel,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 6.0,
          ),
          child: SizedBox(
            height: UiControlSize.standard,
            child: TextField(
              controller: searchController,
              style: const TextStyle(fontSize: UiFont.standard),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: UiFont.standard,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: UiIconSize.dense,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                contentPadding: UiInsets.verticalStandard,
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(UiRadius.card),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),

        if (leading != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 4.0,
            ),
            child: leading,
          ),

        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 4.0,
          ),
          child: Row(
            children: [
              if (itemCount != null && itemLabel != null)
                Text(
                  '$itemCount $itemLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: UiFont.micro,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              const Spacer(),
              PopupMenuButton<T>(
                popUpAnimationStyle: AnimationStyle.noAnimation,
                icon: Icon(
                  Icons.sort_rounded,
                  size: UiIconSize.dense,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 112),
                tooltip: tooltip,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(UiRadius.card),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.15),
                    width: UiStrokeWidth.standard,
                  ),
                ),
                color: theme.cardColor.withValues(alpha: 0.95),
                elevation: 6,
                onSelected: onSortChanged,
                itemBuilder: (context) => sortOptions
                    .map(
                      (option) => PopupMenuItem<T>(
                        value: option.value,
                        height: UiControlSize.standard,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              option.icon,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: UiSpacing.tight),
                            Text(
                              option.label,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: UiFont.micro,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: UiSpacing.tight),
      ],
    );
  }
}
