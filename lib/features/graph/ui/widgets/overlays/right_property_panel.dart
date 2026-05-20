import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/node_render_state.dart';
import 'collapsible_sidebar.dart';

class RightPropertyPanel extends StatelessWidget {
  const RightPropertyPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final renderState = context.watch<NodeRenderState>();
    final selectedEntities = renderState.selectedEntities;
    final isSelected = selectedEntities.isNotEmpty;

    return CollapsibleSidebar(
      title: 'INSPECTOR (${selectedEntities.length})',
      icon: Icons.tune_rounded,
      isRight: true,
      isVisible: isSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: textColor.withValues(alpha: 0.3),
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                'No properties available',
                style: TextStyle(
                  fontSize: 12,
                  color: textColor.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
