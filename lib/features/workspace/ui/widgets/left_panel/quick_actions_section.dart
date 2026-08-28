import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:centrode/features/graph/ui/graph_screen.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/features/workspace/presentation/workspace_hub_controller.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

class QuickActionsSection extends StatelessWidget {
  final WorkspaceHubController? controller;

  const QuickActionsSection({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hubController = controller ?? WorkspaceHubController();

    return Padding(
      padding: UiInsets.container,
      child: Column(
        children: [
          _ReturnToMapButton(controller: hubController),
          const SizedBox(height: UiSpacing.gutter),
          ListTile(
            leading: Icon(
              Icons.folder_open_outlined,
              color: theme.iconTheme.color,
              size: UiIconSize.standard,
            ),
            title: Text(UiStrings.common.open, style: theme.textTheme.bodyMedium),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['cent'],
              );
              if (result != null && result.files.single.path != null) {
                final filePath = result.files.single.path!;
                final name = p.basenameWithoutExtension(filePath);
                await hubController.openCentFile(filePath, name);
                if (context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GraphScreen()),
                  );
                }
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          ListTile(
            leading: Icon(
              Icons.upload_outlined,
              color: theme.iconTheme.color,
              size: UiIconSize.standard,
            ),
            title: Text('Import', style: theme.textTheme.bodyMedium),
            onTap: () {},
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          Expanded(child: Center(child: _NewMapButton(controller: hubController))),
        ],
      ),
    );
  }
}

class _ReturnToMapButton extends StatelessWidget {
  final WorkspaceHubController controller;

  const _ReturnToMapButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: MapManager.instance,
      builder: (context, _) {
        final hasOpenMaps = controller.hasOpenMaps;
        final primaryColor = theme.colorScheme.primary;
        final disabledColor = theme.disabledColor;

        final buttonColor = hasOpenMaps ? primaryColor : disabledColor;

        return HoverScaleButton(
          isEnabled: hasOpenMaps,
          onTap: hasOpenMaps
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GraphScreen()),
                  );
                }
              : null,
          hoverScale: hasOpenMaps ? 1.02 : 1.0,
          pressScale: hasOpenMaps ? 0.98 : 1.0,
          borderRadius: BorderRadius.circular(UiRadius.card),
          builder: (context, isHovered, isPressed) {
            return GlassPanel(
              borderRadius: 10,
              color: hasOpenMaps
                  ? (isHovered
                        ? primaryColor.withValues(alpha: 0.18)
                        : primaryColor.withValues(alpha: 0.1))
                  : theme.cardColor.withValues(alpha: 0.3),
              shadow: hasOpenMaps && isHovered
                  ? BoxShadow(
                      color: primaryColor.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: buttonColor.withValues(
                        alpha: hasOpenMaps ? 1.0 : 0.4,
                      ),
                      size: UiIconSize.standard,
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Text(
                      UiStrings.commands.returnToMap,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: buttonColor.withValues(
                          alpha: hasOpenMaps ? 1.0 : 0.4,
                        ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _NewMapButton extends StatelessWidget {
  final WorkspaceHubController controller;

  const _NewMapButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(UiRadius.card),
      ),
      child: IconButton(
        icon: Icon(Icons.add, color: theme.colorScheme.primary),
        onPressed: () async {
          await controller.createNewMap();
          if (context.mounted) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const GraphScreen()));
          }
        },
      ),
    );
  }
}
