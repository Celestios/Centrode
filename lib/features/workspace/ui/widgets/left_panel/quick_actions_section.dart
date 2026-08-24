import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:centrode/shared/utils/name_generator.dart';
import 'package:centrode/features/graph/ui/graph_screen.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/infrastructure/lifecycle/daemon_gateway.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _ReturnToMapButton(),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              Icons.folder_open_outlined,
              color: theme.iconTheme.color,
              size: 20,
            ),
            title: Text('Open', style: theme.textTheme.bodyMedium),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['cent'],
              );
              if (result != null && result.files.single.path != null) {
                final filePath = result.files.single.path!;
                final name = p.basenameWithoutExtension(filePath);
                MapManager.instance.openCentFile(filePath, name);
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
              size: 20,
            ),
            title: Text('Import', style: theme.textTheme.bodyMedium),
            onTap: () {},
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const Expanded(child: Center(child: _NewMapButton())),
        ],
      ),
    );
  }
}

class _ReturnToMapButton extends StatelessWidget {
  const _ReturnToMapButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: MapManager.instance,
      builder: (context, _) {
        final hasOpenMaps = MapManager.instance.hasOpenMaps;
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
          borderRadius: BorderRadius.circular(10),
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
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Return to Map',
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
  const _NewMapButton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(Icons.add, color: theme.colorScheme.primary),
        onPressed: () async {
          final name = NameGenerator.generate();
          final descriptor = await DaemonGateway.instance.createMap(name);
          MapManager.instance.openMap(
            descriptor.storagePath,
            descriptor.name,
            mapId: descriptor.id,
          );
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
