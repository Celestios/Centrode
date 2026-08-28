import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

class PanelFooterSection extends StatelessWidget {
  const PanelFooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.person_outline,
              size: UiIconSize.standard,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Account',
              style: theme.textTheme.bodyMedium,
            ),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            leading: Icon(
              Icons.settings_outlined,
              size: UiIconSize.standard,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Settings',
              style: theme.textTheme.bodyMedium,
            ),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            leading: Icon(
              Icons.help_outline,
              size: UiIconSize.standard,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'Help',
              style: theme.textTheme.bodyMedium,
            ),
            dense: true,
            onTap: () {},
          ),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              size: UiIconSize.standard,
              color: theme.iconTheme.color,
            ),
            title: Text(
              'About',
              style: theme.textTheme.bodyMedium,
            ),
            dense: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
