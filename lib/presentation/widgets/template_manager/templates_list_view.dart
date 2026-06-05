import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/graph/store/graph_data_controller.dart';
import '../../../../features/graph/presentation/viewport_state.dart';
import '../../../../src/rust/domain/templates.dart';
import '../../../../src/rust/domain/nodes.dart';
import '../../../../src/rust/domain/relations.dart';
import '../../../../src/rust/domain/base_models.dart' as ffi;
import 'delete_template_dialog.dart';

enum TemplateSortOption {
  alphabeticalAsc,
  alphabeticalDesc,
  newest,
  oldest,
}

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

  String _formatTimestamp(int timestampMs) {
    if (timestampMs <= 0) return 'Unknown';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GraphDataController>();
    final theme = Theme.of(context);

    return FutureBuilder<List<Template>>(
      future: controller.getAllTemplates(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('TEMPLATES ERROR: ${snapshot.error}');
          debugPrint('TEMPLATES STACK: ${snapshot.stackTrace}');
        }
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final allTemplates = snapshot.data ?? [];

        // Apply search query filter
        var filteredTemplates = allTemplates;
        if (_searchQuery.isNotEmpty) {
          filteredTemplates = allTemplates
              .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
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
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search templates...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // Sorting bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredTemplates.length} TEMPLATES',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  PopupMenuButton<TemplateSortOption>(
                    icon: Icon(
                      Icons.sort_rounded,
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 112),
                    tooltip: 'Sort templates',
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: theme.dividerColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    color: theme.cardColor.withValues(alpha: 0.95),
                    elevation: 6,
                    onSelected: (option) {
                      setState(() {
                        _sortOption = option;
                      });
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: TemplateSortOption.newest,
                        height: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text('Newest First', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TemplateSortOption.oldest,
                        height: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text('Oldest First', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TemplateSortOption.alphabeticalAsc,
                        height: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort_by_alpha_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text('Name A-Z', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: TemplateSortOption.alphabeticalDesc,
                        height: 30,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sort_by_alpha_rounded,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                            Text('Name Z-A', style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            if (filteredTemplates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'No templates saved' : 'No matching templates',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTemplates.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    final template = filteredTemplates[index];
                    final nodeCount = template.nodes.length;
                    final relationCount = template.relations.length;

                    final isHovered = _hoveredTemplateKey == template.key;

                    // Create the tile widget
                    final tileChild = Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: isHovered
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.04)
                            : Colors.transparent,
                        border: Border(
                          bottom: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.05),
                            width: 1,
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
                          const SizedBox(width: 10),

                          // Template metadata text details
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  template.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$nodeCount nodes · $relationCount relations',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                                  onPressed: () async {
                                    final viewportController = context.read<ViewportController>();
                                    final visibleCenter = viewportController.viewportStateNotifier.value.visibleRect.center;
                                    await controller.instantiateTemplate(template.key, visibleCenter);
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24, maxWidth: 24, maxHeight: 24),
                                  tooltip: 'Place at Center',
                                ),
                                const SizedBox(width: 4),
                                // Delete template button
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                  onPressed: () async {
                                    final confirm = await showDeleteTemplateDialog(context, template.name);
                                    if (confirm == true) {
                                      await controller.deleteTemplate(template.key);
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24, maxWidth: 24, maxHeight: 24),
                                  tooltip: 'Delete Template',
                                ),
                              ],
                            )
                          else
                            Text(
                              _formatTimestamp(template.createdAt.toInt()),
                              style: TextStyle(
                                fontSize: 8,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                            ),
                        ],
                      ),
                    );

                    // Wrap tile inside a Draggable and MouseRegion for hover detection
                    return MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _hoveredTemplateKey = template.key;
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.cardColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                width: 1.5,
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
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
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

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: CustomPaint(
          painter: TemplatePreviewPainter(
            nodes: nodes,
            relations: relations,
            isDark: isDark,
          ),
        ),
      ),
    );
  }
}

class TemplatePreviewPainter extends CustomPainter {
  final List<Nodes> nodes;
  final List<IRelation> relations;
  final bool isDark;

