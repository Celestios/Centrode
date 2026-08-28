import 'package:flutter/foundation.dart';

/// Centralized UI string constants structured for internationalization and translation readiness.
abstract final class UiStrings {
  UiStrings._();

  // --- Common Action Labels ---
  static const common = _CommonStrings();

  // --- Dialog Titles & Messages ---
  static const dialogs = _DialogStrings();

  // --- Command Palette & Action Tooltips ---
  static const commands = _CommandStrings();

  // --- Inspector & Tooling Labels ---
  static const inspector = _InspectorStrings();

  // --- Workspace Hub & Dashboard Strings ---
  static const workspace = _WorkspaceStrings();
}

class _CommonStrings {
  const _CommonStrings();

  final String cancel = 'Cancel';
  final String confirm = 'Confirm';
  final String delete = 'Delete';
  final String save = 'Save';
  final String close = 'Close';
  final String retry = 'Retry';
  final String apply = 'Apply';
  final String open = 'Open';
  final String help = 'Help';
  final String share = 'Share';
  final String search = 'Search';
  final String loading = 'Loading...';
  final String showDetails = 'Show Details';
  final String viewMetadata = 'View metadata';
  final String done = 'Done';
  final String none = 'None';
}

class _DialogStrings {
  const _DialogStrings();

  // Tag Deletion
  final String deleteTagTitle = 'DELETE TAG?';
  String deleteTagMessage(String tagName) =>
      'Are you sure you want to delete the tag "$tagName" globally? This will remove it from all nodes and cannot be undone.';

  // Template Deletion
  final String deleteTemplateTitle = 'DELETE TEMPLATE?';
  String deleteTemplateMessage(String templateName) =>
      'Are you sure you want to delete the template "$templateName"? This action cannot be undone.';

  // Template Saving
  final String saveTemplateTitle = 'SAVE AS TEMPLATE';
  final String saveTemplateMessage =
      'Enter a name for this template to save the selected subgraph as a reusable template.';
  final String templateNameHint = 'Template name...';

  // Map Deletion
  String deleteMapTitle({required bool isPlural}) =>
      isPlural ? 'Delete maps' : 'Delete map';
  String deleteMapMessage({required bool isPlural, String? mapName, int count = 1}) =>
      isPlural ? 'Delete $count selected maps?' : 'Delete "$mapName"?';

  // Hyperlink Prompt
  final String insertHyperlinkTitle = 'Insert Hyperlink';
  final String hyperlinkHint = 'https://example.com';
  final String hyperlinkAction = 'Insert';
}

class _CommandStrings {
  const _CommandStrings();

  final String forceSyncSave = 'Force Sync Save';
  final String toggleTheme = 'Toggle Theme';
  final String keyboardShortcuts = 'Keyboard Shortcuts & Guide';
  final String insertHyperlink = 'Insert Hyperlink';
  final String returnToMap = 'Return to Map';
  final String actions = 'Actions';
}

class _InspectorStrings {
  const _InspectorStrings();

  final String appearance = 'Appearance';
  final String data = 'Data';
  final String nodes = 'Nodes';
  final String relations = 'Relations';
  final String style = 'Style';
  final String formatting = 'Formatting';
  final String fontFamily = 'Font Family';
  final String fontSize = 'Font Size';
  final String strokeWidth = 'Stroke Width';
  final String strokePattern = 'Stroke Pattern';
  final String cornerRadius = 'Corner Radius';
  final String tags = 'Tags';
  final String comments = 'Comments';
  final String addTag = 'Add Tag';
  final String addComment = 'Add Comment';
  final String searchTags = 'Search tags...';
  final String searchTemplates = 'Search templates...';
}

class _WorkspaceStrings {
  const _WorkspaceStrings();

  final String appTitle = 'CENTRODE';
  final String recentMaps = 'Recent Maps';
  final String allMaps = 'All Maps';
  final String templates = 'Templates';
  final String quickActions = 'Quick Actions';
  final String newMap = 'New Map';
  final String openMap = 'Open Map';
  final String noMapsFound = 'No maps found';
  final String emptySectionSubtitle = 'Create a new map or open an existing project';
}
