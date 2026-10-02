import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:centrode/features/graph/ui/graph_screen.dart';
import 'package:centrode/features/workspace/presentation/workspace_hub_controller.dart';

class QuickActionsSection extends StatelessWidget {
  final WorkspaceHubController controller;

  const QuickActionsSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = CentrodeDerivedPalette.of(context);
    final iconColor = palette.textOn(palette.surface.panelBackground).withValues(alpha: 0.75);
    final textColor = palette.textOn(palette.surface.panelBackground);

    return Padding(
      padding: UiInsets.container,
      child: Column(
        children: [
          _ReturnToMapButton(controller: controller),
          const SizedBox(height: UiSpacing.gutter),
          ListTile(
            leading: Icon(
              Icons.folder_open_outlined,
              color: iconColor,
              size: UiIconSize.standard,
            ),
            title: Text(UiStrings.common.open, style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['cent'],
              );
              if (result != null && result.files.single.path != null) {
                final filePath = result.files.single.path!;
                final name = p.basenameWithoutExtension(filePath);
                await controller.openCentFile(filePath, name);
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
              color: iconColor,
              size: UiIconSize.standard,
            ),
            title: Text('Import', style: theme.textTheme.bodyMedium?.copyWith(color: textColor)),
            onTap: () {},
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          Expanded(child: Center(child: _NewMapButton(controller: controller))),
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
    final palette = CentrodeDerivedPalette.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final hasOpenMaps = controller.hasOpenMaps;
        final primaryColor = theme.colorScheme.primary;
        final disabledColor = primaryColor.withValues(alpha: 0.45);

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
              borderRadius: UiRadius.card,
              color: hasOpenMaps
                  ? (isHovered
                        ? Color.alphaBlend(primaryColor.withValues(alpha: 0.28), palette.surface.controlBackground)
                        : Color.alphaBlend(primaryColor.withValues(alpha: 0.18), palette.surface.controlBackground))
                  : Color.alphaBlend(primaryColor.withValues(alpha: 0.08), palette.surface.controlBackground),
              border: Border.all(
                color: hasOpenMaps
                    ? primaryColor.withValues(alpha: isHovered ? 0.75 : 0.5)
                    : primaryColor.withValues(alpha: 0.22),
                width: UiStrokeWidth.subtle,
              ),
              shadow: hasOpenMaps && isHovered
                  ? BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  : (hasOpenMaps
                      ? BoxShadow(
                          color: primaryColor.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      : null),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: UiSpacing.standard,
                  horizontal: UiSpacing.container,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      color: buttonColor,
                      size: UiIconSize.standard,
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Flexible(
                      child: Text(
                        UiStrings.commands.returnToMap,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: buttonColor,
                          fontWeight: FontWeight.w600,
                        ),
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
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: WorkspaceTokens.newMapButtonSize,
      height: WorkspaceTokens.newMapButtonSize,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(UiRadius.card),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.add, color: Colors.white),
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
