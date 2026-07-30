import 'package:flutter/material.dart';
import 'package:mycelium/shared/utils/name_generator.dart';
import 'package:mycelium/features/graph/ui/graph_screen.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'QUICK ACTIONS',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(
              Icons.folder_open_outlined,
              color: theme.iconTheme.color,
              size: 20,
            ),
            title: Text(
              'Open',
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () {},
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          ListTile(
            leading: Icon(
              Icons.upload_outlined,
              color: theme.iconTheme.color,
              size: 20,
            ),
            title: Text(
              'Import',
              style: theme.textTheme.bodyMedium,
            ),
            onTap: () {},
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const Expanded(
            child: Center(
              child: _NewMapButton(),
            ),
          ),
        ],
      ),
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
        icon: Icon(
          Icons.add,
          color: theme.colorScheme.primary,
        ),
        onPressed: () {
          final name = NameGenerator.generate();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GraphScreen(
                storagePath: 'maps/$name.db',
              ),
            ),
          );
        },
      ),
    );
  }
}
