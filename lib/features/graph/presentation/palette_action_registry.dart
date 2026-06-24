import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'workspace_tabs_controller.dart';

class PaletteAction {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final void Function(BuildContext context) onSelected;
  final bool Function(BuildContext context)? isEnabled;

  const PaletteAction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
    this.isEnabled,
  });
}

class PaletteActionRegistry {
  PaletteActionRegistry._();
  static final PaletteActionRegistry instance = PaletteActionRegistry._();

  final List<PaletteAction> _actions = [
    PaletteAction(
      id: 'toggle_left_panel',
      title: 'Toggle Left Panel',
      subtitle: 'Command',
      icon: Icons.menu_open_rounded,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.showLeftPanel.value = !session.showLeftPanel.value;
      },
    ),
    PaletteAction(
      id: 'toggle_right_panel',
      title: 'Toggle Right Panel',
      subtitle: 'Command',
      icon: Icons.chrome_reader_mode_outlined,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.showRightPanel.value = !session.showRightPanel.value;
      },
    ),
    PaletteAction(
      id: 'toggle_bottom_panel',
      title: 'Toggle Bottom Panel',
      subtitle: 'Command',
      icon: Icons.call_to_action_outlined,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        session.showBottomPanel.value = !session.showBottomPanel.value;
      },
    ),
    PaletteAction(
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
        return session.dataController?.canUndo == true;
      },
    ),
    PaletteAction(
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
        return session.dataController?.canRedo == true;
      },
    ),
    PaletteAction(
      id: 'zoom_to_fit',
      title: 'Zoom to Fit Map Boundaries',
      subtitle: 'Command',
      icon: Icons.zoom_out_map_rounded,
      onSelected: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        final dataController = session.dataController;
        final viewportController = session.viewportController;
        if (viewportController != null && dataController != null) {
          viewportController.focusOnBounds(dataController.canvasBounds);
        }
      },
      isEnabled: (context) {
        final session = context.read<WorkspaceTabsController>().activeSession;
        return session.viewportController != null &&
            session.dataController != null;
      },
    ),
  ];

  List<PaletteAction> getActions(BuildContext context) {
    return _actions
        .where(
          (action) => action.isEnabled == null || action.isEnabled!(context),
        )
        .toList();
  }

  void registerAction(PaletteAction action) {
    if (!_actions.any((act) => act.id == action.id)) {
      _actions.add(action);
    }
  }

  void unregisterAction(String id) {
    _actions.removeWhere((act) => act.id == id);
  }
}
