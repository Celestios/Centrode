import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/shared/utils/date_utils.dart';
import 'package:centrode/presentation/widgets/search/searchable_sort_list_header.dart';
import '../../../store/command_queue_processor.dart';
import '../../../models/models.dart';
import '../../../presentation/viewport_state.dart';
import '../../../presentation/template_manager_coordinator.dart';
import 'template_preview_painter.dart';
import 'delete_template_dialog.dart';

class TemplatesListView extends StatefulWidget {
  final TemplateManagerCoordinator? coordinator;

  const TemplatesListView({super.key, this.coordinator});

  @override
  State<TemplatesListView> createState() => _TemplatesListViewState();
}

class _TemplatesListViewState extends State<TemplatesListView> {
  final TextEditingController _searchController = TextEditingController();
  String? _hoveredTemplateKey;

  TemplateManagerCoordinator? _internalCoordinator;
  TemplateManagerCoordinator get _coordinator =>
      widget.coordinator ?? _internalCoordinator!;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _coordinator.setSearchQuery(_searchController.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.coordinator == null && _internalCoordinator == null) {
      _internalCoordinator = TemplateManagerCoordinator(
        commandProcessor: context.read<CommandQueueProcessor>(),
      );
      _internalCoordinator!.refresh();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _internalCoordinator?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _coordinator,
      builder: (context, _) {
        final filteredTemplates = _coordinator.filteredTemplates;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchableSortedListHeader<TemplateSortOption>(
              searchController: _searchController,
              hintText: 'Search templates...',
              currentSort: _coordinator.sortOption,
              sortOptions: const [
                SortOption(
                  value: TemplateSortOption.newest,
                  label: 'Newest First',
                  icon: Icons.calendar_today_rounded,
                ),
                SortOption(
                  value: TemplateSortOption.oldest,
                  label: 'Oldest First',
                  icon: Icons.calendar_today_outlined,
                ),
                SortOption(
                  value: TemplateSortOption.alphabeticalAsc,
                  label: 'Name A-Z',
                  icon: Icons.sort_by_alpha_rounded,
                ),
                SortOption(
                  value: TemplateSortOption.alphabeticalDesc,
                  label: 'Name Z-A',
                  icon: Icons.sort_by_alpha_rounded,
                ),
              ],
              onSortChanged: (option) => _coordinator.setSortOption(option),
              tooltip: 'Sort templates',
            ),

            // Scrollable List Body
            if (filteredTemplates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    _coordinator.searchQuery.isEmpty
                        ? 'No templates saved yet'
                        : 'No matching templates',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: UiFont.compact,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTemplates.length,
                  padding: UiInsets.verticalTight,
                  itemBuilder: (context, index) {
                    final template = filteredTemplates[index];
                    final isHovered =
                        _hoveredTemplateKey == template.key.key.uuid;

                    final nodeCount = template.nodes.length;
                    final relationCount = template.relations.length;

                    final tileChild = Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.03,
                              ),
                        borderRadius: BorderRadius.circular(UiRadius.card),
                        border: Border.all(
                          color: isHovered
                              ? theme.colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.white10,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Thumbnail Preview
                          TemplatePreviewWidget(
                            nodes: template.nodes,
                            relations: template.relations,
                            size: 44,
                          ),
                          const SizedBox(width: UiSpacing.standard),

                          // Template Info (Title & Counts)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontSize: UiFont.standard,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: UiSpacing.tight),
                                Text(
                                  '$nodeCount nodes · $relationCount relations',
                                  style: TextStyle(
                                    fontSize: UiFont.micro,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Quick action buttons or creation time
                          if (isHovered)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Instantiate template at viewport center
                                CentrodeIconButton(
                                  icon: Icons.add_circle_outline_rounded,
                                  onPressed: () async {
                                    final viewportController = context
                                        .read<ViewportController>();
                                    final visibleCenter = viewportController
                                        .viewportStateNotifier
                                        .value
                                        .visibleRect
                                        .center;
                                    await _coordinator.instantiateTemplate(
                                      template.key.key.uuid,
                                      visibleCenter,
                                    );
                                  },
                                  iconSize: 16,
                                  buttonSize: 24,
                                  enableHover: false,
                                  tooltip: 'Place at Center',
                                ),
                                const SizedBox(width: UiSpacing.tight),
                                // Delete template button
                                CentrodeIconButton(
                                  icon: Icons.delete_outline_rounded,
                                  onPressed: () async {
                                    final confirm =
                                        await showDeleteTemplateDialog(
                                          context,
                                          template.name,
                                        );
                                    if (confirm == true) {
                                      await _coordinator.deleteTemplate(
                                        template.key.key.uuid,
                                      );
                                    }
                                  },
                                  iconSize: 16,
                                  buttonSize: 24,
                                  enableHover: false,
                                  iconColor: Colors.redAccent,
                                  tooltip: 'Delete Template',
                                ),
                              ],
                            )
                          else
                            Text(
                              template.createdAt <= 0
                                  ? 'Unknown'
                                  : formatTimestampShort(
                                      template.createdAt.toInt(),
                                    ),
                              style: TextStyle(
                                fontSize: UiFont.micro,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );

                    return MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _hoveredTemplateKey = template.key.key.uuid;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _hoveredTemplateKey = null;
                        });
                      },
                      child: Draggable<Template>(
                        data: template,
                        dragAnchorStrategy: pointerDragAnchorStrategy,
                        feedback: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(UiRadius.card),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.4,
                                ),
                                width: UiStrokeWidth.thick,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.copy_all_outlined,
                                  size: UiIconSize.dense,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: UiSpacing.standard),
                                Text(
                                  template.name,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: tileChild,
                        ),
                        child: tileChild,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class TemplatePreviewWidget extends StatelessWidget {
  final List<Nodes> nodes;
  final List<IRelation> relations;
  final double size;

  const TemplatePreviewWidget({
    super.key,
    required this.nodes,
    required this.relations,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final uiNodes = nodes.map((n) => UiNode.fromRust(n)).toList();
    final uiRelations = relations.map((r) => UiRelation.fromRust(r)).toList();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(UiRadius.control),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: UiStrokeWidth.standard,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CustomPaint(
          painter: TemplatePreviewPainter(
            nodes: uiNodes,
            relations: uiRelations,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}
