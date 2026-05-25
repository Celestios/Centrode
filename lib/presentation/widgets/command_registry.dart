import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/graph/presentation/workspace_tabs_controller.dart';

class Command {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context) onSelected;
  final bool Function(BuildContext context)? isEnabled;

  const Command({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
    this.isEnabled,
  });
}

class CommandRegistry {
  CommandRegistry._();
  static final CommandRegistry instance = CommandRegistry._();

  final List<Command> _commands = [
    Command(
      id: 'toggle_left_panel',
      title: 'Toggle Left Panel',
      subtitle: 'Command',
      icon: Icons.menu_open_rounded,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.showLeftPanel.value = !session.showLeftPanel.value;
      },
    ),
    Command(
      id: 'toggle_right_panel',
      title: 'Toggle Right Panel',
      subtitle: 'Command',
      icon: Icons.chrome_reader_mode_outlined,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.showRightPanel.value = !session.showRightPanel.value;
      },
    ),
    Command(
      id: 'toggle_bottom_panel',
      title: 'Toggle Bottom Panel',
      subtitle: 'Command',
      icon: Icons.call_to_action_outlined,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.showBottomPanel.value = !session.showBottomPanel.value;
      },
    ),
    Command(
      id: 'undo',
      title: 'Undo last action',
      subtitle: 'Command',
      icon: Icons.undo_rounded,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.dataController?.undo();
      },
      isEnabled: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        return session.dataController != null;
      },
    ),
    Command(
      id: 'redo',
      title: 'Redo action',
      subtitle: 'Command',
      icon: Icons.redo_rounded,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.dataController?.redo();
      },
      isEnabled: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        return session.dataController != null;
      },
    ),
    Command(
      id: 'zoom_to_fit',
      title: 'Zoom to Fit Map Boundaries',
      subtitle: 'Command',
      icon: Icons.zoom_out_map_rounded,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        final dataController = session.dataController;
        final viewportController = session.viewportController;
        if (viewportController != null && dataController != null) {
          viewportController.focusOnBounds(dataController.canvasBounds.value);
        }
      },
      isEnabled: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        return session.viewportController != null && session.dataController != null;
      },
    ),
  ];

  List<Command> getCommands(BuildContext context) {
    return _commands.where((cmd) => cmd.isEnabled == null || cmd.isEnabled!(context)).toList();
  }

  void registerCommand(Command command) {
    if (!_commands.any((cmd) => cmd.id == command.id)) {
      _commands.add(command);
    }
  }

  void unregisterCommand(String id) {
    _commands.removeWhere((cmd) => cmd.id == id);
  }
}