  TemplatePreviewPainter({
    required this.nodes,
    required this.relations,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;

    // 1. Calculate bounding box of the template nodes
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    final Map<String, Rect> nodeRects = {};
    final Map<String, Color> nodeColors = {};

    for (final node in nodes) {
      final String key = node.map(
        iNode: (n) => n.field0.id.key,
        taskNode: (n) => n.field0.id.key,
        interNode: (n) => n.field0.id.key,
        commentNode: (n) => n.field0.id.key,
        drawingNode: (n) => n.field0.id.key,
        shapeNode: (n) => n.field0.id.key,
        frameNode: (n) => n.field0.id.key,
        mediaNode: (n) => n.field0.id.key,
      );
      final ffi.Coordinates pos = node.map(
        iNode: (n) => n.field0.position,
        taskNode: (n) => n.field0.position,
        interNode: (n) => n.field0.position,
        commentNode: (n) => n.field0.position,
        drawingNode: (n) => n.field0.position,
        shapeNode: (n) => n.field0.position,
        frameNode: (n) => n.field0.position,
        mediaNode: (n) => n.field0.position,
      );
      final ffi.Size nodeSize = node.map(
        iNode: (n) => n.field0.size,
        taskNode: (n) => n.field0.size,
        interNode: (n) => const ffi.Size(width: 60, height: 36),
        commentNode: (n) => n.field0.size,
        drawingNode: (n) => const ffi.Size(width: 60, height: 36),
        shapeNode: (n) => n.field0.size,
        frameNode: (n) => n.field0.size,
        mediaNode: (n) => n.field0.size,
      );

      final double nx = pos.x.toDouble();
      final double ny = pos.y.toDouble();
      final double nw = nodeSize.width.toDouble();
      final double nh = nodeSize.height.toDouble();

      final rect = Rect.fromLTWH(nx, ny, nw, nh);
      nodeRects[key] = rect;

      final color = node.map(
        iNode: (n) => const Color(0xFF90CAF9), // light blue
        taskNode: (n) => const Color(0xFFA5D6A7), // light green
        interNode: (n) => const Color(0xFFFFF59D), // light yellow
        commentNode: (n) => const Color(0xFFB0BEC5), // grey
        drawingNode: (n) => const Color(0xFFCE93D8), // purple
        shapeNode: (n) => const Color(0xFFFFCC80), // orange
        frameNode: (n) => const Color(0xFFBCAAA4), // brown
        mediaNode: (n) => const Color(0xFF80CBC4), // teal
      );
      nodeColors[key] = color;

      if (rect.left < minX) minX = rect.left;
      if (rect.top < minY) minY = rect.top;
      if (rect.right > maxX) maxX = rect.right;
      if (rect.bottom > maxY) maxY = rect.bottom;
    }

    if (minX == double.infinity) return;

    final double groupWidth = maxX - minX;
    final double groupHeight = maxY - minY;

    // Scale to fit with padding (e.g. 6px padding on each side)
    const double padding = 6.0;
    final double targetWidth = size.width - (padding * 2);
    final double targetHeight = size.height - (padding * 2);

    double scale = 1.0;
    if (groupWidth > 0 || groupHeight > 0) {
      final double scaleX = groupWidth > 0 ? targetWidth / groupWidth : double.infinity;
      final double scaleY = groupHeight > 0 ? targetHeight / groupHeight : double.infinity;
      scale = scaleX < scaleY ? scaleX : scaleY;
      // Cap scale to prevent single nodes from looking huge
      if (scale > 0.4) scale = 0.4;
    }

    // Center the group within the size
    final double offsetX = padding + (targetWidth - (groupWidth * scale)) / 2 - minX * scale;
    final double offsetY = padding + (targetHeight - (groupHeight * scale)) / 2 - minY * scale;

    // Helper to transform coordinates
    Offset transform(Offset p) {
      return Offset(p.dx * scale + offsetX, p.dy * scale + offsetY);
    }

    // 2. Draw relations/links
    final relationPaint = Paint()
      ..color = isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (final rel in relations) {
      final startRect = nodeRects[rel.in_.key];
      final endRect = nodeRects[rel.out.key];
      if (startRect != null && endRect != null) {
        final startCenter = transform(startRect.center);
        final endCenter = transform(endRect.center);
        canvas.drawLine(startCenter, endCenter, relationPaint);
      }
    }

    // 3. Draw nodes
    for (final node in nodes) {
      final String key = node.map(
        iNode: (n) => n.field0.id.key,
        taskNode: (n) => n.field0.id.key,
        interNode: (n) => n.field0.id.key,
        commentNode: (n) => n.field0.id.key,
        drawingNode: (n) => n.field0.id.key,
        shapeNode: (n) => n.field0.id.key,
        frameNode: (n) => n.field0.id.key,
        mediaNode: (n) => n.field0.id.key,
      );
      final rect = nodeRects[key];
      final color = nodeColors[key];
      if (rect != null && color != null) {
        final scaledRect = Rect.fromPoints(
          transform(rect.topLeft),
          transform(rect.bottomRight),
        );

        final nodePaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        final borderPaint = Paint()
          ..color = isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15)
          ..strokeWidth = 0.6
          ..style = PaintingStyle.stroke;

        // Draw a tiny rounded rect
        final rrect = RRect.fromRectAndRadius(scaledRect, const Radius.circular(3.0));
        canvas.drawRRect(rrect, nodePaint);
        canvas.drawRRect(rrect, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant TemplatePreviewPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.relations != relations ||
        oldDelegate.isDark != isDark;
  }
}
