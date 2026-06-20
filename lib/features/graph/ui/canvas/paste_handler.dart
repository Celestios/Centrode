import 'dart:ui';
import 'package:logging/logging.dart';
import '../../models/content_builder.dart';
import '../../models/graph_node.dart';
import '../../store/graph_data_controller.dart';

final Logger _log = Logger('PasteHandler');

enum _BlockType { heading, paragraph, bulletItem, orderedItem, checkItem, codeBlock }

class _Block {
  final _BlockType type;
  final String text;
  final int level;
  final bool checked;

  const _Block(this.type, this.text, {this.level = 0, this.checked = false});
}

class _TreeNode {
  final String? title;
  final String body;
  final int level;
  final List<_TreeNode> children = [];

  _TreeNode({this.title, this.body = '', required this.level});
}

List<_Block> _parseBlocks(String text) {
  final lines = text.split('\n');
  final blocks = <_Block>[];
  bool inCodeBlock = false;
  final codeBuffer = StringBuffer();

  for (final rawLine in lines) {
    final line = rawLine.replaceAll('\r', '');
    final trimmed = line.trimRight();

    if (inCodeBlock) {
      if (trimmed == '```') {
        inCodeBlock = false;
        blocks.add(_Block(_BlockType.codeBlock, codeBuffer.toString().trimRight()));
        codeBuffer.clear();
      } else {
        codeBuffer.writeln(trimmed);
      }
      continue;
    }

    if (trimmed.startsWith('```')) {
      inCodeBlock = true;
      continue;
    }

    final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(trimmed);
    if (headingMatch != null) {
      blocks.add(_Block(_BlockType.heading, headingMatch.group(2)!, level: headingMatch.group(1)!.length));
      continue;
    }

    final checkMatch = RegExp(r'^[-*+]\s+\[([ xX])\]\s+(.*)$').firstMatch(trimmed);
    if (checkMatch != null) {
      blocks.add(_Block(_BlockType.checkItem, checkMatch.group(2)!, checked: checkMatch.group(1) != ' '));
      continue;
    }

    final bulletMatch = RegExp(r'^[-*+]\s+(.*)$').firstMatch(trimmed);
    if (bulletMatch != null) {
      blocks.add(_Block(_BlockType.bulletItem, bulletMatch.group(1)!));
      continue;
    }

    final orderedMatch = RegExp(r'^\d+\.\s+(.*)$').firstMatch(trimmed);
    if (orderedMatch != null) {
      blocks.add(_Block(_BlockType.orderedItem, orderedMatch.group(1)!));
      continue;
    }

    if (trimmed.isEmpty) {
      if (blocks.isNotEmpty && blocks.last.type == _BlockType.paragraph) {
        continue;
      }
      continue;
    }

    if (blocks.isNotEmpty && blocks.last.type == _BlockType.paragraph) {
      blocks[blocks.length - 1] = _Block(_BlockType.paragraph, '${blocks.last.text}\n$trimmed');
    } else {
      blocks.add(_Block(_BlockType.paragraph, trimmed));
    }
  }

  if (inCodeBlock && codeBuffer.isNotEmpty) {
    blocks.add(_Block(_BlockType.codeBlock, codeBuffer.toString().trimRight()));
  }

  return blocks;
}

List<_TreeNode> _buildTree(String text) {
  final blocks = _parseBlocks(text);
  final root = _TreeNode(body: '', level: 0);
  final stack = <_TreeNode>[root];

  _TreeNode currentSection = root;

  for (final block in blocks) {
    if (block.type == _BlockType.heading) {
      final node = _TreeNode(title: block.text, level: block.level);
      while (stack.length > 1 && stack.last.level >= node.level) {
        stack.removeLast();
      }
      stack.last.children.add(node);
      stack.add(node);
      currentSection = node;
    } else {
      String content;
      switch (block.type) {
        case _BlockType.bulletItem:
          content = '- ${block.text}';
          break;
        case _BlockType.orderedItem:
          content = '1. ${block.text}';
          break;
        case _BlockType.checkItem:
          content = block.checked ? '- [x] ${block.text}' : '- [ ] ${block.text}';
          break;
        case _BlockType.codeBlock:
          content = '```\n${block.text}\n```';
          break;
        case _BlockType.paragraph:
        case _BlockType.heading:
          content = block.text;
          break;
      }
      final child = _TreeNode(body: content, level: 0);
      currentSection.children.add(child);
    }
  }

  return root.children;
}

String _nodeContent(_TreeNode node) {
  if (node.title != null) {
    final prefix = '#' * node.level;
    if (node.body.isNotEmpty) {
      return '$prefix ${node.title}\n${node.body}';
    }
    return '$prefix ${node.title}';
  }
  return node.body;
}

void pasteTextToCanvas({
  required GraphDataController dataController,
  required String text,
  required Offset canvasPosition,
}) {
  if (text.trim().isEmpty) return;

  final trees = _buildTree(text);

  if (trees.isEmpty) {
    _createSingleNode(dataController, text, canvasPosition);
    return;
  }

  if (trees.length == 1 && trees.first.title == null && trees.first.children.isEmpty) {
    _createSingleNode(dataController, text, canvasPosition);
    return;
  }

  _createTreeNodes(dataController, trees, canvasPosition);
}

void _createSingleNode(
  GraphDataController dataController,
  String text,
  Offset position,
) {
  final id = dataController.createNode(UiNodes.info, position);
  dataController.commitEntityText(id, ContentFactory.fromText(text));
  dataController.flushSync();
  _log.info('Pasted plain text as single node: $id');
}

void _createTreeNodes(
  GraphDataController dataController,
  List<_TreeNode> roots,
  Offset position,
) {
  const double hGap = 280.0;
  const double vGap = 140.0;

  final createdIds = <String>{};

  String createNode(_TreeNode tree, Offset pos, String? parentId) {
    final content = _nodeContent(tree);
    final id = dataController.createNode(UiNodes.info, pos);
    if (content.isNotEmpty) {
      dataController.commitEntityText(id, ContentFactory.fromText(content));
    }
    createdIds.add(id);

    if (parentId != null) {
      dataController.createRelation(parentId, id);
    }

    final childCount = tree.children.length;
    if (childCount > 0) {
      final startX = pos.dx - ((childCount - 1) * hGap) / 2;
      for (int i = 0; i < childCount; i++) {
        final childPos = Offset(startX + i * hGap, pos.dy + vGap);
        createNode(tree.children[i], childPos, id);
      }
    }

    return id;
  }

  final rootCount = roots.length;
  final startX = position.dx - ((rootCount - 1) * hGap) / 2;

  for (int i = 0; i < rootCount; i++) {
    createNode(roots[i], Offset(startX + i * hGap, position.dy), null);
  }

  dataController.flushSync();
  _log.info('Pasted markdown as ${createdIds.length} connected nodes');
}
