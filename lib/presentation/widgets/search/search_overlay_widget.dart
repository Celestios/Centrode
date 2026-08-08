import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/color_utils.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'search_registry.dart';

class SearchOverlayWidget extends StatelessWidget {
  final List<SearchResult> results;
  final int selectedIndex;
  final bool isLoading;
  final void Function(SearchResult) onSelected;
  final ScrollController scrollController;
  final GraphDataQueryController? queryController;

  const SearchOverlayWidget({
    super.key,
    required this.results,
    required this.selectedIndex,
    required this.isLoading,
    required this.onSelected,
    required this.scrollController,
    this.queryController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      width: 500,
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        child: GlassPanel(
          borderRadius: 12,
          blur: 12,
          color: theme.cardColor.withValues(alpha: 0.92),
          shadow: BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isLoading)
                  LinearProgressIndicator(
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                if (!isLoading && results.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'No matching results',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  )
                else if (results.isNotEmpty)
                  Flexible(
                    child: ListView.builder(
                      controller: scrollController,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        final isSelected = index == selectedIndex;

                        if (item.type == SearchResultType.relationHeader) {
                          final verbColor = getVerbColor(
                            item.relationVerb,
                            theme,
                          );
                          return Container(
                            padding: const EdgeInsets.only(
                              left: 14,
                              right: 14,
                              top: 14,
                              bottom: 8,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: verbColor.withValues(alpha: 0.1),
                                    border: Border.all(
                                      color: verbColor.withValues(alpha: 0.4),
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.alt_route_rounded,
                                        size: 10,
                                        color: verbColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.relationVerb?.toUpperCase() ??
                                            'RELATION',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.1,
                                          color: verbColor,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: theme.dividerColor.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (item.type == SearchResultType.relation) {
                          final rel = item.relation;
                          final fromNode = rel != null
                              ? queryController?.nodeLookup[rel.fromNodeId]
                              : null;
                          final toNode = rel != null
                              ? queryController?.nodeLookup[rel.toNodeId]
                              : null;
                          final verbColor = getVerbColor(
                            item.relationVerb,
                            theme,
                          );

                          return InkWell(
                            onTap: () => onSelected(item),
                            child: Container(
                              padding: const EdgeInsets.only(
                                left: 28,
                                right: 14,
                                top: 8,
                                bottom: 8,
                              ),
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    )
                                  : Colors.transparent,
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 14,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : verbColor.withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildNodePreview(fromNode, theme),
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            height: 1.5,
                                            color: verbColor.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              size: 14,
                                              color: verbColor.withValues(
                                                alpha: 0.5,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.cardColor,
                                              border: Border.all(
                                                color: verbColor.withValues(
                                                  alpha: 0.4,
                                                ),
                                                width: 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.relationVerb ?? '',
                                              style: TextStyle(
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                                color: verbColor,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  _buildNodePreview(toNode, theme),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      'Enter',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontSize: 10,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }

                        return InkWell(
                          onTap: () => onSelected(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            color: isSelected
                                ? theme.colorScheme.primary.withValues(
                                    alpha: 0.15,
                                  )
                                : Colors.transparent,
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  size: 18,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.iconTheme.color?.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        item.title,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                      Text(
                                        item.subtitle,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme.hintColor,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Text(
                                    'Enter',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontSize: 10,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNodePreview(UiNode? node, ThemeData theme) {
    if (node == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.dividerColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'Unknown',
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      );
    }

    final style = node.resolvedStyle;
    final bgColor = style != null ? Color(style.bgColor) : theme.cardColor;
    final strokeColor = style != null
        ? Color(style.strokeColor)
        : theme.dividerColor;
    final textColor = style != null
        ? Color(style.textColor)
        : theme.textTheme.bodyMedium?.color;
    final borderRadius = style != null ? style.borderRadius : 4.0;
    final isCircle = style?.shape == 'circle';

    return Container(
      constraints: const BoxConstraints(maxWidth: 130),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: isCircle
            ? BorderRadius.circular(100)
            : BorderRadius.circular(borderRadius),
        border: Border.all(color: strokeColor, width: 1),
      ),
      child: Text(
        node.text.isEmpty ? 'Untitled Node' : node.text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
          fontFamily: style?.fontFamily,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
