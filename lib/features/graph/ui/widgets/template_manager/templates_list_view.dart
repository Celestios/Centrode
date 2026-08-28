import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/shared/utils/date_utils.dart';
import '../../../store/command_queue_processor.dart';
import '../../../presentation/viewport_state.dart';
import '../../../models/models.dart';
import 'package:centrode/presentation/widgets/search/searchable_sort_list_header.dart';
import 'template_preview_painter.dart';
import 'delete_template_dialog.dart';

enum TemplateSortOption { alphabeticalAsc, alphabeticalDesc, newest, oldest }

class TemplatesListView extends StatefulWidget {
  const TemplatesListView({super.key});

  @override
  State<TemplatesListView> createState() => _TemplatesListViewState();
}

class _TemplatesListViewState extends State<TemplatesListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TemplateSortOption _sortOption = TemplateSortOption.newest;
  String? _hoveredTemplateKey;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommandQueueProcessor>();
    final theme = Theme.of(context);

    return FutureBuilder<List<Template>>(
      future: controller.templateMutations.getAllTemplates(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('TEMPLATES ERROR: ${snapshot.error}');
          debugPrint('TEMPLATES STACK: ${snapshot.stackTrace}');
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 20,
                height: UiControlSize.dense,
                child: CircularProgressIndicator(strokeWidth: UiStrokeWidth.thick),
              ),
            ),
          );
        }

        final allTemplates = (snapshot.data ?? [])
            .whereType<Template>()
            .toList();

        // Apply search query filter
        var filteredTemplates = allTemplates;
        if (_searchQuery.isNotEmpty) {
          filteredTemplates = allTemplates
              .where(
                (t) =>
                    t.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();
        }

        // Apply sorting option
        filteredTemplates.sort((a, b) {
          switch (_sortOption) {
            case TemplateSortOption.alphabeticalAsc:
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            case TemplateSortOption.alphabeticalDesc:
              return b.name.toLowerCase().compareTo(a.name.toLowerCase());
            case TemplateSortOption.newest:
              return b.createdAt.toInt().compareTo(a.createdAt.toInt());
            case TemplateSortOption.oldest:
              return a.createdAt.toInt().compareTo(b.createdAt.toInt());
          }
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchableSortedListHeader<TemplateSortOption>(
              searchController: _searchController,
              hintText: 'Search templates...',
              currentSort: _sortOption,
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
              onSortChanged: (option) {
                setState(() {
                  _sortOption = option;
                });
              },
              tooltip: 'Sort templates',
              itemCount: filteredTemplates.length,
              itemLabel: 'TEMPLATES',
            ),
            const SizedBox(height: UiSpacing.tight),

            if (filteredTemplates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty
                        ? 'No templates saved'
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
                    final nodeCount = template.nodes.length;
                    final relationCount = template.relations.length;

                    final isHovered =
                        _hoveredTemplateKey == template.key.key.uuid;

                    // Create the tile widget
                    final tileChild = Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.04,
                              )
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.05),
                            width: UiStrokeWidth.standard,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Visual snapshot of the template group
                          TemplatePreviewWidget(
                            nodes: template.nodes,
                            relations: template.relations,
                            size: 44.0,
                          ),
                          const SizedBox(width: UiSpacing.standard),

                          // Template metadata text details
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontSize: UiFont.standard,
                                    fontWeight: FontWeight.bold,
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
                                    await controller.templateMutations
                                        .instantiateTemplate(
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
                                      await controller.templateMutations
                                          .deleteTemplate(
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
                                  : formatTimestampShort(template.createdAt.toInt()),
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

                    // Wrap tile inside a Draggable and MouseRegion for hover detection
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
