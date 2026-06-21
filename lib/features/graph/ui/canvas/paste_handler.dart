import 'dart:ui';
import 'package:mycelium/infrastructure/telemetry/logging.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import '../../models/content_builder.dart';
import '../../models/graph_node.dart';
import '../../models/graph_relation.dart';
import '../../store/graph_data_controller.dart';
import 'package:mycelium/src/rust/domain/contents.dart';
import 'package:mycelium/features/graph/presentation/strategies/relation_layout_strategy.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

final Logger _log = Logger('PasteHandler');

class _TreeNode {
  final Content content;
  final List<_TreeNode> children = [];

  _TreeNode({required this.content});
}

List<_TreeNode> _buildTree(Content content) {
  final blocks = _mergeBlocks(content.blocks);
  final roots = <_TreeNode>[];
  final headingStack = <_TreeNode>[];

  for (final block in blocks) {
    if (block.blockType == BlockType.heading) {
      final level = block.attrs?.level ?? 1;
      final node = _TreeNode(
        content: Content(text: _blockText(block), blocks: [block]),
      );
      while (headingStack.isNotEmpty &&
          _headingLevel(headingStack.last) >= level) {
        headingStack.removeLast();
      }
      if (headingStack.isEmpty) {
        roots.add(node);
      } else {
        headingStack.last.children.add(node);
      }
      headingStack.add(node);
    } else {
      final node = _TreeNode(
        content: Content(text: _blockText(block), blocks: [block]),
      );
      if (headingStack.isNotEmpty) {
        headingStack.last.children.add(node);
      } else {
        roots.add(node);
      }
    }
  }

  return roots;
}

List<ContentBlock> _mergeBlocks(List<ContentBlock> blocks) {
  final result = <ContentBlock>[];
  for (final block in blocks) {
    final text = _blockText(block);
    if (text.trim().isEmpty && block.blockType == BlockType.paragraph) continue;
    if (block.blockType == BlockType.paragraph &&
        result.isNotEmpty &&
        result.last.blockType == BlockType.paragraph) {
      final merged = ContentBlock(
        blockType: BlockType.paragraph,
        content: [
          ...result.last.content,
          const InlineElement(inlineType: InlineType.hardBreak, text: ''),
          ...block.content,
        ],
      );
      result[result.length - 1] = merged;
    } else {
      result.add(block);
    }
  }
  return result;
}

int _headingLevel(_TreeNode node) {
  if (node.content.blocks.isEmpty) return 0;
  return node.content.blocks.first.attrs?.level ?? 1;
}

String _blockText(ContentBlock block) {
  final buffer = StringBuffer();
  for (final inline in block.content) {
    buffer.write(inline.text);
  }
  return buffer.toString();
}

Future<void> pasteTextToCanvas({
  required GraphDataController dataController,
  required String text,
  required Offset canvasPosition,
}) async {
  if (text.trim().isEmpty) return;

  final content = ContentFactory.fromText(text);
  final trees = _buildTree(content);

  if (trees.isEmpty) {
    _createSingleNode(dataController, content, canvasPosition);
    await dataController.flush();
    return;
  }

  if (trees.length == 1 &&
      trees.first.children.isEmpty &&
      trees.first.content.blocks.length == 1) {
    _createSingleNode(dataController, trees.first.content, canvasPosition);
    await dataController.flush();
    return;
  }

  await _createTreeNodes(dataController, trees, canvasPosition);
}

void _createSingleNode(
  GraphDataController dataController,
  Content content,
  Offset position,
) {
  final id = dataController.createNode(UiNodes.info, position, content: content);
  _log.info('Pasted plain text as single node: $id');
}

Future<void> _createTreeNodes(
  GraphDataController dataController,
  List<_TreeNode> roots,
  Offset position,
) async {
  const double hGap = 280.0;
  const double vGap = 140.0;

  final createdIds = <String>{};
  final relations = <(String parentId, String childId, String verb)>[];

  String addNode(
    _TreeNode tree,
    Offset pos,
    String? parentId, {
    String? parentVerb,
  }) {
    final id = dataController.createNode(
      UiNodes.info,
      pos,
      content: tree.content,
    );
    createdIds.add(id);

    if (parentId != null) {
      final isParentHeading = parentVerb != null;
      final isChildBody = tree.content.blocks.first.blockType != BlockType.heading;
      final verb = isParentHeading && isChildBody ? 'description' : 'contains';
      relations.add((parentId, id, verb));
    }

    final childCount = tree.children.length;
    if (childCount > 0) {
      final startX = pos.dx - ((childCount - 1) * hGap) / 2;
      for (int i = 0; i < childCount; i++) {
        final childPos = Offset(startX + i * hGap, pos.dy + vGap);
        final isHeading = tree.content.blocks.first.blockType == BlockType.heading;
        addNode(
          tree.children[i],
          childPos,
          id,
          parentVerb: isHeading ? _blockText(tree.content.blocks.first) : parentVerb,
        );
      }
    }

    return id;
  }

  final rootCount = roots.length;
  final startX = position.dx - ((rootCount - 1) * hGap) / 2;

  for (int i = 0; i < rootCount; i++) {
    addNode(roots[i], Offset(startX + i * hGap, position.dy), null);
  }

  await dataController.flush();

  for (final (parentId, childId, verb) in relations) {
    final fromNode = dataController.store.nodeLookup[parentId];
    final toNode = dataController.store.nodeLookup[childId];
    if (fromNode == null || toNode == null) continue;

    final fromVs = NodeViewState(fromNode);
    final toVs = NodeViewState(toNode);

    final closest = RelationLayoutStrategy.getClosestMiddlePorts(fromVs, toVs);
    final fromSide = closest.startPort.side.name;
    final toSide = closest.endPort.side.name;

    final relation = InfoUiRelation(
      fromNodeId: parentId,
      fromNodeTable: fromNode.tableName,
      toNodeId: childId,
      toNodeTable: toNode.tableName,
      verb: verb,
      layout: RelationLayout(
        fromSide: fromSide,
        toSide: toSide,
        strategyType: 'bezier',
      ),
    );

    dataController.store.relationLookup[relation.id] = relation;
    dataController.styleUpdater?.updateStyleForRelation(relation.id);

    try {
      await dataController.syncEngine.api.createRelation(input: relation.toRust());
    } catch (e) {
      _log.warning('Failed to persist relation to Rust: $e');
    }
  }

  dataController.triggerUpdate();
  _log.info('Pasted markdown as ${createdIds.length} connected nodes');
}
